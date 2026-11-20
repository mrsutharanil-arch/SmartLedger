import SwiftUI

public struct PreparedTransactionsInboxView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    @State private var selectedItemForEdit: PreparedTransaction? = nil
    
    public init() {}
    
    var pendingItems: [PreparedTransaction] {
        store.preparedTransactions.filter { $0.status == .pendingReview }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // MARK: - Hero Explanation Banner
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            Image(systemName: "bolt.badge.automatic.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Auto-Scanned by Backend")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Transactions prepared from bank alerts, forwarded receipts, and background scans. Review and approve in 1 tap.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // MARK: - Batch Approve All Button
                    if !pendingItems.isEmpty {
                        Button(action: {
                            store.approveAllPreparedTransactions()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Approve All (\(pendingItems.count)) Transactions")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .cornerRadius(14)
                            .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                    }
                    
                    // MARK: - Empty State
                    if pendingItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("All Caught Up!")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("No pending auto-scanned transactions. As incoming bank alerts or receipt emails arrive, they will appear here automatically.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // MARK: - Prepared Items List
                        VStack(spacing: 14) {
                            ForEach(pendingItems) { item in
                                PreparedCardRow(item: item, onApprove: {
                                    store.approvePreparedTransaction(prepared: item)
                                }, onReject: {
                                    store.rejectPreparedTransaction(prepared: item)
                                })
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Auto-Scan Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        store.syncPreparedFromBackend()
                    }) {
                        HStack(spacing: 4) {
                            if store.isSyncingBackend {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Sync")
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - Prepared Card Row
struct PreparedCardRow: View {
    let item: PreparedTransaction
    var onApprove: () -> Void
    var onReject: () -> Void
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        CardContainerView(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                // Top Meta row
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: item.sourceIcon)
                            .font(.system(size: 10))
                        Text(item.readableSource)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                        Text("\(Int(item.confidenceScore * 100))% AI Confirmed")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(6)
                }
                
                // Details row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.merchant)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if let card = item.suggestedCardLast4 {
                            Text("Matched Card: •••• \(card)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(item.amount.formattedCurrency(code: item.currency))
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                }
                
                // Extracted Line Items Toggle
                if !item.lineItems.isEmpty {
                    Divider()
                    
                    Button(action: {
                        withAnimation { isExpanded.toggle() }
                    }) {
                        HStack {
                            Text("\(item.lineItems.count) Extracted Line Items")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if isExpanded {
                        VStack(spacing: 6) {
                            ForEach(item.lineItems) { line in
                                HStack {
                                    Text(line.name)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(line.totalPrice.formattedCurrency(code: item.currency))
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Divider()
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Discard")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                    
                    Button(action: onApprove) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                            Text("Approve & Deduct")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}
