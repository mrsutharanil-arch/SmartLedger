import Foundation
import BackgroundTasks
import UserNotifications
import Photos

@MainActor
public class BackgroundScanManager: NSObject, ObservableObject {
    public static let shared = BackgroundScanManager()
    
    public static let backgroundTaskId = "com.smartledger.app.refresh"
    @Published public var isMonitoringPhotos: Bool = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Register iOS Background Tasks
    public func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundScanManager.backgroundTaskId,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self.handleAppRefresh(task: refreshTask)
        }
    }
    
    // MARK: - Schedule Next Background Refresh
    public func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundScanManager.backgroundTaskId)
        // Request execution within next 15-30 minutes
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Successfully scheduled SmartLedger background auto-scan refresh.")
        } catch {
            print("Could not schedule BGAppRefreshTask: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Execute App Refresh
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()
        
        task.expirationHandler = {
            print("Background auto-scan task timed out.")
        }
        
        Task {
            do {
                let prepared = try await BackendSyncService.shared.fetchPreparedTransactions()
                let pendingCount = prepared.filter { $0.status == .pendingReview }.count
                
                if pendingCount > 0 {
                    await self.postLocalNotification(
                        title: "Auto-Scanned Transactions Ready",
                        body: "\(pendingCount) new transactions prepared from bank alerts and emails. Tap to review."
                    )
                }
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    // MARK: - Request Notification Permissions & Post Notification
    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Notifications granted: \(granted)")
        }
    }
    
    public func postLocalNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Photo Library Auto-Scan Watcher (For Receipt Screenshots)
    public func startPhotoMonitoring() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized || status == .limited {
                DispatchQueue.main.async {
                    self.isMonitoringPhotos = true
                    PHPhotoLibrary.shared().register(self)
                }
            }
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension BackgroundScanManager: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Triggered when a new screenshot or camera picture is saved
        Task {
            print("New photo added. Auto-scanning for receipt contents...")
        }
    }
}
