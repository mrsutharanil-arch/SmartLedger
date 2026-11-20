import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)
            
            ScanHubView()
                .tabItem {
                    Label("Scan & Ingest", systemImage: "camera.viewfinder")
                }
                .tag(1)
            
            AccountsView()
                .tabItem {
                    Label("Accounts & Cards", systemImage: "creditcard.fill")
                }
                .tag(2)
            
            BillsAndInvestmentsHubView()
                .tabItem {
                    Label("Bills & Wealth", systemImage: "banknote.fill")
                }
                .tag(3)
            
            AIAdvisorView()
                .tabItem {
                    Label("Gemini AI", systemImage: "sparkles")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// Combined Hub for Bills & Investments with top tabs
struct BillsAndInvestmentsHubView: View {
    @State private var activeSection: Section = .bills
    
    enum Section: String, CaseIterable, Identifiable {
        case bills = "Bills & Subscriptions"
        case investments = "Investments & Net Worth"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $activeSection) {
                    ForEach(Section.allCases) { sec in
                        Text(sec.rawValue).tag(sec)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                
                if activeSection == .bills {
                    BillsTrackerView()
                } else {
                    InvestmentsView()
                }
            }
        }
    }
}
