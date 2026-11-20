import Foundation

public struct SMSParserService {
    public static let shared = SMSParserService()
    
    private init() {}
    
    public struct QuickParsedAlert {
        public let amount: Double?
        public let merchant: String?
        public let cardOrAccountLast4: String?
        public let type: TransactionType
        public let rawText: String
    }
    
    public func quickParse(text: String) -> QuickParsedAlert {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Detect Amount
        var detectedAmount: Double? = nil
        let amountPatterns = [
            #"(?:spent|charged|debited|paid|withdrawn|purchase of|amount of|txn of|INR|USD|\$|₹|€|£)\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)"#,
            #"([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:spent|debited|paid)"#
        ]
        
        for pattern in amountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
               let range = Range(match.range(at: 1), in: cleaned) {
                let numberString = cleaned[range].replacingOccurrences(of: ",", with: "")
                if let val = Double(numberString) {
                    detectedAmount = val
                    break
                }
            }
        }
        
        // 2. Detect Card or Account last 4
        var last4: String? = nil
        let cardPatterns = [
            #"(?:card|acct|account|ending|xx|x)\s*(?:in|no\.?|#)?\s*([0-9]{4})"#,
            #"([0-9]{4})\s*(?:is charged|debited)"#
        ]
        for pattern in cardPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
               let range = Range(match.range(at: 1), in: cleaned) {
                last4 = String(cleaned[range])
                break
            }
        }
        
        // 3. Detect Merchant / Beneficiary
        var merchantName: String? = nil
        let merchantPatterns = [
            #"(?:at|to|in favor of|vpa)\s+([A-Za-z0-9\s\.\&\*\-]+?)(?:\s+on|\s+ref|\s+avail|\s+balance|\s+limit|\.|$)"#
        ]
        for pattern in merchantPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
               let range = Range(match.range(at: 1), in: cleaned) {
                let found = cleaned[range].trimmingCharacters(in: .whitespacesAndNewlines)
                if found.count >= 2 && found.count <= 40 {
                    merchantName = found
                    break
                }
            }
        }
        
        // 4. Type detection
        let lower = cleaned.lowercased()
        let isIncome = lower.contains("credited") || lower.contains("deposited") || lower.contains("salary") || lower.contains("refund")
        
        return QuickParsedAlert(
            amount: detectedAmount,
            merchant: merchantName,
            cardOrAccountLast4: last4,
            type: isIncome ? .income : .expense,
            rawText: cleaned
        )
    }
}
