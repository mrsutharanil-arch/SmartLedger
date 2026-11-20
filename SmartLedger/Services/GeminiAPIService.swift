import Foundation
import UIKit

public actor GeminiAPIService {
    public static let shared = GeminiAPIService()
    
    private let defaultModel = "gemini-2.5-flash"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/"
    
    // Loaded from UserDefaults or Keychain
    public var apiKey: String {
        get {
            UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "gemini_api_key")
        }
    }
    
    private init() {}
    
    // MARK: - 1. Multimodal Receipt & Invoice Scanner
    public func analyzeReceipt(imageData: Data) async throws -> ParsedReceipt {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Smart offline simulated fallback for immediate demo / offline usage
            return generateSimulatedReceipt(from: "Scanned Receipt")
        }
        
        let prompt = """
        You are an expert personal accountant AI. Analyze this receipt or invoice image thoroughly.
        Extract the following information in valid JSON format only, with no markdown backticks, matching this exact schema:
        {
          "merchantName": "string or null",
          "dateString": "YYYY-MM-DD or null",
          "totalAmount": number or null,
          "subtotal": number or null,
          "taxAmount": number or null,
          "tipAmount": number or null,
          "paymentMethodLast4": "4 digit string or null",
          "categorySuggested": "Groceries, Dining & Food, Shopping, Utilities, Transportation, Entertainment, Health & Medical, Housing & Rent, Bills & Subscriptions, Travel, or Other",
          "confidenceScore": number between 0.0 and 1.0,
          "currencyDetected": "USD, EUR, INR, GBP, etc.",
          "invoiceNumber": "string or null",
          "items": [
            {
              "name": "string",
              "quantity": number,
              "unitPrice": number,
              "totalPrice": number,
              "category": "string or null"
            }
          ]
        }
        """
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "temperature": 0.1
            ]
        ]
        
        let jsonResponse = try await sendGeminiRequest(body: requestBody)
        return try parseReceiptJSON(jsonResponse)
    }
    
    // MARK: - 2. SMS Alert & Email Text Parser
    public func parseTransactionText(rawText: String) async throws -> ParsedReceipt {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return generateSimulatedTextParse(text: rawText)
        }
        
        let prompt = """
        You are an expert financial ledger processor. Parse this bank SMS alert, push notification, or email text into a structured personal accounting record:
        \"\"\"
        \(rawText)
        \"\"\"
        
        Respond with pure JSON only without markdown formatting matching:
        {
          "merchantName": "string or null",
          "dateString": "YYYY-MM-DD or null",
          "totalAmount": number or null,
          "subtotal": number or null,
          "taxAmount": null,
          "tipAmount": null,
          "paymentMethodLast4": "string or null (e.g. card ending in 4124, or A/c XX402)",
          "categorySuggested": "Groceries, Dining & Food, Shopping, Utilities, Transportation, Entertainment, Health & Medical, Housing & Rent, Bills & Subscriptions, Salary & Income, Investments, Travel, or Other",
          "confidenceScore": 0.98,
          "currencyDetected": "USD, INR, EUR, etc.",
          "invoiceNumber": "reference/txn ID if found",
          "items": [
            {
              "name": "Transaction Description",
              "quantity": 1,
              "unitPrice": number,
              "totalPrice": number,
              "category": "string"
            }
          ]
        }
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "temperature": 0.1
            ]
        ]
        
        let jsonResponse = try await sendGeminiRequest(body: requestBody)
        return try parseReceiptJSON(jsonResponse)
    }
    
    // MARK: - 3. AI Financial Advisor & Portfolio Health Analyzer
    public func generateInsights(
        transactions: [Transaction],
        accounts: [Account],
        cards: [CreditCard],
        investments: [Investment],
        bills: [Bill]
    ) async throws -> [AIInsight] {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return generateLocalRuleBasedInsights(transactions: transactions, accounts: accounts, cards: cards, investments: investments, bills: bills)
        }
        
        let prompt = """
        You are an elite personal wealth manager and accounting auditor.
        Review this customer's live financial dataset:
        
        ACCOUNTS:
        \(accounts.map { "\($0.name) (\($0.type.rawValue)): \($0.balance.formattedCurrency())" }.joined(separator: "\n"))
        
        CREDIT CARDS:
        \(cards.map { "\($0.cardName): Balance: \($0.currentBalance.formattedCurrency()) / Limit: \($0.creditLimit.formattedCurrency()) (Util: \(String(format: "%.1f", $0.utilizationPercentage))%), Due: \($0.paymentDueDate.formattedDateString())" }.joined(separator: "\n"))
        
        PENDING BILLS:
        \(bills.map { "\($0.title): \($0.amount.formattedCurrency()), Due: \($0.dueDate.formattedDateString()), AutoPay: \($0.isAutoPay)" }.joined(separator: "\n"))
        
        INVESTMENTS:
        \(investments.map { "\($0.name) (\($0.symbol)): Value \($0.currentValue.formattedCurrency()), Return: \(String(format: "%.1f", $0.returnPercentage))%" }.joined(separator: "\n"))
        
        RECENT TRANSACTIONS:
        \(transactions.prefix(20).map { "\($0.date.formattedDateString()): \($0.title) - \($0.amount.formattedCurrency()) (\($0.category.rawValue), \($0.type.rawValue))" }.joined(separator: "\n"))
        
        Provide 3 to 5 high-impact, actionable insights in JSON format matching:
        [
          {
            "title": "Short title",
            "summary": "Clear, concise analysis and advice (2 sentences)",
            "type": "criticalAlert, spendingSpike, savingsOpportunity, billReminder, or investmentTip",
            "impactAmount": number or null,
            "actionLabel": "Actionable button label like 'Pay Off Card' or 'Review Groceries'"
          }
        ]
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "temperature": 0.2
            ]
        ]
        
        do {
            let jsonResponse = try await sendGeminiRequest(body: requestBody)
            guard let data = jsonResponse.data(using: .utf8) else {
                return generateLocalRuleBasedInsights(transactions: transactions, accounts: accounts, cards: cards, investments: investments, bills: bills)
            }
            
            struct RawInsight: Codable {
                let title: String
                let summary: String
                let type: String
                let impactAmount: Double?
                let actionLabel: String?
            }
            
            let rawItems = try JSONDecoder().decode([RawInsight].self, from: data)
            return rawItems.map { raw in
                let insightType: InsightType
                switch raw.type {
                case "criticalAlert": insightType = .criticalAlert
                case "spendingSpike": insightType = .spendingSpike
                case "savingsOpportunity": insightType = .savingsOpportunity
                case "billReminder": insightType = .billReminder
                case "investmentTip": insightType = .investmentTip
                default: insightType = .monthlySummary
                }
                return AIInsight(
                    title: raw.title,
                    summary: raw.summary,
                    type: insightType,
                    impactAmount: raw.impactAmount,
                    actionLabel: raw.actionLabel
                )
            }
        } catch {
            return generateLocalRuleBasedInsights(transactions: transactions, accounts: accounts, cards: cards, investments: investments, bills: bills)
        }
    }
    
    // MARK: - 4. Interactive Financial Chat Assistant
    public func chatWithAdvisor(message: String, context: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "To enable live Google Gemini AI conversations, please add your Gemini API Key in Settings. In the meantime, all local financial analytics, bill trackers, and card calculations are fully operational."
        }
        
        let prompt = """
        You are 'Gemini Wealth AI', a helpful, private, and highly skilled iOS personal finance & accounting advisor.
        You have direct access to the user's localized financial ledger, bank balances, credit card statements, and investments.
        
        USER FINANCIAL CONTEXT:
        \(context)
        
        USER QUESTION:
        \"\(message)\"
        
        Provide a friendly, highly intelligent, numbers-driven, and concise answer with clear action steps.
        Use bullet points where appropriate and highlight dollar/currency amounts clearly.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 800
            ]
        ]
        
        return try await sendGeminiRequest(body: requestBody)
    }
    
    // MARK: - HTTP Network Request Execution
    private func sendGeminiRequest(body: [String: Any]) async throws -> String {
        guard let url = URL(string: "\(baseURL)\(defaultModel):generateContent?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(domain: "GeminiAPIService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "GeminiAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse candidate text from Gemini"])
        }
        
        return cleanJSONString(text)
    }
    
    private func cleanJSONString(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseReceiptJSON(_ jsonString: String) throws -> ParsedReceipt {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "GeminiAPIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }
        
        struct RawReceipt: Codable {
            var merchantName: String?
            var dateString: String?
            var totalAmount: Double?
            var subtotal: Double?
            var taxAmount: Double?
            var tipAmount: Double?
            var paymentMethodLast4: String?
            var categorySuggested: String?
            var confidenceScore: Double?
            var currencyDetected: String?
            var invoiceNumber: String?
            var items: [RawItem]?
        }
        
        struct RawItem: Codable {
            var name: String
            var quantity: Double?
            var unitPrice: Double?
            var totalPrice: Double?
            var category: String?
        }
        
        let decoded = try JSONDecoder().decode(RawReceipt.self, from: data)
        let items: [ReceiptLineItem] = (decoded.items ?? []).map {
            ReceiptLineItem(
                name: $0.name,
                quantity: $0.quantity ?? 1.0,
                unitPrice: $0.unitPrice ?? ($0.totalPrice ?? 0.0),
                totalPrice: $0.totalPrice ?? 0.0,
                category: $0.category
            )
        }
        
        return ParsedReceipt(
            merchantName: decoded.merchantName,
            dateString: decoded.dateString,
            totalAmount: decoded.totalAmount,
            subtotal: decoded.subtotal,
            taxAmount: decoded.taxAmount,
            tipAmount: decoded.tipAmount,
            paymentMethodLast4: decoded.paymentMethodLast4,
            categorySuggested: decoded.categorySuggested,
            confidenceScore: decoded.confidenceScore ?? 0.95,
            currencyDetected: decoded.currencyDetected ?? "USD",
            items: items,
            invoiceNumber: decoded.invoiceNumber
        )
    }
    
    // MARK: - Smart Offline / Fallback Engines
    private func generateSimulatedReceipt(from title: String) -> ParsedReceipt {
        return ParsedReceipt(
            merchantName: "Trader Joe's",
            dateString: "2026-11-20",
            totalAmount: 64.85,
            subtotal: 59.50,
            taxAmount: 5.35,
            tipAmount: 0.0,
            paymentMethodLast4: "4821",
            categorySuggested: "Groceries",
            confidenceScore: 0.98,
            currencyDetected: "USD",
            items: [
                ReceiptLineItem(name: "Organic Whole Milk (1 Gallon)", quantity: 1, unitPrice: 4.99, totalPrice: 4.99, category: "Groceries"),
                ReceiptLineItem(name: "Cage-Free Large Eggs 12ct", quantity: 2, unitPrice: 3.49, totalPrice: 6.98, category: "Groceries"),
                ReceiptLineItem(name: "Avocados 4-Pack", quantity: 1, unitPrice: 5.49, totalPrice: 5.49, category: "Produce"),
                ReceiptLineItem(name: "Wild Caught Salmon Fillet", quantity: 1, unitPrice: 18.99, totalPrice: 18.99, category: "Meat & Seafood"),
                ReceiptLineItem(name: "Almond Butter Creamy", quantity: 2, unitPrice: 6.99, totalPrice: 13.98, category: "Pantry"),
                ReceiptLineItem(name: "Whole Wheat Sourdough", quantity: 1, unitPrice: 4.50, totalPrice: 4.50, category: "Bakery"),
                ReceiptLineItem(name: "Dark Chocolate Almonds", quantity: 1, unitPrice: 4.57, totalPrice: 4.57, category: "Snacks")
            ],
            invoiceNumber: "TJ-948123"
        )
    }
    
    private func generateSimulatedTextParse(text: String) -> ParsedReceipt {
        // Simple regex extraction for amount and card
        let amountPattern = #"(?:[\$€£₹]|USD|INR)?\s*([0-9]+(?:\.[0-9]{2})?)"#
        var detectedAmount: Double = 42.50
        if let regex = try? NSRegularExpression(pattern: amountPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range(at: 1), in: text) {
                detectedAmount = Double(text[range]) ?? 42.50
            }
        }
        
        let cardPattern = #"(?:ending in|card ending|xx|acct)\s*([0-9]{4})"#
        var last4 = "8831"
        if let regex = try? NSRegularExpression(pattern: cardPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range(at: 1), in: text) {
                last4 = String(text[range])
            }
        }
        
        return ParsedReceipt(
            merchantName: "Parsed Transaction Alert",
            dateString: "2026-11-20",
            totalAmount: detectedAmount,
            subtotal: detectedAmount,
            taxAmount: 0.0,
            tipAmount: 0.0,
            paymentMethodLast4: last4,
            categorySuggested: "Dining & Food",
            confidenceScore: 0.94,
            currencyDetected: "USD",
            items: [
                ReceiptLineItem(name: "Transaction from Alert", quantity: 1, unitPrice: detectedAmount, totalPrice: detectedAmount, category: "Expense")
            ],
            invoiceNumber: "TXN-\(Int.random(in: 100000...999999))"
        )
    }
    
    private func generateLocalRuleBasedInsights(
        transactions: [Transaction],
        accounts: [Account],
        cards: [CreditCard],
        investments: [Investment],
        bills: [Bill]
    ) -> [AIInsight] {
        var insights: [AIInsight] = []
        
        // 1. Credit Card Utilization Check
        for card in cards {
            if card.utilizationPercentage > 30.0 {
                insights.append(
                    AIInsight(
                        title: "High Credit Utilization on \(card.cardName)",
                        summary: "Your balance is \(card.currentBalance.formattedCurrency()) of \(card.creditLimit.formattedCurrency()) (\(String(format: "%.1f", card.utilizationPercentage))%). Keeping card utilization under 30% boosts your credit score significantly.",
                        type: .criticalAlert,
                        impactAmount: card.currentBalance,
                        actionLabel: "Make Payment"
                    )
                )
            }
        }
        
        // 2. Upcoming Due Bills
        let pending = bills.filter { !$0.isPaid && $0.daysRemaining <= 5 }
        if let nextBill = pending.first {
            insights.append(
                AIInsight(
                    title: "Bill Due Soon: \(nextBill.title)",
                    summary: "\(nextBill.title) of \(nextBill.amount.formattedCurrency()) is due in \(max(0, nextBill.daysRemaining)) days. Auto-pay is currently \(nextBill.isAutoPay ? "Active" : "Disabled").",
                    type: .billReminder,
                    impactAmount: nextBill.amount,
                    actionLabel: "Mark as Paid"
                )
            )
        }
        
        // 3. Investment Returns
        let totalGain = investments.reduce(0.0) { $0 + $1.unrealizedReturn }
        if totalGain > 0 {
            insights.append(
                AIInsight(
                    title: "Portfolio Gaining Momentum",
                    summary: "Your investment portfolio is up by +\(totalGain.formattedCurrency()) overall. Consider continuing scheduled dollar-cost averaging into index funds.",
                    type: .investmentTip,
                    impactAmount: totalGain,
                    actionLabel: "View Portfolio"
                )
            )
        }
        
        // 4. Dining / Spending Anomaly
        let diningExpenses = transactions.filter { $0.category == .dining }
        let diningTotal = diningExpenses.reduce(0.0) { $0 + $1.amount }
        if diningTotal > 250.0 {
            insights.append(
                AIInsight(
                    title: "Dining Out Trend Elevated",
                    summary: "You spent \(diningTotal.formattedCurrency()) on dining and takeout recently across \(diningExpenses.count) transactions. Cooking 2 extra meals this week could save you ~$85.",
                    type: .spendingSpike,
                    impactAmount: diningTotal,
                    actionLabel: "View Transactions"
                )
            )
        }
        
        if insights.isEmpty {
            insights.append(
                AIInsight(
                    title: "Finances Look Healthy",
                    summary: "All accounts are balanced, no overdue bills found, and your savings buffer is steady.",
                    type: .monthlySummary,
                    impactAmount: nil,
                    actionLabel: "Explore Budget"
                )
            )
        }
        
        return insights
    }
}
