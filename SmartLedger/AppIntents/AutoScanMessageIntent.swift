import Foundation
import AppIntents

#if canImport(AppIntents)
public struct AutoScanMessageIntent: AppIntent {
    public static var title: LocalizedStringResource = "Auto-Scan Bank SMS or Alert"
    public static var description = IntentDescription("Automatically parses a bank SMS, notification, or forwarded email into a prepared transaction.")
    
    @Parameter(title: "Message Text")
    public var messageText: String
    
    public init() {}
    
    public init(messageText: String) {
        self.messageText = messageText
    }
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        // 1. Process via Gemini
        let parsed = try await GeminiAPIService.shared.parseTransactionText(rawText: messageText)
        
        let amount = parsed.totalAmount ?? 0.0
        let merchant = parsed.merchantName ?? "Bank Alert"
        
        // 2. Prepare transaction on backend or local DataStore
        let prepared = PreparedTransaction(
            title: "Auto-Scanned: \(merchant)",
            amount: amount,
            merchant: merchant,
            category: .shopping,
            source: "sms_auto_scan",
            status: .pendingReview,
            confidenceScore: parsed.confidenceScore,
            currency: parsed.currencyDetected ?? "USD",
            suggestedCardLast4: parsed.paymentMethodLast4,
            rawText: messageText,
            lineItems: parsed.items
        )
        
        await MainActor.run {
            DataStore.shared.preparedTransactions.insert(prepared, at: 0)
        }
        
        return .result(dialog: "SmartLedger prepared \(merchant) for $\(String(format: "%.2f", amount)). Ready for 1-tap review.")
    }
}

public struct SmartLedgerShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AutoScanMessageIntent(),
            phrases: [
                "Auto-scan bank alert in \(.applicationName)",
                "Prepare transaction with \(.applicationName)",
                "Scan receipt with \(.applicationName)"
            ],
            shortTitle: "Auto-Scan Transaction",
            systemImageName: "camera.viewfinder"
        )
    }
}
#endif
