import Foundation

public enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense = "Expense"
    case income = "Income"
    case transfer = "Transfer"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .expense: return "arrow.up.right.circle.fill"
        case .income: return "arrow.down.left.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

public enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case groceries = "Groceries"
    case dining = "Dining & Food"
    case shopping = "Shopping"
    case utilities = "Utilities"
    case transport = "Transportation"
    case entertainment = "Entertainment"
    case health = "Health & Medical"
    case housing = "Housing & Rent"
    case income = "Salary & Income"
    case investment = "Investments"
    case bills = "Bills & Subscriptions"
    case education = "Education"
    case travel = "Travel"
    case business = "Business"
    case other = "Other"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .groceries: return "cart.fill"
        case .dining: return "fork.knife"
        case .shopping: return "bag.fill"
        case .utilities: return "bolt.fill"
        case .transport: return "car.fill"
        case .entertainment: return "popcorn.fill"
        case .health: return "heart.fill"
        case .housing: return "house.fill"
        case .income: return "dollarsign.arrow.circlepath"
        case .investment: return "chart.pie.fill"
        case .bills: return "doc.text.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .business: return "briefcase.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    public var defaultColorHex: String {
        switch self {
        case .groceries: return "#4CAF50"
        case .dining: return "#FF9800"
        case .shopping: return "#E91E63"
        case .utilities: return "#FFC107"
        case .transport: return "#00BCD4"
        case .entertainment: return "#9C27B0"
        case .health: return "#F44336"
        case .housing: return "#3F51B5"
        case .income: return "#2E7D32"
        case .investment: return "#009688"
        case .bills: return "#607D8B"
        case .education: return "#795548"
        case .travel: return "#03A9F4"
        case .business: return "#455A64"
        case .other: return "#9E9E9E"
        }
    }
}

public enum TransactionSource: String, Codable, CaseIterable, Identifiable {
    case receiptScan = "Receipt Scan (Camera/OCR)"
    case smsAlert = "SMS Alert / Message"
    case emailInvoice = "Email / PDF Invoice"
    case manual = "Manual Entry"
    case recurringBill = "Recurring Auto-Bill"
    
    public var id: String { rawValue }
    
    public var iconBadge: String {
        switch self {
        case .receiptScan: return "camera.viewfinder"
        case .smsAlert: return "message.badge.filled.fill"
        case .emailInvoice: return "envelope.open.fill"
        case .manual: return "square.and.pencil"
        case .recurringBill: return "repeat.circle.fill"
        }
    }
}

public struct Transaction: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var amount: Double
    public var type: TransactionType
    public var category: TransactionCategory
    public var date: Date
    public var notes: String?
    public var accountId: UUID?
    public var creditCardId: UUID?
    public var source: TransactionSource
    public var rawTextSource: String?
    public var lineItems: [ReceiptLineItem]?
    public var merchant: String?
    public var isVerified: Bool
    public var currency: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: TransactionType = .expense,
        category: TransactionCategory = .shopping,
        date: Date = Date(),
        notes: String? = nil,
        accountId: UUID? = nil,
        creditCardId: UUID? = nil,
        source: TransactionSource = .manual,
        rawTextSource: String? = nil,
        lineItems: [ReceiptLineItem]? = nil,
        merchant: String? = nil,
        isVerified: Bool = true,
        currency: String = "USD"
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.category = category
        self.date = date
        self.notes = notes
        self.accountId = accountId
        self.creditCardId = creditCardId
        self.source = source
        self.rawTextSource = rawTextSource
        self.lineItems = lineItems
        self.merchant = merchant
        self.isVerified = isVerified
        self.currency = currency
    }
}
