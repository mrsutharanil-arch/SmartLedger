import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAddExpenseSheet = false
    @State private var showingScanHub = false
    @State private var showingPreparedInbox = false
    @State private var companyProfile: CompanyProfile = CompanyProfileView.loadSavedProfile()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    // MARK: - 0. Company Branding & Logo Banner
                    NavigationLink(destination: CompanyProfileView()) {
                        CompanyBrandingHeaderView(profile: companyProfile)
                    }
                    .buttonStyle(.plain)
                    
                    // MARK: - 1. Net Worth Hero Card
                    NetWorthHeroView()
                    
                    // MARK: - 2. Auto-Scan Prepared Transactions Callout Banner
                    if store.pendingPreparedCount > 0 {
                        PreparedTransactionsCalloutBanner(
                            count: store.pendingPreparedCount,
                            onTap: { showingPreparedInbox = true }
                        )
                    }
                    
                    // MARK: - 3. Gemini AI Insight Callout
                    if let topInsight = store.insights.first {
                        TopInsightBannerView(insight: topInsight)
                    }
                    
                    // MARK: - 4. Quick Action Buttons
                    QuickActionBar(
                        onScanTap: { showingScanHub = true },
                        onAddExpenseTap: { showingAddExpenseSheet = true }
                    )
                    
                    // MARK: - 5. Monthly Cash Flow Summary
                    CashFlowSummaryCard()
                    
                    // MARK: - 6. Accounts & Cards Quick Carousel
                    AccountsOverviewCarousel()
                    
                    // MARK: - 7. Recent Ingested Transactions
                    RecentTransactionsSection()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("SmartLedger")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                companyProfile = CompanyProfileView.loadSavedProfile()
            }
            .sheet(isPresented: $showingAddExpenseSheet) {
                QuickManualAddSheet()
            }
            .sheet(isPresented: $showingScanHub) {
                NavigationStack {
                    ScanHubView()
                }
            }
            .sheet(isPresented: $showingPreparedInbox) {
                PreparedTransactionsInboxView()
            }
        }
    }
}

// MARK: - Auto-Scan Prepared Transactions Callout Banner
struct PreparedTransactionsCalloutBanner: View {
    let count: Int
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FF6F00").opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bolt.badge.automatic.fill")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#FF6F00"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("AUTO-SCAN READY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#FF6F00"))
                            .tracking(0.8)
                        Spacer()
                        Text("\(count) New")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#FF6F00"))
                            .cornerRadius(10)
                    }
                    
                    Text("\(count) Transactions Prepared on Backend")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Auto-parsed from bank SMS and receipts. Tap to approve.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: "#FF6F00").opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
    }
}

// MARK: - Net Worth Hero View
struct NetWorthHeroView: View {
    @EnvironmentObject var store: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOTAL NET WORTH")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1.0)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Live Ledger")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }
            
            Text(store.netWorth.formattedCurrency(code: store.selectedCurrency))
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cash & Banks")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.75))
                    Text(store.totalCashBalance.formattedCurrency(code: store.selectedCurrency))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Investments")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.75))
                    Text(store.totalInvestmentsValue.formattedCurrency(code: store.selectedCurrency))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#80D8FF"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Credit Debt")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.75))
                    Text(store.totalCreditDebt.formattedCurrency(code: store.selectedCurrency))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#FF8A80"))
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#0F2027"), Color(hex: "#203A43"), Color(hex: "#2C5364")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Top Insight Banner View
struct TopInsightBannerView: View {
    let insight: AIInsight
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: insight.type.tintColorHex).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: insight.type.icon)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: insight.type.tintColorHex))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("GEMINI ADVISOR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: insight.type.tintColorHex))
                        .tracking(0.8)
                    Spacer()
                    Text(insight.type.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                Text(insight.title)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(insight.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: insight.type.tintColorHex).opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Quick Action Bar
struct QuickActionBar: View {
    var onScanTap: () -> Void
    var onAddExpenseTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onScanTap) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.headline)
                    Text("Scan / Ingest")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color(hex: "#1565C0")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            
            Button(action: onAddExpenseTap) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text("Quick Add")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Cash Flow Summary Card
struct CashFlowSummaryCard: View {
    @EnvironmentObject var store: DataStore
    
    var body: some View {
        CardContainerView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("THIS MONTH'S CASH FLOW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .tracking(0.6)
                    Spacer()
                    Text(Date().formattedMonthYear())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.left")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("Income")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(store.currentMonthIncome.formattedCurrency(code: store.selectedCurrency))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Divider()
                        .frame(height: 36)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text("Expenses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(store.currentMonthExpenses.formattedCurrency(code: store.selectedCurrency))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Divider()
                        .frame(height: 36)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "equal.circle")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Net Saved")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(store.currentMonthCashFlow.formattedCurrency(code: store.selectedCurrency))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(store.currentMonthCashFlow >= 0 ? .primary : .red)
                    }
                }
            }
        }
    }
}

// MARK: - Accounts Carousel
struct AccountsOverviewCarousel: View {
    @EnvironmentObject var store: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ACCOUNTS & WALLETS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(0.6)
                Spacer()
                NavigationLink(destination: AccountsView()) {
                    Text("See All")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.accounts) { acc in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: acc.type.iconName)
                                    .foregroundColor(Color(hex: acc.colorHex))
                                Spacer()
                                Text(acc.type.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(acc.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                
                                Text(acc.balance.formattedCurrency(code: acc.currency))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(14)
                        .frame(width: 160)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Recent Transactions Section
struct RecentTransactionsSection: View {
    @EnvironmentObject var store: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT INGESTED TRANSACTIONS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(0.6)
                Spacer()
                Text("\(store.transactions.count) Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            CardContainerView(padding: 8) {
                VStack(spacing: 0) {
                    ForEach(store.transactions.prefix(5)) { txn in
                        TransactionRowView(transaction: txn)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                        
                        if txn.id != store.transactions.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Quick Manual Add Sheet
struct QuickManualAddSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var type: TransactionType = .expense
    @State private var category: TransactionCategory = .dining
    @State private var selectedAccountId: UUID? = nil
    @State private var selectedCreditCardId: UUID? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Info") {
                    TextField("Merchant or Description", text: $title)
                    TextField("Amount ($)", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(TransactionCategory.allCases) { c in
                            HStack {
                                Image(systemName: c.icon)
                                Text(c.rawValue)
                            }.tag(c)
                        }
                    }
                }
                
                Section("Paid From / Account") {
                    Picker("Bank Account", selection: $selectedAccountId) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.accounts) { acc in
                            Text("\(acc.name) (\(acc.balance.formattedCurrency()))").tag(UUID?.some(acc.id))
                        }
                    }
                    
                    Picker("Credit Card", selection: $selectedCreditCardId) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.creditCards) { card in
                            Text("\(card.cardName) (****\(card.last4Digits))").tag(UUID?.some(card.id))
                        }
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = Double(amountString), !title.isEmpty {
                            let txn = Transaction(
                                title: title,
                                amount: amount,
                                type: type,
                                category: category,
                                date: Date(),
                                accountId: selectedAccountId,
                                creditCardId: selectedCreditCardId,
                                source: .manual,
                                merchant: title
                            )
                            store.addTransaction(txn)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || Double(amountString) == nil)
                }
            }
        }
    }
}
