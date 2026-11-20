import SwiftUI

@main
struct SmartLedgerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var authService = BiometricAuthService.shared
    
    init() {
        // Register iOS BackgroundTasks & Notification Permissions
        BackgroundScanManager.shared.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authService.isUnlocked || !UserDefaults.standard.bool(forKey: "biometrics_enabled") {
                    MainTabView()
                        .environmentObject(dataStore)
                } else {
                    // Biometric Lock Screen
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text("SmartLedger Locked")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please authenticate to view your personal accounts, credit cards, and investments.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button(action: {
                            authService.authenticateUser { _ in }
                        }) {
                            HStack {
                                Image(systemName: "faceid")
                                Text("Unlock with Face ID")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(16)
                        }
                        .padding(.top, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground).ignoresSafeArea())
                }
            }
            .onAppear {
                authService.authenticateUser { _ in }
                BackgroundScanManager.shared.requestNotificationPermission()
                dataStore.syncPreparedFromBackend()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background {
                    BackgroundScanManager.shared.scheduleBackgroundRefresh()
                } else if newPhase == .active {
                    dataStore.syncPreparedFromBackend()
                }
            }
        }
    }
}
