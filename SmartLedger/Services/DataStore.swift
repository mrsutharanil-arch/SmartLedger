import Foundation
import SwiftUI
import Combine

@MainActor
public class DataStore: ObservableObject {
    public static let shared = DataStore()
    
    // MARK: - Published Collections
    @Published public var accounts: [Account] = []
    @Published public var creditCards: [CreditCard] = []
    @Published public var transactions: [Transaction] = []
    @Published public var bills: [Bill] = []
    @Published public var investments: [Investment] = []
    @Published public var budgets: [Budget] = []
    @Published public var insights: [AIInsight] = []
    @Published public var isGeneratingInsights: Bool = false
    
    // Auto-Scanned Prepared Transactions Waiting for User Review
    @Published public var preparedTransactions: [PreparedTransaction] = []
    @Published public var isSyncingBackend: Bool = false
    
    @Published public var selectedCurrency: String = "USD"
    
    private let accountsFile = "accounts.json"
    private let cardsFile = "credit_cards.json"
    private let txnsFile = "transactions.json"
    private let billsFile = "bills.json"
    private let investmentsFile = "investments.json"
    private let preparedFile = "prepared_transactions.json"
    
    public init() {
        loadData()
        if accounts.isEmpty && creditCards.isEmpty && transactions.isEmpty {
            loadMockData()
        }
        if preparedTransactions.isEmpty {
            loadMockPreparedTransactions()
        }
        refreshRuleBasedInsights()
        syncPreparedFromBackend()
    }
    
    // MARK: - Financial Computed Metrics
    public var totalCashBalance: Double {
        accounts.reduce(0.0) { $0 + $1.balance }
    }
    
    public var totalCreditDebt: Double {
        creditCards.reduce(0.0) { $0 + $1.currentBalance }
    }
    
    public var totalInvestmentsValue: Double {
        investments.reduce(0.0) { $0 + $1.currentValue }
    }
    
    public var netWorth: Double {
        (totalCashBalance + totalInvestmentsValue) - totalCreditDebt
    }
    
