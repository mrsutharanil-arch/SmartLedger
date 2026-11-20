import Foundation

public struct ReceiptLineItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var quantity: Double
    public var unitPrice: Double
    public var totalPrice: Double
    public var category: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1.0,
        unitPrice: Double = 0.0,
        totalPrice: Double = 0.0,
        category: String? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.category = category
    }
}

public struct ParsedReceipt: Codable, Hashable {
    public var merchantName: String?
    public var dateString: String?
    public var totalAmount: Double?
    public var subtotal: Double?
    public var taxAmount: Double?
    public var tipAmount: Double?
    public var paymentMethodLast4: String?
    public var categorySuggested: String?
    public var confidenceScore: Double
    public var currencyDetected: String?
    public var items: [ReceiptLineItem]
    public var invoiceNumber: String?
    
    public init(
        merchantName: String? = nil,
        dateString: String? = nil,
        totalAmount: Double? = nil,
        subtotal: Double? = nil,
        taxAmount: Double? = nil,
        tipAmount: Double? = nil,
        paymentMethodLast4: String? = nil,
        categorySuggested: String? = nil,
        confidenceScore: Double = 0.95,
        currencyDetected: String? = "USD",
        items: [ReceiptLineItem] = [],
        invoiceNumber: String? = nil
    ) {
        self.merchantName = merchantName
        self.dateString = dateString
        self.totalAmount = totalAmount
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.tipAmount = tipAmount
        self.paymentMethodLast4 = paymentMethodLast4
        self.categorySuggested = categorySuggested
        self.confidenceScore = confidenceScore
        self.currencyDetected = currencyDetected
        self.items = items
        self.invoiceNumber = invoiceNumber
    }
}
