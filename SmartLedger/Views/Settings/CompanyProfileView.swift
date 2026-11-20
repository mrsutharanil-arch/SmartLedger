import SwiftUI

public struct CompanyProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var profile: CompanyProfile
    @State private var showingSaveAlert: Bool = false
    @State private var showingExportPreview: Bool = false
    
    public init() {
        let saved = CompanyProfileView.loadSavedProfile()
        _profile = State(initialValue: saved)
    }
    
    public static func loadSavedProfile() -> CompanyProfile {
        if let data = UserDefaults.standard.data(forKey: "company_profile_data"),
           let decoded = try? JSONDecoder().decode(CompanyProfile.self, from: data) {
            return decoded
        }
        return CompanyProfile()
    }
    
    public var body: some View {
        Form {
            // MARK: - Section 1: Logo & Company Header
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#0B192C"), Color(hex: "#1E3E62"), Color(hex: "#0077B6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 84, height: 84)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#00B4D8"), lineWidth: 3)
                                )
                                .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 4)
                            
                            HStack(alignment: .bottom, spacing: 4) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: "#00B4D8"))
                                    .frame(width: 6, height: 20)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: "#48CAE4"))
                                    .frame(width: 6, height: 32)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: "#90E0EF"))
                                    .frame(width: 6, height: 44)
                            }
                            
                            Image(systemName: "sparkle")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "#FFD700"))
                                .offset(x: 20, y: -20)
                        }
                        Spacer()
                    }
                    .padding(.top, 6)
                    
                    Text(profile.companyName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Official Corporate & Accounting Profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
            
            // MARK: - Section 2: General Business Details
            Section("Business Information") {
                TextField("Company Display Name", text: $profile.companyName)
                TextField("Legal Registered Name", text: $profile.legalName)
                TextField("Business Activity / Industry", text: $profile.businessType)
            }
            
            // MARK: - Section 3: Tax & Registration Credentials
            Section("Tax & Compliance Identifiers") {
                TextField("Tax ID / GSTIN / VAT", text: $profile.taxNumber)
                TextField("Registration / Incorporation No.", text: $profile.registrationNumber)
                TextField("Financial Year Begins (e.g. April 1)", text: $profile.financialYearStart)
            }
            
            // MARK: - Section 4: Contact & Online Presence
            Section("Contact & Support") {
                TextField("Official Email", text: $profile.officialEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Official Phone", text: $profile.phone)
                    .keyboardType(.phonePad)
                TextField("Website / Repository URL", text: $profile.website)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            }
            
            // MARK: - Section 5: Registered Office Address
            Section("Registered Office Address") {
                TextField("Street Address", text: $profile.addressLine)
                TextField("City / State", text: $profile.city)
                TextField("Country", text: $profile.country)
            }
            
            // MARK: - Section 6: Official Statement Export
            Section("Company Financial Statements") {
                Button(action: { showingExportPreview = true }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("Preview Company Ledger Letterhead")
                    }
                }
            }
        }
        .navigationTitle("Company Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProfile()
                    showingSaveAlert = true
                }
                .fontWeight(.bold)
            }
        }
        .alert("Company Profile Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("Your company details and branding have been updated across your ledger and statement exports.")
        }
        .sheet(isPresented: $showingExportPreview) {
            CompanyLetterheadPreviewSheet(profile: profile)
        }
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "company_profile_data")
        }
    }
}

// MARK: - Official Company Letterhead Preview Sheet
struct CompanyLetterheadPreviewSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    let profile: CompanyProfile
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Corporate Letterhead Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(profile.legalName)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(profile.businessType)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(profile.addressLine), \(profile.city), \(profile.country)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("Email: \(profile.officialEmail) | \(profile.website)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("STATEMENT OF ACCOUNTS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(0.6)
                                Text(profile.taxNumber)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                Text(Date().formattedDateString())
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                            .padding(.top, 4)
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Executive Ledger Summary
                    CardContainerView(padding: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("FINANCIAL POSITION OVERVIEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.8)
                            
                            HStack {
                                Text("Total Net Worth:")
                                    .font(.subheadline)
                                Spacer()
                                Text(store.netWorth.formattedCurrency(code: store.selectedCurrency))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Total Bank Balances:")
                                    .font(.subheadline)
                                Spacer()
                                Text(store.totalCashBalance.formattedCurrency(code: store.selectedCurrency))
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Investment Portfolio:")
                                    .font(.subheadline)
                                Spacer()
                                Text(store.totalInvestmentsValue.formattedCurrency(code: store.selectedCurrency))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Outstanding Credit Obligations:")
                                    .font(.subheadline)
                                Spacer()
                                Text(store.totalCreditDebt.formattedCurrency(code: store.selectedCurrency))
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Letterhead Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
