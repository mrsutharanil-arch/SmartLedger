import Foundation
import SwiftUI
import Combine

public struct ChatMessage: Identifiable, Codable, Hashable {
    public let id: UUID
    public let sender: MessageSender
    public let text: String
    public let timestamp: Date
    
    public enum MessageSender: String, Codable {
        case user
        case geminiAdvisor
    }
    
    public init(id: UUID = UUID(), sender: MessageSender, text: String, timestamp: Date = Date()) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
    }
}

@MainActor
public class AIAdvisorViewModel: ObservableObject {
    @Published public var messages: [ChatMessage] = []
    @Published public var inputText: String = ""
    @Published public var isGenerating: Bool = false
    @Published public var quickPrompts: [String] = [
        "Analyze my monthly spending and tell me where to cut costs.",
        "Can I afford a $400 purchase without hurting my savings?",
        "Audit my credit cards and check for interest traps.",
        "How much net worth increase do I need for retirement goals?",
        "What are my highest recurring bills this month?"
    ]
    
    public init() {
        // Welcome message
        messages.append(
            ChatMessage(
                sender: .geminiAdvisor,
                text: "Hello! I am your personal Gemini AI Financial Strategist. I have live awareness of your bank accounts, credit card balances, upcoming bills, and investments. How can I assist your wealth building today?"
            )
        )
    }
    
    public func sendMessage(store: DataStore) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMsg = ChatMessage(sender: .user, text: trimmed)
        messages.append(userMsg)
        inputText = ""
        isGenerating = true
        
        // Build live context string from DataStore
        let context = """
        Total Net Worth: \(store.netWorth.formattedCurrency())
        Total Bank Balance: \(store.totalCashBalance.formattedCurrency())
        Total Credit Debt: \(store.totalCreditDebt.formattedCurrency())
        Total Investments: \(store.totalInvestmentsValue.formattedCurrency())
        Monthly Income: \(store.currentMonthIncome.formattedCurrency())
        Monthly Expenses: \(store.currentMonthExpenses.formattedCurrency())
        Net Cash Flow: \(store.currentMonthCashFlow.formattedCurrency())
        
        Cards: \(store.creditCards.map { "\($0.cardName): Balance \($0.currentBalance.formattedCurrency()) / Limit \($0.creditLimit.formattedCurrency()), Util \($0.utilizationPercentage)%" }.joined(separator: ", "))
        
        Pending Bills: \(store.bills.filter { !$0.isPaid }.map { "\($0.title) (\($0.amount.formattedCurrency())) due in \($0.daysRemaining) days" }.joined(separator: ", "))
        
        Top Recent Expenses: \(store.transactions.filter { $0.type == .expense }.prefix(6).map { "\($0.title): \($0.amount.formattedCurrency())" }.joined(separator: ", "))
        """
        
        Task {
            do {
                let reply = try await GeminiAPIService.shared.chatWithAdvisor(message: trimmed, context: context)
                await MainActor.run {
                    self.messages.append(ChatMessage(sender: .geminiAdvisor, text: reply))
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.messages.append(ChatMessage(sender: .geminiAdvisor, text: "Error: \(error.localizedDescription)"))
                    self.isGenerating = false
                }
            }
        }
    }
    
    public func sendQuickPrompt(_ prompt: String, store: DataStore) {
        inputText = prompt
        sendMessage(store: store)
    }
}
