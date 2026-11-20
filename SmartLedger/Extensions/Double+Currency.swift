import Foundation

extension Double {
    public func formattedCurrency(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$\(String(format: "%.2f", self))"
    }
    
    public func formattedCompactCurrency(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        if abs(self) >= 1_000_000 {
            return String(format: "\(code == "USD" ? "$" : "")%.1fM", self / 1_000_000)
        } else if abs(self) >= 1_000 {
            return String(format: "\(code == "USD" ? "$" : "")%.1fk", self / 1_000)
        }
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "$\(Int(self))"
    }
}
