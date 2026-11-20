import SwiftUI

public struct AIAdvisorView: View {
    @EnvironmentObject var store: DataStore
    @StateObject private var viewModel = AIAdvisorViewModel()
    @State private var selectedTab: AdvisorMode = .chat
    
    enum AdvisorMode: String, CaseIterable, Identifiable {
        case chat = "AI Chat Assistant"
        case audit = "Financial Audit & Alerts"
        
        var id: String { rawValue }
    }
    
    public init() {}
    
    // Financial Health Score (0-100)
    var healthScore: Int {
        var score = 70
        // Credit utilization bonus/penalty
        let maxUtil = store.creditCards.map { $0.utilizationPercentage }.max() ?? 0.0
        if maxUtil > 50 { score -= 15 }
        else if maxUtil < 20 { score += 10 }
        
        // Savings buffer bonus
        if store.totalCashBalance > 10000 { score += 10 }
        
        // Bills overdue penalty
        let overdueCount = store.bills.filter { $0.isOverdue }.count
        score -= (overdueCount * 10)
        
        return max(20, min(98, score))
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Switcher
                Picker("Advisor Mode", selection: $selectedTab) {
                    ForEach(AdvisorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                
                if selectedTab == .chat {
                    // Chat View
                    VStack(spacing: 0) {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 14) {
                                    ForEach(viewModel.messages) { msg in
                                        ChatBubbleView(message: msg)
                                            .id(msg.id)
                                    }
                                    
                                    if viewModel.isGenerating {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Gemini is thinking...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 16)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            }
                            .onChange(of: viewModel.messages.count) { _ in
                                if let last = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        
                        // Quick prompt suggestions
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.quickPrompts, id: \.self) { prompt in
                                    Button(action: {
                                        viewModel.sendQuickPrompt(prompt, store: store)
                                    }) {
                                        Text(prompt)
                                            .font(.caption2)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(UIColor.secondarySystemGroupedBackground))
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                        
                        // Input Bar
                        HStack(spacing: 10) {
                            TextField("Ask Gemini about your finances...", text: $viewModel.inputText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                            
                            Button(action: {
                                viewModel.sendMessage(store: store)
                            }) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .blue)
                            }
                            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemBackground))
                    }
                } else {
                    // Audit & Insights View
                    ScrollView {
                        VStack(spacing: 20) {
                            // Health Score Gauge Card
                            CardContainerView(padding: 16) {
                                HStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 10)
                                            .frame(width: 80, height: 80)
                                        
                                        Circle()
                                            .trim(from: 0.0, to: CGFloat(healthScore) / 100.0)
                                            .stroke(healthScore >= 75 ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                            .frame(width: 80, height: 80)
                                            .rotationEffect(.degrees(-90))
                                        
                                        VStack(spacing: 0) {
                                            Text("\(healthScore)")
                                                .font(.title2)
                                                .fontWeight(.heavy)
                                            Text("/ 100")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("FINANCIAL HEALTH INDEX")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .tracking(0.6)
                                        
                                        Text(healthScore >= 80 ? "Excellent Standing" : (healthScore >= 60 ? "Good Financial Shape" : "Attention Needed"))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        
                                        Text("Calculated from credit utilization (\(String(format: "%.1f", store.creditCards.map { $0.utilizationPercentage }.max() ?? 0))% max), cash-to-debt ratio, and bill reliability.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // Insights Feed
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("ACTIONABLE GEMINI INSIGHTS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                        .tracking(0.6)
                                    Spacer()
                                    Button(action: {
                                        store.refreshRuleBasedInsights()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Refresh")
                                        }
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                ForEach(store.insights) { insight in
                                    CardContainerView(padding: 14) {
                                        HStack(alignment: .top, spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: insight.type.tintColorHex).opacity(0.18))
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: insight.type.icon)
                                                    .font(.subheadline)
                                                    .foregroundColor(Color(hex: insight.type.tintColorHex))
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text(insight.title)
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                    Spacer()
                                                    Text(insight.type.rawValue)
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundColor(Color(hex: insight.type.tintColorHex))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color(hex: insight.type.tintColorHex).opacity(0.12))
                                                        .cornerRadius(4)
                                                }
                                                
                                                Text(insight.summary)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                if let action = insight.actionLabel {
                                                    HStack {
                                                        Spacer()
                                                        Text(action)
                                                            .font(.caption2)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(.blue)
                                                    }
                                                    .padding(.top, 4)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea(edges: .bottom))
            .navigationTitle("Gemini Advisor")
        }
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.sender == .user {
                Spacer()
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.sender == .user ?
                        Color.blue :
                        Color(UIColor.secondarySystemGroupedBackground)
                    )
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(message.sender == .user ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
                    )
            }
            
            if message.sender == .geminiAdvisor {
                Spacer()
            }
        }
    }
}
