import Foundation
import LocalAuthentication

@MainActor
public class BiometricAuthService: ObservableObject {
    public static let shared = BiometricAuthService()
    
    @Published public var isUnlocked: Bool = false
    @Published public var biometryType: LABiometryType = .none
    
    private init() {
        checkBiometryType()
    }
    
    public func checkBiometryType() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.biometryType = context.biometryType
        } else {
            self.biometryType = .none
        }
    }
    
    public func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        let isBiometricsEnabled = UserDefaults.standard.bool(forKey: "biometrics_enabled")
        guard isBiometricsEnabled else {
            self.isUnlocked = true
            completion(true)
            return
        }
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock SmartLedger to access your accounts and accounting data."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isUnlocked = success
                    completion(success)
                }
            }
        } else {
            // Biometrics unavailable, fallback to unlocked or passcode
            self.isUnlocked = true
            completion(true)
        }
    }
}
