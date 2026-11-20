import Foundation

public enum BillCategory: String, Codable, CaseIterable, Identifiable {
    case utility = "Utility (Power, Water, Gas)"
    case rent = "Rent & Mortgage"
    case subscription = "Subscription (Streaming, Software)"
    case loanEmi = "Loan EMI"
    case creditCardBill = "Credit Card Bill"
    case insurance = "Insurance"
    case internet = "Internet & Mobile"
    case other = "Other Bill"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .utility: return "bolt.fill"
        case .rent: return "house.fill"
        case .subscription: return "play.tv.fill"
        case .loanEmi: return "percent"
        case .creditCardBill: return "creditcard.fill"
        case .insurance: return "shield.lefthalf.filled"
        case .internet: return "wifi"
        case .other: return "doc.text.fill"
        }
    }
}

public enum BillFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case oneTime = "One-Time"
    
    public var id: String { rawValue }
}

public struct Bill: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var amount: Double
    public var dueDate: Date
    public var category: BillCategory
    public var frequency: BillFrequency
    public var isPaid: Bool
    public var paidDate: Date?
    public var isAutoPay: Bool
    public var linkedAccountId: UUID?
    public var linkedCreditCardId: UUID?
    public var reminderDaysBefore: Int
    public var notes: String?
    public var currency: String
    
    public var isOverdue: Bool {
        if isPaid { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        return due < today
    }
    
    public var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        let components = calendar.dateComponents([.day], from: today, to: due)
        return components.day ?? 0
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        dueDate: Date,
        category: BillCategory = .utility,
        frequency: BillFrequency = .monthly,
        isPaid: Bool = false,
        paidDate: Date? = nil,
        isAutoPay: Bool = false,
        linkedAccountId: UUID? = nil,
        linkedCreditCardId: UUID? = nil,
        reminderDaysBefore: Int = 3,
        notes: String? = nil,
        currency: String = "USD"
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.dueDate = dueDate
        self.category = category
        self.frequency = frequency
        self.isPaid = isPaid
        self.paidDate = paidDate
        self.isAutoPay = isAutoPay
        self.linkedAccountId = linkedAccountId
        self.linkedCreditCardId = linkedCreditCardId
        self.reminderDaysBefore = reminderDaysBefore
        self.notes = notes
        self.currency = currency
    }
}
