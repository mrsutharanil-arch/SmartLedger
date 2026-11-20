import Foundation

public enum InsightType: String, Codable, CaseIterable, Identifiable {
    case criticalAlert = "Alert"
    case spendingSpike = "Anomaly"
    case savingsOpportunity = "Optimization"
    case billReminder = "Upcoming Bill"
    case investmentTip = "Portfolio"
    case monthlySummary = "Overview"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .criticalAlert: return "exclamationmark.triangle.fill"
        case .spendingSpike: return "chart.line.uptrend.xyaxis.circle.fill"
        case .savingsOpportunity: return "leaf.fill"
        case .billReminder: return "clock.badge.exclamationmark.fill"
        case .investmentTip: return "sparkles"
        case .monthlySummary: return "newspaper.fill"
        }
    }
    
    public var tintColorHex: String {
        switch self {
        case .criticalAlert: return "#F44336"
        case .spendingSpike: return "#FF9800"
        case .savingsOpportunity: return "#4CAF50"
        case .billReminder: return "#2196F3"
        case .investmentTip: return "#9C27B0"
        case .monthlySummary: return "#009688"
        }
    }
}

public struct AIInsight: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var summary: String
    public var type: InsightType
    public var impactAmount: Double?
    public var createdAt: Date
    public var actionLabel: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        type: InsightType,
        impactAmount: Double? = nil,
        createdAt: Date = Date(),
        actionLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.type = type
        self.impactAmount = impactAmount
        self.createdAt = createdAt
        self.actionLabel = actionLabel
    }
}
