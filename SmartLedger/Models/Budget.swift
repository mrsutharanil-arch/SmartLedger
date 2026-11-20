import Foundation

public struct Budget: Identifiable, Codable, Hashable {
    public let id: UUID
    public var category: TransactionCategory
    public var monthlyLimit: Double
    public var month: Int
    public var year: Int
    
    public init(
        id: UUID = UUID(),
        category: TransactionCategory,
        monthlyLimit: Double,
        month: Int = Calendar.current.component(.month, from: Date()),
        year: Int = Calendar.current.component(.year, from: Date())
    ) {
        self.id = id
        self.category = category
        self.monthlyLimit = monthlyLimit
        self.month = month
        self.year = year
    }
}
