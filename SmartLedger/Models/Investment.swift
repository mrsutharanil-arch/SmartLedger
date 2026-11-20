import Foundation

public enum AssetClass: String, Codable, CaseIterable, Identifiable {
    case stocks = "Equities & Stocks"
    case etf = "Index Funds & ETFs"
    case crypto = "Cryptocurrency"
    case mutualFund = "Mutual Funds"
    case fixedIncome = "Bonds & Fixed Deposit"
    case realEstate = "Real Estate"
    case preciousMetals = "Gold & Commodities"
    case retirement = "Retirement / 401(k) / IRA"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .etf: return "square.stack.3d.up.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .mutualFund: return "chart.pie.fill"
        case .fixedIncome: return "building.columns.circle.fill"
        case .realEstate: return "house.and.flag.fill"
        case .preciousMetals: return "sparkles"
        case .retirement: return "person.crop.circle.badge.clock.fill"
        }
    }
    
    public var colorHex: String {
        switch self {
        case .stocks: return "#2196F3"
        case .etf: return "#3F51B5"
        case .crypto: return "#F57C00"
        case .mutualFund: return "#009688"
        case .fixedIncome: return "#4CAF50"
        case .realEstate: return "#795548"
        case .preciousMetals: return "#FFD700"
        case .retirement: return "#9C27B0"
        }
    }
}

public struct Investment: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var symbol: String
    public var assetClass: AssetClass
    public var quantity: Double
    public var averageCost: Double
    public var currentPrice: Double
    public var institution: String
    public var currency: String
    public var lastUpdated: Date
    public var notes: String?
    
    public var totalInvested: Double {
        return quantity * averageCost
    }
    
    public var currentValue: Double {
        return quantity * currentPrice
    }
    
    public var unrealizedReturn: Double {
        return currentValue - totalInvested
    }
    
    public var returnPercentage: Double {
        guard totalInvested > 0 else { return 0 }
        return (unrealizedReturn / totalInvested) * 100.0
    }
    
    public var isPositive: Bool {
        return unrealizedReturn >= 0
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        assetClass: AssetClass,
        quantity: Double,
        averageCost: Double,
        currentPrice: Double,
        institution: String = "Brokerage",
        currency: String = "USD",
        lastUpdated: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.assetClass = assetClass
        self.quantity = quantity
        self.averageCost = averageCost
        self.currentPrice = currentPrice
        self.institution = institution
        self.currency = currency
        self.lastUpdated = lastUpdated
        self.notes = notes
    }
}
