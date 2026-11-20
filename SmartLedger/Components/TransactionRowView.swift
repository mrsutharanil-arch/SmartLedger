import SwiftUI

public struct TransactionRowView: View {
    public let transaction: Transaction
    
    public init(transaction: Transaction) {
        self.transaction = transaction
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Category Icon Badge
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.category.defaultColorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: transaction.category.defaultColorHex))
            }
            
            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(transaction.date.formattedRelativeOrDate())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // Ingestion Source Badge
                    HStack(spacing: 3) {
                        Image(systemName: transaction.source.iconBadge)
                            .font(.system(size: 9))
                        Text(sourceShortName(transaction.source))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .expense ? "-" : "+")\(transaction.amount.formattedCurrency(code: transaction.currency))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.type == .expense ? .primary : .green)
                
                if let items = transaction.lineItems, !items.isEmpty {
                    Text("\(items.count) items")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func sourceShortName(_ source: TransactionSource) -> String {
        switch source {
        case .receiptScan: return "Scan"
        case .smsAlert: return "SMS"
        case .emailInvoice: return "Email"
        case .manual: return "Manual"
        case .recurringBill: return "Auto-Bill"
        }
    }
}
