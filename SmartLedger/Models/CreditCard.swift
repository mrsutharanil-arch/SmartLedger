import Foundation

public enum CardNetwork: String, Codable, CaseIterable, Identifiable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case amex = "American Express"
    case discover = "Discover"
    case rupay = "RuPay"
    case other = "Other"
    
    public var id: String { rawValue }
    
    public var iconSymbol: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.circle.fill"
        case .amex: return "crown.fill"
        case .discover: return "globe.americas.fill"
        case .rupay: return "indianrupeesign.circle.fill"
        case .other: return "creditcard"
        }
    }
}

public struct CreditCard: Identifiable, Codable, Hashable {
    public let id: UUID
    public var cardName: String
    public var last4Digits: String
    public var creditLimit: Double
    public var currentBalance: Double
    public var statementClosingDate: Date
    public var paymentDueDate: Date
    public var minimumDue: Double
    public var apr: Double
    public var cardNetwork: CardNetwork
    public var colorGradientHex: [String]
    public var isAutoPayEnabled: Bool
    public var currency: String
    
    public var availableCredit: Double {
        return max(0, creditLimit - currentBalance)
    }
    
    public var utilizationPercentage: Double {
        guard creditLimit > 0 else { return 0 }
        return (currentBalance / creditLimit) * 100.0
    }
    
    public var daysUntilDue: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDue = calendar.startOfDay(for: paymentDueDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfDue)
        return components.day ?? 0
    }
    
    public init(
        id: UUID = UUID(),
        cardName: String,
        last4Digits: String,
        creditLimit: Double,
        currentBalance: Double,
        statementClosingDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        paymentDueDate: Date = Calendar.current.date(byAdding: .day, value: 25, to: Date()) ?? Date(),
        minimumDue: Double = 35.0,
        apr: Double = 24.99,
        cardNetwork: CardNetwork = .visa,
        colorGradientHex: [String] = ["#1A2980", "#26D0CE"],
        isAutoPayEnabled: Bool = false,
        currency: String = "USD"
    ) {
        self.id = id
        self.cardName = cardName
        self.last4Digits = last4Digits
        self.creditLimit = creditLimit
        self.currentBalance = currentBalance
        self.statementClosingDate = statementClosingDate
        self.paymentDueDate = paymentDueDate
        self.minimumDue = minimumDue
        self.apr = apr
        self.cardNetwork = cardNetwork
        self.colorGradientHex = colorGradientHex
        self.isAutoPayEnabled = isAutoPayEnabled
        self.currency = currency
    }
}
