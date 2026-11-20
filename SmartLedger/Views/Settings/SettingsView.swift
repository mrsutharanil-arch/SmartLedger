import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @State private var apiKey: String = ""
    @State private var backendURL: String = ""
    @State private var isTestingKey: Bool = false
    @State private var testResult: String? = nil
    @State private var isFaceIDEnabled: Bool = false
    @State private var companyProfile: CompanyProfile = CompanyProfileView.loadSavedProfile()
    
    let currencies = ["USD", "EUR", "GBP", "INR", "JPY", "CAD", "AUD"]
    
    public init() {}
    
    public var body: some View {
        Form {
            // MARK: - Section 1: Company Profile & Branding
            Section("Company Profile & Branding") {
                NavigationLink(destination: CompanyProfileView()) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#0B192C"), Color(hex: "#1E3E62"), Color(hex: "#0077B6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.title3)
                                .foregroundColor(Color(hex: "#00B4D8"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(companyProfile.companyName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            Text(companyProfile.taxNumber)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // MARK: - Section 2: Auto-Scan Backend Server
            Section(header: Text("Auto-Scan Backend Service"), footer: Text("The backend automatically scans forwarded receipt emails, inbound SMS banking alerts, and background photo uploads, preparing them for 1-tap ledger approval.")) {
                TextField("Server URL (e.g. http://192.168.1.50:8000)", text: $backendURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button(action: {
                    UserDefaults.standard.set(backendURL, forKey: "backend_server_url")
                    store.syncPreparedFromBackend()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Save & Sync Backend Now")
                    }
                }
            }
            
            // MARK: - Section 3: Google Gemini AI Configuration
            Section(header: Text("Google Gemini AI Engine"), footer: Text("SmartLedger connects directly to Gemini 2.5 Flash for high-speed multimodal receipt scanning, SMS alert parsing, and financial reasoning. Your key is stored locally in device storage.")) {
                SecureField("Gemini API Key (AIzaSy...)", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button(action: saveAndTestKey) {
                    HStack {
                        if isTestingKey {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Testing Gemini Connection...")
                        } else {
                            Image(systemName: "bolt.badge.checkmark.fill")
                            Text("Save & Test Connection")
                        }
                    }
                }
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTestingKey)
                
                if let res = testResult {
                    HStack {
                        Image(systemName: res.contains("Success") ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(res.contains("Success") ? .green : .red)
                        Text(res)
                            .font(.caption)
                            .foregroundColor(res.contains("Success") ? .green : .red)
                    }
                }
            }
            
            // MARK: - Section 4: Preferences & Currency
            Section("Preferences") {
                Picker("Primary Currency", selection: $store.selectedCurrency) {
                    ForEach(currencies, id: \.self) { curr in
                        Text(curr).tag(curr)
                    }
                }
                
                Toggle("Face ID / Biometric Lock", isOn: $isFaceIDEnabled)
                    .onChange(of: isFaceIDEnabled) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "biometrics_enabled")
                    }
            }
            
            // MARK: - Section 5: Data Management
            Section("Data Management") {
                Button(action: {
                    store.loadMockData()
                    store.loadMockPreparedTransactions()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle")
                        Text("Reset Demo Mock Data & Prepared Inbox")
                    }
                }
                
                Button(role: .destructive, action: {
                    store.accounts.removeAll()
                    store.creditCards.removeAll()
                    store.transactions.removeAll()
                    store.bills.removeAll()
                    store.investments.removeAll()
                    store.insights.removeAll()
                    store.preparedTransactions.removeAll()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Local Ledger Data")
                    }
                }
            }
            
            // MARK: - Section 6: Privacy & Security
            Section("Security & Privacy") {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("100% Local-First Storage")
                            .font(.footnote)
                            .fontWeight(.bold)
                        Text("All transactions, balances, cards, and investments are persisted locally on this iPhone. No third-party data tracking.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - Section 7: Company & Application About
            Section("About & Organization") {
                HStack {
                    Text("Organization")
                    Spacer()
                    Text(companyProfile.companyName)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("mrsutharanil-arch")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Contact Email")
                    Spacer()
                    Text(companyProfile.officialEmail)
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("2.5.0 (Build 42)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("AI Model Target")
                    Spacer()
                    Text("Gemini 2.5 Flash")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings & AI")
        .onAppear {
            apiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
            backendURL = UserDefaults.standard.string(forKey: "backend_server_url") ?? "http://localhost:8000"
            isFaceIDEnabled = UserDefaults.standard.bool(forKey: "biometrics_enabled")
            companyProfile = CompanyProfileView.loadSavedProfile()
        }
    }
    
    private func saveAndTestKey() {
        let cleaned = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(cleaned, forKey: "gemini_api_key")
        isTestingKey = true
        testResult = nil
        
        Task {
            do {
                let testResponse = try await GeminiAPIService.shared.chatWithAdvisor(
                    message: "Ping",
                    context: "Test connection check"
                )
                await MainActor.run {
                    self.isTestingKey = false
                    self.testResult = "Success: Gemini API is verified and active!"
                }
            } catch {
                await MainActor.run {
                    self.isTestingKey = false
                    self.testResult = "Connection failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
