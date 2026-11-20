import SwiftUI

public struct AccountsView: View {
    @EnvironmentObject var store: DataStore
    
    @State private var showingAddAccountSheet = false
    @State private var showingAddCardSheet = false
    @State private var payingCard: CreditCard? = nil
    @State private var paymentAmountString: String = ""
    @State private var selectedPaymentAccountId: UUID? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Summary Header
                    HStack(spacing: 16) {
                        CardContainerView(padding: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOTAL BANK DEPOSITS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(0.6)
                                Text(store.totalCashBalance.formattedCurrency(code: store.selectedCurrency))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        CardContainerView(padding: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOTAL CREDIT DEBT")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(0.6)
                                Text(store.totalCreditDebt.formattedCurrency(code: store.selectedCurrency))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // MARK: - Credit Cards Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CREDIT CARDS & BILL CYCLE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .tracking(0.6)
                                Text("Track limits, utilization & due dates")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: { showingAddCardSheet = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Card")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        if store.creditCards.isEmpty {
                            Text("No credit cards added yet.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(store.creditCards) { card in
                                    VStack(spacing: 10) {
                                        CreditCardItemView(card: card)
                                        
                                        // Quick Action row for Card
                                        HStack {
                                            HStack(spacing: 4) {
                                                Image(systemName: card.isAutoPayEnabled ? "checkmark.circle.fill" : "exclamationmark.circle")
                                                    .font(.caption2)
                                                    .foregroundColor(card.isAutoPayEnabled ? .green : .orange)
                                                Text(card.isAutoPayEnabled ? "Auto-Pay Active" : "Manual Payment")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                payingCard = card
                                                paymentAmountString = String(format: "%.2f", card.currentBalance)
                                                selectedPaymentAccountId = store.accounts.first?.id
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "banknote")
                                                    Text("Pay Card")
                                                }
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 6)
                                                .background(Color.blue)
                                                .cornerRadius(20)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: - Bank Accounts Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CONNECTED BANK ACCOUNTS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .tracking(0.6)
                                Text("Checking, savings, and liquid cash")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: { showingAddAccountSheet = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Account")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        CardContainerView(padding: 8) {
                            VStack(spacing: 0) {
                                ForEach(store.accounts) { acc in
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: acc.colorHex).opacity(0.15))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: acc.type.iconName)
                                                .font(.headline)
                                                .foregroundColor(Color(hex: acc.colorHex))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(acc.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            HStack(spacing: 6) {
                                                Text(acc.institutionName)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text("•")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text("•••• \(acc.accountNumberLast4)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(acc.balance.formattedCurrency(code: acc.currency))
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(acc.balance >= 0 ? .primary : .red)
                                            Text(acc.type.rawValue)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    
                                    if acc.id != store.accounts.last?.id {
                                        Divider()
                                            .padding(.leading, 64)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Accounts & Cards")
            .sheet(isPresented: $showingAddAccountSheet) {
                AddAccountSheet()
            }
            .sheet(isPresented: $showingAddCardSheet) {
                AddCreditCardSheet()
            }
            .sheet(item: $payingCard) { card in
                PayCardModalSheet(
                    card: card,
                    amountString: $paymentAmountString,
                    selectedAccountId: $selectedPaymentAccountId
                )
            }
        }
    }
}

// MARK: - Pay Credit Card Modal Sheet
struct PayCardModalSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    let card: CreditCard
    @Binding var amountString: String
    @Binding var selectedAccountId: UUID?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Pay Credit Card Balance") {
                    HStack {
                        Text("Card")
                        Spacer()
                        Text("\(card.cardName) (****\(card.last4Digits))")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Current Balance")
                        Spacer()
                        Text(card.currentBalance.formattedCurrency(code: card.currency))
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Payment Amount ($)", text: $amountString)
                        .keyboardType(.decimalPad)
                }
                
                Section("Pay From Bank Account") {
                    Picker("Select Account", selection: $selectedAccountId) {
                        ForEach(store.accounts) { acc in
                            Text("\(acc.name) (\(acc.balance.formattedCurrency()))").tag(UUID?.some(acc.id))
                        }
                    }
                }
            }
            .navigationTitle("Make Card Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Payment") {
                        if let paymentAmount = Double(amountString), paymentAmount > 0 {
                            // 1. Add payment transaction
                            let txn = Transaction(
                                title: "Payment: \(card.cardName)",
                                amount: paymentAmount,
                                type: .expense,
                                category: .bills,
                                date: Date(),
                                notes: "Paid card balance",
                                accountId: selectedAccountId,
                                creditCardId: card.id,
                                source: .manual,
                                merchant: card.cardName
                            )
                            store.addTransaction(txn)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Add Account Sheet
struct AddAccountSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var name: String = ""
    @State private var type: AccountType = .checking
    @State private var balanceString: String = ""
    @State private var institution: String = ""
    @State private var last4: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name (e.g. Chase Main)", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    TextField("Financial Institution (e.g. Wells Fargo)", text: $institution)
                    TextField("Account Number (Last 4 digits)", text: $last4)
                        .keyboardType(.numberPad)
                    TextField("Current Balance ($)", text: $balanceString)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Bank Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let bal = Double(balanceString) ?? 0.0
                        let acc = Account(
                            name: name.isEmpty ? "New Account" : name,
                            type: type,
                            balance: bal,
                            accountNumberLast4: last4.isEmpty ? "0000" : last4,
                            institutionName: institution.isEmpty ? "Bank" : institution
                        )
                        store.addAccount(acc)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Credit Card Sheet
struct AddCreditCardSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var cardName: String = ""
    @State private var last4: String = ""
    @State private var limitString: String = ""
    @State private var balanceString: String = ""
    @State private var network: CardNetwork = .visa
    @State private var aprString: String = "24.99"
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 20, to: Date())!
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Credit Card Details") {
                    TextField("Card Name (e.g. Amex Blue Cash)", text: $cardName)
                    Picker("Card Network", selection: $network) {
                        ForEach(CardNetwork.allCases) { n in
                            Text(n.rawValue).tag(n)
                        }
                    }
                    TextField("Last 4 Digits", text: $last4)
                        .keyboardType(.numberPad)
                    TextField("Credit Limit ($)", text: $limitString)
                        .keyboardType(.decimalPad)
                    TextField("Current Balance ($)", text: $balanceString)
                        .keyboardType(.decimalPad)
                    TextField("APR (%)", text: $aprString)
                        .keyboardType(.decimalPad)
                    DatePicker("Next Payment Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Credit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let limit = Double(limitString) ?? 5000.0
                        let balance = Double(balanceString) ?? 0.0
                        let apr = Double(aprString) ?? 24.99
                        let card = CreditCard(
                            cardName: cardName.isEmpty ? "Credit Card" : cardName,
                            last4Digits: last4.isEmpty ? "0000" : last4,
                            creditLimit: limit,
                            currentBalance: balance,
                            paymentDueDate: dueDate,
                            apr: apr,
                            cardNetwork: network
                        )
                        store.addCreditCard(card)
                        dismiss()
                    }
                    .disabled(cardName.isEmpty)
                }
            }
        }
    }
}
