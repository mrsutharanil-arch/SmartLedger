import Foundation

public enum PreparedStatus: String, Codable, CaseIterable, Identifiable {
    case pendingReview = "pending_review"
    case approved = "approved"
    case rejected = "rejected"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .pendingReview: return "Ready for Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

public struct PreparedTransaction: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var amount: Double
    public var merchant: String
    public var category: TransactionCategory
    public var source: String
    public var status: PreparedStatus
    public var confidenceScore: Double
    public var currency: String
    public var suggestedCardLast4: String?
    public var suggestedAccountLast4: String?
    public var rawText: String?
    public var lineItems: [ReceiptLineItem]
    public var transactionDate: Date
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        amount: Double,
        merchant: String,
        category: TransactionCategory = .shopping,
        source: String = "auto_scan",
        status: PreparedStatus = .pendingReview,
        confidenceScore: Double = 0.95,
        currency: String = "USD",
        suggestedCardLast4: String? = nil,
        suggestedAccountLast4: String? = nil,
        rawText: String? = nil,
        lineItems: [ReceiptLineItem] = [],
        transactionDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.merchant = merchant
        self.category = category
        self.source = source
        self.status = status
        self.confidenceScore = confidenceScore
        self.currency = currency
        self.suggestedCardLast4 = suggestedCardLast4
        self.suggestedAccountLast4 = suggestedAccountLast4
        self.rawText = rawText
        self.lineItems = lineItems
        self.transactionDate = transactionDate
        self.createdAt = createdAt
    }
    
    public var readableSource: String {
        if source.contains("email") {
            return "Email Auto-Scan"
        } else if source.contains("sms") {
            return "Bank SMS Auto-Scan"
        } else if source.contains("photo") {
            return "Background Photo Scan"
        } else {
            return "Auto-Scan Backend"
        }
    }
    
    public var sourceIcon: String {
        if source.contains("email") {
            return "envelope.badge.shield.half.filled.fill"
        } else if source.contains("sms") {
            return "message.badge.filled.fill"
        } else {
            return "camera.viewfinder"
        }
    }
}
