import SwiftUI

public struct ParsedReceiptReviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    @ObservedObject var viewModel: IngestionViewModel
    
    @State private var merchantName: String
    @State private var totalAmountString: String
    @State private var taxAmountString: String
    @State private var tipAmountString: String
    @State private var selectedCategory: TransactionCategory
    @State private var selectedDate: Date
    @State private var notes: String
    @State private var selectedAccountId: UUID?
    @State private var selectedCreditCardId: UUID?
    
    public init(viewModel: IngestionViewModel, parsedReceipt: ParsedReceipt) {
        self.viewModel = viewModel
        
        _merchantName = State(initialValue: parsedReceipt.merchantName ?? "Scanned Merchant")
        _totalAmountString = State(initialValue: String(format: "%.2f", parsedReceipt.totalAmount ?? 0.0))
        _taxAmountString = State(initialValue: String(format: "%.2f", parsedReceipt.taxAmount ?? 0.0))
        _tipAmountString = State(initialValue: String(format: "%.2f", parsedReceipt.tipAmount ?? 0.0))
        
        let matchingCat = TransactionCategory.allCases.first {
            $0.rawValue.lowercased() == (parsedReceipt.categorySuggested ?? "").lowercased()
        } ?? .groceries
        _selectedCategory = State(initialValue: matchingCat)
        
        _selectedDate = State(initialValue: Date())
        _notes = State(initialValue: "Extracted via Gemini AI (\(viewModel.activeSource.rawValue))")
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Main Extracted Header
                Section("Gemini Extraction Summary") {
                    HStack {
                        Text("Confidence Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("\(Int((viewModel.parsedReceipt?.confidenceScore ?? 0.95) * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    TextField("Merchant / Title", text: $merchantName)
                        .font(.headline)
                    
                    HStack {
                        Text("Total Amount")
                        Spacer()
                        TextField("Total", text: $totalAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Tax")
                        Spacer()
                        TextField("Tax", text: $taxAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Tip")
                        Spacer()
                        TextField("Tip", text: $tipAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                }
                
                // Section 2: Account / Credit Card Mapping
                Section("Charge To Account or Card") {
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
                
                // Section 3: Extracted Line Items
                if let items = viewModel.parsedReceipt?.items, !items.isEmpty {
                    Section("Extracted Line Items (\(items.count))") {
                        ForEach(items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if item.quantity > 1 {
                                        Text("\(Int(item.quantity)) × \(item.unitPrice.formattedCurrency())")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text(item.totalPrice.formattedCurrency())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                
                // Section 4: Notes & Context
                Section("Notes") {
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Verify Ingestion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        viewModel.showReviewSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Ledger") {
                        let amount = Double(totalAmountString) ?? 0.0
                        viewModel.commitParsedTransaction(
                            store: store,
                            title: merchantName,
                            amount: amount,
                            category: selectedCategory,
                            date: selectedDate,
                            notes: notes,
                            accountId: selectedAccountId,
                            creditCardId: selectedCreditCardId
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                // Auto-match card if last 4 was detected by Gemini!
                if let last4 = viewModel.parsedReceipt?.paymentMethodLast4 {
                    if let matchedCard = store.creditCards.first(where: { $0.last4Digits == last4 }) {
                        selectedCreditCardId = matchedCard.id
                    } else if let matchedAcc = store.accounts.first(where: { $0.accountNumberLast4 == last4 }) {
                        selectedAccountId = matchedAcc.id
                    }
                }
            }
        }
    }
}
