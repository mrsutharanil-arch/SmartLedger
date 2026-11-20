import Foundation

public enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking = "Checking"
    case savings = "Savings"
    case cash = "Cash"
    case digitalWallet = "Digital Wallet"
    case business = "Business"
    case loan = "Personal Loan"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .checking: return "building.columns.fill"
        case .savings: return "banknote.fill"
        case .cash: return "dollarsign.circle.fill"
        case .digitalWallet: return "wallet.pass.fill"
        case .business: return "briefcase.fill"
        case .loan: return "chart.line.downtrend.xyaxis"
        }
    }
}

public struct Account: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var type: AccountType
    public var balance: Double
    public var currency: String
    public var accountNumberLast4: String
    public var institutionName: String
    public var icon: String
    public var colorHex: String
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        balance: Double,
        currency: String = "USD",
        accountNumberLast4: String = "0000",
        institutionName: String = "General Bank",
        icon: String = "building.columns.fill",
        colorHex: String = "#1E88E5",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.currency = currency
        self.accountNumberLast4 = accountNumberLast4
        self.institutionName = institutionName
        self.icon = icon
        self.colorHex = colorHex
        self.updatedAt = updatedAt
    }
}
