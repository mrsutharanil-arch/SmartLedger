import Foundation

public actor BackendSyncService {
    public static let shared = BackendSyncService()
    
    public var backendURL: String {
        get {
            UserDefaults.standard.string(forKey: "backend_server_url") ?? "http://localhost:8000"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "backend_server_url")
        }
    }
    
    private init() {}
    
    // MARK: - Fetch Prepared Transactions
    public func fetchPreparedTransactions() async throws -> [PreparedTransaction] {
        guard let url = URL(string: "\(backendURL)/api/v1/prepared?status=pending_review") else {
            return generateOfflineSimulatedPrepared()
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 4.0
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return generateOfflineSimulatedPrepared()
            }
            
            struct RawPreparedResponse: Codable {
                let id: String
                let title: String
                let amount: Double
                let merchant: String
                let category: String
                let source: String
                let status: String
                let confidence_score: Double
                let currency: String
                let suggested_card_last4: String?
                let suggested_account_last4: String?
                let raw_text: String?
                let line_items: [RawItem]
                let transaction_date: String
                let created_at: String
                
                struct RawItem: Codable {
                    let name: String
                    let quantity: Double?
                    let unit_price: Double?
                    let total_price: Double?
                    let category: String?
                }
            }
            
            let rawList = try JSONDecoder().decode([RawPreparedResponse].self, from: data)
            return rawList.map { raw in
                let matchedCategory = TransactionCategory.allCases.first {
                    $0.rawValue.lowercased() == raw.category.lowercased()
                } ?? .shopping
                
                let lineItems = raw.line_items.map {
                    ReceiptLineItem(
                        name: $0.name,
                        quantity: $0.quantity ?? 1.0,
                        unitPrice: $0.unit_price ?? 0.0,
                        totalPrice: $0.total_price ?? 0.0,
                        category: $0.category
                    )
                }
                
                return PreparedTransaction(
                    id: raw.id,
                    title: raw.title,
                    amount: raw.amount,
                    merchant: raw.merchant,
                    category: matchedCategory,
                    source: raw.source,
                    status: .pendingReview,
                    confidenceScore: raw.confidence_score,
                    currency: raw.currency,
                    suggestedCardLast4: raw.suggested_card_last4,
                    suggestedAccountLast4: raw.suggested_account_last4,
                    rawText: raw.raw_text,
                    lineItems: lineItems,
                    transactionDate: Date(),
                    createdAt: Date()
                )
            }
        } catch {
            return generateOfflineSimulatedPrepared()
        }
    }
    
    // MARK: - Approve Transaction on Backend
    public func approvePreparedTransaction(id: String) async {
        guard let url = URL(string: "\(backendURL)/api/v1/prepared/\(id)/approve") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try? await URLSession.shared.data(for: req)
    }
    
    // MARK: - Reject Transaction on Backend
    public func rejectPreparedTransaction(id: String) async {
        guard let url = URL(string: "\(backendURL)/api/v1/prepared/\(id)/reject") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        _ = try? await URLSession.shared.data(for: req)
    }
    
    // MARK: - Batch Approve All
    public func approveAllPrepared() async {
        guard let url = URL(string: "\(backendURL)/api/v1/prepared/batch/approve-all") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        _ = try? await URLSession.shared.data(for: req)
    }
    
    // MARK: - Offline / Standalone Fallback Simulation
    public func generateOfflineSimulatedPrepared() -> [PreparedTransaction] {
        return [
            PreparedTransaction(
                id: "mock-auto-1",
                title: "Costco Wholesale Electronic Receipt",
                amount: 182.45,
                merchant: "Costco Wholesale #482",
                category: .groceries,
                source: "email_auto_scan",
                confidenceScore: 0.98,
                currency: "USD",
                suggestedCardLast4: "1008",
                rawText: "Thank you for shopping at Costco. Order Total: $182.45 charged to Visa ending in 1008 on 11/20/2026.",
                lineItems: [
                    ReceiptLineItem(name: "Kirkland Organic Eggs 24ct", quantity: 1, unitPrice: 7.99, totalPrice: 7.99, category: "Groceries"),
                    ReceiptLineItem(name: "Organic Olive Oil 2L", quantity: 1, unitPrice: 22.99, totalPrice: 22.99, category: "Pantry"),
                    ReceiptLineItem(name: "Paper Towels 12ct", quantity: 1, unitPrice: 24.99, totalPrice: 24.99, category: "Household"),
                    ReceiptLineItem(name: "Choice Ribeye Steaks", quantity: 1, unitPrice: 54.50, totalPrice: 54.50, category: "Meat"),
                    ReceiptLineItem(name: "Kirkland Protein Bars", quantity: 2, unitPrice: 19.99, totalPrice: 39.98, category: "Snacks")
                ]
            ),
            PreparedTransaction(
                id: "mock-auto-2",
                title: "Chase Bank SMS Alert: Shell Oil",
                amount: 48.75,
                merchant: "Shell Oil Station",
                category: .transport,
                source: "sms_auto_scan",
                confidenceScore: 0.96,
                currency: "USD",
                suggestedCardLast4: "9314",
                rawText: "Chase Alert: You made a $48.75 purchase at SHELL OIL on card ending 9314 at 1:15 PM.",
                lineItems: [
                    ReceiptLineItem(name: "Regular Unleaded Gas (12.5 gal)", quantity: 1, unitPrice: 48.75, totalPrice: 48.75, category: "Fuel")
                ]
            ),
            PreparedTransaction(
                id: "mock-auto-3",
                title: "Uber Eats Delivery Receipt",
                amount: 32.10,
                merchant: "Chipotle Mexican Grill",
                category: .dining,
                source: "email_auto_scan",
                confidenceScore: 0.97,
                currency: "USD",
                suggestedCardLast4: "3029",
                rawText: "Uber Eats Receipt: Your order from Chipotle Mexican Grill was delivered. Total: $32.10.",
                lineItems: [
                    ReceiptLineItem(name: "Chicken Burrito Bowl", quantity: 1, unitPrice: 12.80, totalPrice: 12.80, category: "Food"),
                    ReceiptLineItem(name: "Chips & Guacamole", quantity: 1, unitPrice: 5.40, totalPrice: 5.40, category: "Food"),
                    ReceiptLineItem(name: "Delivery Fee & Tip", quantity: 1, unitPrice: 13.90, totalPrice: 13.90, category: "Service")
                ]
            )
        ]
    }
}
