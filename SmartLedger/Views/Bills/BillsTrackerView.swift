import SwiftUI

public struct BillsTrackerView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedFilter: BillFilter = .all
    @State private var showingAddBillSheet = false
    @State private var payingBill: Bill? = nil
    
    enum BillFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case upcoming = "Upcoming"
        case paid = "Paid"
        
        var id: String { rawValue }
    }
    
    public init() {}
    
    var filteredBills: [Bill] {
        switch selectedFilter {
        case .all:
            return store.bills
        case .upcoming:
            return store.bills.filter { !$0.isPaid }
        case .paid:
            return store.bills.filter { $0.isPaid }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Summary Hero
                    HStack(spacing: 16) {
                        CardContainerView(padding: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PENDING BILLS TOTAL")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(0.6)
                                Text(store.pendingBillsTotal.formattedCurrency(code: store.selectedCurrency))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        CardContainerView(padding: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DUE WITHIN 7 DAYS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(0.6)
                                Text("\(store.upcomingBillsCount) Bills")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // MARK: - Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(BillFilter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // MARK: - Bills List
                    VStack(spacing: 12) {
                        ForEach(filteredBills) { bill in
                            BillRowCard(bill: bill) {
                                payingBill = bill
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Bills & Subscriptions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBillSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddBillSheet) {
                AddBillSheet()
            }
            .confirmationDialog(
                "Mark \(payingBill?.title ?? "Bill") as Paid?",
                isPresented: Binding(
                    get: { payingBill != nil },
                    set: { if !$0 { payingBill = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Confirm Paid & Record in Ledger") {
                    if let b = payingBill {
                        store.markBillPaid(billId: b.id)
                        payingBill = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    payingBill = nil
                }
            }
        }
    }
}

// MARK: - Bill Row Card
struct BillRowCard: View {
    let bill: Bill
    var onPayTap: () -> Void
    
    var body: some View {
        CardContainerView(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(bill.isPaid ? Color.green.opacity(0.15) : (bill.isOverdue ? Color.red.opacity(0.15) : Color.blue.opacity(0.15)))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: bill.isPaid ? "checkmark.circle.fill" : bill.category.icon)
                        .font(.headline)
                        .foregroundColor(bill.isPaid ? .green : (bill.isOverdue ? .red : .blue))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(bill.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 6) {
                        Text(bill.isPaid ? "Paid" : (bill.daysRemaining < 0 ? "Overdue by \(abs(bill.daysRemaining))d" : "Due in \(bill.daysRemaining)d"))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(bill.isPaid ? .green : (bill.daysRemaining <= 3 ? .red : .secondary))
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(bill.frequency.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if bill.isAutoPay {
                            HStack(spacing: 2) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 8))
                                Text("AutoPay")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.12))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(bill.amount.formattedCurrency(code: bill.currency))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(bill.isPaid ? .secondary : .primary)
                    
                    if !bill.isPaid {
                        Button(action: onPayTap) {
                            Text("Mark Paid")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Add Bill Sheet
struct AddBillSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var category: BillCategory = .utility
    @State private var frequency: BillFrequency = .monthly
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @State private var isAutoPay: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Bill Details") {
                    TextField("Bill Title (e.g. Electric Power)", text: $title)
                    TextField("Amount ($)", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $category) {
                        ForEach(BillCategory.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(BillFrequency.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    Toggle("Auto-Pay Enabled", isOn: $isAutoPay)
                }
            }
            .navigationTitle("Add Recurring Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amt = Double(amountString), !title.isEmpty {
                            let b = Bill(
                                title: title,
                                amount: amt,
                                dueDate: dueDate,
                                category: category,
                                frequency: frequency,
                                isAutoPay: isAutoPay
                            )
                            store.addBill(b)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || Double(amountString) == nil)
                }
            }
        }
    }
}