    public var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
    }
    
    public var currentMonthExpenses: Double {
        currentMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    public var currentMonthIncome: Double {
        currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    public var currentMonthCashFlow: Double {
        currentMonthIncome - currentMonthExpenses
    }
    
    public var pendingBillsTotal: Double {
        bills.filter { !$0.isPaid }.reduce(0.0) { $0 + $1.amount }
    }
    
    public var upcomingBillsCount: Int {
        bills.filter { !$0.isPaid && $0.daysRemaining >= 0 && $0.daysRemaining <= 7 }.count
    }
    
    public var pendingPreparedCount: Int {
        preparedTransactions.filter { $0.status == .pendingReview }.count
    }
    
    // MARK: - Auto-Scan Backend Sync & Prepared Transactions
    public func syncPreparedFromBackend() {
        self.isSyncingBackend = true
        Task {
            do {
                let items = try await BackendSyncService.shared.fetchPreparedTransactions()
                await MainActor.run {
                    // Merge incoming without duplicating IDs
                    for item in items {
                        if !self.preparedTransactions.contains(where: { $0.id == item.id }) {
                            self.preparedTransactions.insert(item, at: 0)
                        }
                    }
                    self.isSyncingBackend = false
                    self.saveData()
                }
            } catch {
                await MainActor.run {
                    self.isSyncingBackend = false
                }
            }
        }
    }
    
    public func approvePreparedTransaction(
        prepared: PreparedTransaction,
        targetAccountId: UUID? = nil,
        targetCardId: UUID? = nil
    ) {
        guard let index = preparedTransactions.firstIndex(where: { $0.id == prepared.id }) else { return }
        preparedTransactions[index].status = .approved
        
        // Auto-match Card or Account by last 4 if not supplied
        var matchedCardId = targetCardId
        var matchedAccId = targetAccountId
        
        if matchedCardId == nil && matchedAccId == nil {
            if let last4 = prepared.suggestedCardLast4,
               let card = creditCards.first(where: { $0.last4Digits == last4 }) {
                matchedCardId = card.id
            } else if let last4 = prepared.suggestedAccountLast4,
                      let acc = accounts.first(where: { $0.accountNumberLast4 == last4 }) {
                matchedAccId = acc.id
            } else {
                // Default to primary checking account or primary card
                matchedAccId = accounts.first?.id
            }
        }
        
        // Create full confirmed transaction in active ledger
        let sourceEnum: TransactionSource
        if prepared.source.contains("email") {
            sourceEnum = .emailInvoice
        } else if prepared.source.contains("sms") {
            sourceEnum = .smsAlert
        } else {
            sourceEnum = .receiptScan
        }
        
        let newTxn = Transaction(
            title: prepared.title,
            amount: prepared.amount,
            type: .expense,
            category: prepared.category,
            date: prepared.transactionDate,
            notes: "Auto-prepared by backend (\(prepared.readableSource))",
            accountId: matchedAccId,
            creditCardId: matchedCardId,
            source: sourceEnum,
            rawTextSource: prepared.rawText,
            lineItems: prepared.lineItems,
            merchant: prepared.merchant,
            isVerified: true,
            currency: prepared.currency
        )
        
        addTransaction(newTxn)
        
        // Notify backend asynchronously
        Task {
            await BackendSyncService.shared.approvePreparedTransaction(id: prepared.id)
        }
        
        saveData()
    }
    
    public func rejectPreparedTransaction(prepared: PreparedTransaction) {
        guard let index = preparedTransactions.firstIndex(where: { $0.id == prepared.id }) else { return }
        preparedTransactions[index].status = .rejected
        preparedTransactions.remove(at: index)
        
        Task {
            await BackendSyncService.shared.rejectPreparedTransaction(id: prepared.id)
        }
        
        saveData()
    }
    
    public func approveAllPreparedTransactions() {
        let pending = preparedTransactions.filter { $0.status == .pendingReview }
        for item in pending {
            approvePreparedTransaction(prepared: item)
        }
        
        Task {
            await BackendSyncService.shared.approveAllPrepared()
        }
    }
    
    // MARK: - Transaction Operations
    public func addTransaction(_ txn: Transaction) {
        transactions.insert(txn, at: 0)
        
        // Auto update linked Account or Credit Card balance
        if let accountId = txn.accountId, let index = accounts.firstIndex(where: { $0.id == accountId }) {
            if txn.type == .expense {
                accounts[index].balance -= txn.amount
            } else if txn.type == .income {
                accounts[index].balance += txn.amount
            }
            accounts[index].updatedAt = Date()
        } else if let cardId = txn.creditCardId, let index = creditCards.firstIndex(where: { $0.id == cardId }) {
            if txn.type == .expense {
                creditCards[index].currentBalance += txn.amount
            } else if txn.type == .income {
                creditCards[index].currentBalance = max(0, creditCards[index].currentBalance - txn.amount)
            }
        }
        
        saveData()
        refreshRuleBasedInsights()
    }
    
    public func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
        saveData()
    }
    
    // MARK: - Bill Operations
    public func addBill(_ bill: Bill) {
        bills.append(bill)
        saveData()
        refreshRuleBasedInsights()
    }
    
    public func markBillPaid(billId: UUID, fromAccountId: UUID? = nil) {
        guard let index = bills.firstIndex(where: { $0.id == billId }) else { return }
        bills[index].isPaid = true
        bills[index].paidDate = Date()
        
        let bill = bills[index]
        let txn = Transaction(
            title: "Bill Payment: \(bill.title)",
            amount: bill.amount,
            type: .expense,
            category: .bills,
            date: Date(),
            notes: "Paid via SmartLedger",
            accountId: fromAccountId ?? bill.linkedAccountId,
            source: .recurringBill,
            merchant: bill.title
        )
        addTransaction(txn)
        saveData()
    }
    
    // MARK: - Accounts & Cards Operations
    public func addAccount(_ account: Account) {
        accounts.append(account)
        saveData()
    }
    
    public func addCreditCard(_ card: CreditCard) {
        creditCards.append(card)
        saveData()
        refreshRuleBasedInsights()
    }
    
    public func addInvestment(_ investment: Investment) {
        investments.append(investment)
        saveData()
        refreshRuleBasedInsights()
    }
    
    // MARK: - AI Insights Refresh
    public func refreshRuleBasedInsights() {
        Task {
            do {
                let fresh = try await GeminiAPIService.shared.generateInsights(
                    transactions: self.transactions,
                    accounts: self.accounts,
                    cards: self.creditCards,
                    investments: self.investments,
                    bills: self.bills
                )
                await MainActor.run {
                    self.insights = fresh
                }
            } catch {
                print("Failed to generate insights: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Data Persistence
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveData() {
        let dir = getDocumentsDirectory()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let accData = try encoder.encode(accounts)
            try accData.write(to: dir.appendingPathComponent(accountsFile))
            
            let cardData = try encoder.encode(creditCards)
            try cardData.write(to: dir.appendingPathComponent(cardsFile))
            
            let txnData = try encoder.encode(transactions)
            try txnData.write(to: dir.appendingPathComponent(txnsFile))
            
            let billData = try encoder.encode(bills)
            try billData.write(to: dir.appendingPathComponent(billsFile))
            
            let invData = try encoder.encode(investments)
            try invData.write(to: dir.appendingPathComponent(investmentsFile))
            
            let prepData = try encoder.encode(preparedTransactions)
            try prepData.write(to: dir.appendingPathComponent(preparedFile))
        } catch {
            print("Error persisting DataStore: \(error)")
        }
    }
    
    private func loadData() {
        let dir = getDocumentsDirectory()
        let decoder = JSONDecoder()
        
        if let data = try? Data(contentsOf: dir.appendingPathComponent(accountsFile)),
           let decoded = try? decoder.decode([Account].self, from: data) {
            self.accounts = decoded
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent(cardsFile)),
           let decoded = try? decoder.decode([CreditCard].self, from: data) {
            self.creditCards = decoded
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent(txnsFile)),
           let decoded = try? decoder.decode([Transaction].self, from: data) {
            self.transactions = decoded
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent(billsFile)),
           let decoded = try? decoder.decode([Bill].self, from: data) {
            self.bills = decoded
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent(investmentsFile)),
           let decoded = try? decoder.decode([Investment].self, from: data) {
            self.investments = decoded
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent(preparedFile)),
           let decoded = try? decoder.decode([PreparedTransaction].self, from: data) {
            self.preparedTransactions = decoded
        }
    }
    
    // MARK: - Pre-populated Mock Data
    public func loadMockPreparedTransactions() {
        self.preparedTransactions = BackendSyncService.shared.generateOfflineSimulatedPrepared()
        saveData()
    }
    
    public func loadMockData() {
        let checking = Account(
            name: "Chase Premier Checking",
            type: .checking,
            balance: 6840.50,
            accountNumberLast4: "4920",
            institutionName: "JPMorgan Chase",
            icon: "building.columns.fill",
            colorHex: "#0D47A1"
        )
        let savings = Account(
            name: "Apple High-Yield Savings",
            type: .savings,
            balance: 18450.25,
            accountNumberLast4: "8841",
            institutionName: "Goldman Sachs / Apple",
            icon: "banknote.fill",
            colorHex: "#FF9800"
        )
        let cash = Account(
            name: "Cash Wallet",
            type: .cash,
            balance: 340.00,
            accountNumberLast4: "N/A",
            institutionName: "Physical Wallet",
            icon: "dollarsign.circle.fill",
            colorHex: "#4CAF50"
        )
        self.accounts = [checking, savings, cash]
        
        let amex = CreditCard(
            cardName: "Amex Gold Card",
            last4Digits: "1008",
            creditLimit: 15000.0,
            currentBalance: 1420.75,
            statementClosingDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!,
            paymentDueDate: Calendar.current.date(byAdding: .day, value: 22, to: Date())!,
            minimumDue: 45.0,
            apr: 22.49,
            cardNetwork: .amex,
            colorGradientHex: ["#D4AF37", "#8C7853"],
            isAutoPayEnabled: true
        )
        let chaseSapphire = CreditCard(
            cardName: "Sapphire Reserve",
            last4Digits: "9314",
            creditLimit: 20000.0,
            currentBalance: 4890.10,
            statementClosingDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            paymentDueDate: Calendar.current.date(byAdding: .day, value: 16, to: Date())!,
            minimumDue: 95.0,
            apr: 24.99,
            cardNetwork: .visa,
            colorGradientHex: ["#0B2545", "#134074"],
            isAutoPayEnabled: false
        )
        let appleCard = CreditCard(
            cardName: "Apple Titanium Card",
            last4Digits: "3029",
            creditLimit: 8500.0,
            currentBalance: 320.00,
            statementClosingDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!,
            paymentDueDate: Calendar.current.date(byAdding: .day, value: 28, to: Date())!,
            minimumDue: 25.0,
            apr: 19.99,
            cardNetwork: .mastercard,
            colorGradientHex: ["#E0E0E0", "#9E9E9E"],
            isAutoPayEnabled: true
        )
        self.creditCards = [amex, chaseSapphire, appleCard]
        
        self.investments = [
            Investment(
                name: "Vanguard S&P 500 ETF",
                symbol: "VOO",
                assetClass: .etf,
                quantity: 45.0,
                averageCost: 440.00,
                currentPrice: 535.20,
                institution: "Vanguard Brokerage"
            ),
            Investment(
                name: "Apple Inc.",
                symbol: "AAPL",
                assetClass: .stocks,
                quantity: 60.0,
                averageCost: 175.50,
                currentPrice: 228.40,
                institution: "Robinhood"
            ),
            Investment(
                name: "Bitcoin",
                symbol: "BTC",
                assetClass: .crypto,
                quantity: 0.35,
                averageCost: 61000.00,
                currentPrice: 91500.00,
                institution: "Coinbase Prime"
            ),
            Investment(
                name: "Treasury 10Y Bond Note",
                symbol: "US10Y",
                assetClass: .fixedIncome,
                quantity: 10.0,
                averageCost: 1000.00,
                currentPrice: 1030.00,
                institution: "TreasuryDirect"
            )
        ]
        
        self.bills = [
            Bill(
                title: "Apartment Rent & HOA",
                amount: 2150.00,
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                category: .rent,
                frequency: .monthly,
                isPaid: false,
                isAutoPay: true,
                linkedAccountId: checking.id
            ),
            Bill(
                title: "Pacific Gas & Electric (PG&E)",
                amount: 142.30,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                category: .utility,
                frequency: .monthly,
                isPaid: false,
                isAutoPay: false,
                linkedCreditCardId: chaseSapphire.id
            ),
            Bill(
                title: "Gigabit Fiber Internet",
                amount: 79.99,
                dueDate: Calendar.current.date(byAdding: .day, value: 11, to: Date())!,
                category: .internet,
                frequency: .monthly,
                isPaid: false,
                isAutoPay: true,
                linkedCreditCardId: amex.id
            ),
            Bill(
                title: "Netflix 4K Ultra Plan",
                amount: 22.99,
                dueDate: Calendar.current.date(byAdding: .day, value: 18, to: Date())!,
                category: .subscription,
                frequency: .monthly,
                isPaid: true,
                paidDate: Date(),
                isAutoPay: true,
                linkedCreditCardId: appleCard.id
            )
        ]
        
        let now = Date()
        self.transactions = [
            Transaction(
                title: "Whole Foods Market",
                amount: 124.60,
                type: .expense,
                category: .groceries,
                date: now,
                notes: "Scanned paper receipt with Gemini AI",
                creditCardId: amex.id,
                source: .receiptScan,
                lineItems: [
                    ReceiptLineItem(name: "Organic Honeycrisp Apples", quantity: 3, unitPrice: 2.99, totalPrice: 8.97, category: "Groceries"),
                    ReceiptLineItem(name: "Almond Milk Unsweetened", quantity: 2, unitPrice: 3.49, totalPrice: 6.98, category: "Groceries"),
                    ReceiptLineItem(name: "Grass-Fed Ribeye Steak", quantity: 2, unitPrice: 22.50, totalPrice: 45.00, category: "Meat")
                ],
                merchant: "Whole Foods Market",
                isVerified: true
            ),
            Transaction(
                title: "Monthly Engineering Salary",
                amount: 6250.00,
                type: .income,
                category: .income,
                date: Calendar.current.date(byAdding: .day, value: -2, to: now)!,
                notes: "Direct Deposit ACH - Tech Corp",
                accountId: checking.id,
                source: .emailInvoice,
                merchant: "Acme Tech Inc",
                isVerified: true
            ),
            Transaction(
                title: "Blue Bottle Coffee",
                amount: 6.75,
                type: .expense,
                category: .dining,
                date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
                notes: "Captured from bank SMS alert",
                creditCardId: appleCard.id,
                source: .smsAlert,
                merchant: "Blue Bottle Coffee",
                isVerified: true
            )
        ]
        
        saveData()
    }
}
