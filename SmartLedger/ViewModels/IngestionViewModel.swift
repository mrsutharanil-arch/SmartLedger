import Foundation
import SwiftUI
import Combine

@MainActor
public class IngestionViewModel: ObservableObject {
    @Published public var isAnalyzing: Bool = false
    @Published public var parsedReceipt: ParsedReceipt? = nil
    @Published public var currentScanImage: UIImage? = nil
    @Published public var rawPastedText: String = ""
    @Published public var activeSource: TransactionSource = .receiptScan
    @Published public var errorMessage: String? = nil
    @Published public var showReviewSheet: Bool = false
    
    // Target linking
    @Published public var selectedAccountId: UUID? = nil
    @Published public var selectedCreditCardId: UUID? = nil
    
    public init() {}
    
    // MARK: - Process Scanned Image with Gemini Multimodal Vision
    public func processScannedImage(_ image: UIImage) {
        self.currentScanImage = image
        self.activeSource = .receiptScan
        self.isAnalyzing = true
        self.errorMessage = nil
        
        guard let jpegData = image.jpegData(compressionQuality: 0.75) else {
            self.errorMessage = "Failed to encode captured image."
            self.isAnalyzing = false
            return
        }
        
        Task {
            do {
                let receipt = try await GeminiAPIService.shared.analyzeReceipt(imageData: jpegData)
                await MainActor.run {
                    self.parsedReceipt = receipt
                    self.isAnalyzing = false
                    self.showReviewSheet = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Gemini scan error: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    // MARK: - Process SMS or Email Text with Gemini Text Intelligence
    public func processTextContent(_ text: String, source: TransactionSource) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        self.rawPastedText = text
        self.activeSource = source
        self.isAnalyzing = true
        self.errorMessage = nil
        
        Task {
            do {
                let receipt = try await GeminiAPIService.shared.parseTransactionText(rawText: text)
                await MainActor.run {
                    self.parsedReceipt = receipt
                    self.isAnalyzing = false
                    self.showReviewSheet = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Gemini parser error: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    // MARK: - Check Clipboard for Bank Alert / Transaction
    public func checkClipboardForAlert() -> String? {
        if UIPasteboard.general.hasStrings, let text = UIPasteboard.general.string {
            let lower = text.lowercased()
            if lower.contains("spent") || lower.contains("debited") || lower.contains("charged") ||
               lower.contains("paid") || lower.contains("bank") || lower.contains("card ending") ||
               lower.contains("usd") || lower.contains("inr") || lower.contains("invoice") {
                return text
            }
        }
        return nil
    }
    
    // MARK: - Commit Final Verified Transaction to DataStore
    public func commitParsedTransaction(
        store: DataStore,
        title: String,
        amount: Double,
        category: TransactionCategory,
        date: Date,
        notes: String?,
        accountId: UUID?,
        creditCardId: UUID?
    ) {
        let txn = Transaction(
            title: title,
            amount: amount,
            type: .expense,
            category: category,
            date: date,
            notes: notes,
            accountId: accountId,
            creditCardId: creditCardId,
            source: activeSource,
            rawTextSource: rawPastedText.isEmpty ? nil : rawPastedText,
            lineItems: parsedReceipt?.items,
            merchant: parsedReceipt?.merchantName ?? title,
            isVerified: true
        )
        
        store.addTransaction(txn)
        
        // Reset state
        self.parsedReceipt = nil
        self.currentScanImage = nil
        self.rawPastedText = ""
        self.showReviewSheet = false
    }
}
