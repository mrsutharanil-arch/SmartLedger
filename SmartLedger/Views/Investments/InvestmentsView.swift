import SwiftUI

public struct InvestmentsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAddHoldingSheet = false
    
    public init() {}
    
    var totalInvested: Double {
        store.investments.reduce(0.0) { $0 + $1.totalInvested }
    }
    
    var totalCurrentValue: Double {
        store.investments.reduce(0.0) { $0 + $1.currentValue }
    }
    
    var totalGain: Double {
        totalCurrentValue - totalInvested
    }
    
    var overallReturnPercentage: Double {
        guard totalInvested > 0 else { return 0 }
        return (totalGain / totalInvested) * 100.0
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Portfolio Value Hero Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TOTAL INVESTMENT PORTFOLIO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(0.8)
                        
                        Text(totalCurrentValue.formattedCurrency(code: store.selectedCurrency))
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: totalGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text("\(totalGain >= 0 ? "+" : "")\(totalGain.formattedCurrency(code: store.selectedCurrency)) (\(String(format: "%.1f", overallReturnPercentage))%)")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(totalGain >= 0 ? Color(hex: "#69F0AE") : Color(hex: "#FF8A80"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                            
                            Spacer()
                            
                            Text("Invested: \(totalInvested.formattedCurrency(code: store.selectedCurrency))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#1A237E"), Color(hex: "#283593"), Color(hex: "#3949AB")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                    
                    // MARK: - Asset Class Allocation Bars
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ASSET ALLOCATION")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .tracking(0.6)
                        
                        CardContainerView(padding: 14) {
                            VStack(spacing: 12) {
                                ForEach(AssetClass.allCases) { assetClass in
                                    let classHoldings = store.investments.filter { $0.assetClass == assetClass }
                                    let classValue = classHoldings.reduce(0.0) { $0 + $1.currentValue }
                                    if classValue > 0 {
                                        let pct = totalCurrentValue > 0 ? (classValue / totalCurrentValue) * 100.0 : 0
                                        VStack(spacing: 4) {
                                            HStack {
                                                Image(systemName: assetClass.icon)
                                                    .font(.caption)
                                                    .foregroundColor(Color(hex: assetClass.colorHex))
                                                Text(assetClass.rawValue)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                Spacer()
                                                Text("\(classValue.formattedCurrency(code: store.selectedCurrency)) (\(String(format: "%.1f", pct))%)")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                            }
                                            
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.primary.opacity(0.08))
                                                        .frame(height: 6)
                                                    Capsule()
                                                        .fill(Color(hex: assetClass.colorHex))
                                                        .frame(width: max(6, geo.size.width * CGFloat(pct / 100.0)), height: 6)
                                                }
                                            }
                                            .frame(height: 6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: - Holdings List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("HOLDINGS & POSITIONS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .tracking(0.6)
                            Spacer()
                            Text("\(store.investments.count) Assets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        CardContainerView(padding: 8) {
                            VStack(spacing: 0) {
                                ForEach(store.investments) { inv in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: inv.assetClass.colorHex).opacity(0.15))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: inv.assetClass.icon)
                                                .font(.headline)
                                                .foregroundColor(Color(hex: inv.assetClass.colorHex))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(inv.symbol)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                Text("•")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(inv.name)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Text("\(String(format: "%.2f", inv.quantity)) shares @ \(inv.averageCost.formattedCurrency(code: inv.currency))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(inv.currentValue.formattedCurrency(code: inv.currency))
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            
                                            HStack(spacing: 2) {
                                                Image(systemName: inv.isPositive ? "arrow.up.right" : "arrow.down.right")
                                                    .font(.system(size: 8))
                                                Text("\(inv.isPositive ? "+" : "")\(String(format: "%.1f", inv.returnPercentage))%")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .foregroundColor(inv.isPositive ? .green : .red)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    
                                    if inv.id != store.investments.last?.id {
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
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHoldingSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddHoldingSheet) {
                AddInvestmentSheet()
            }
        }
    }
}

// MARK: - Add Investment Sheet
struct AddInvestmentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    
    @State private var name: String = ""
    @State private var symbol: String = ""
    @State private var assetClass: AssetClass = .stocks
    @State private var quantityString: String = ""
    @State private var costString: String = ""
    @State private var currentPriceString: String = ""
    @State private var institution: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Asset Details") {
                    TextField("Asset Name (e.g. Microsoft)", text: $name)
                    TextField("Ticker / Symbol (e.g. MSFT)", text: $symbol)
                    
                    Picker("Asset Class", selection: $assetClass) {
                        ForEach(AssetClass.allCases) { ac in
                            Text(ac.rawValue).tag(ac)
                        }
                    }
                    
                    TextField("Broker / Institution (e.g. Fidelity)", text: $institution)
                }
                
                Section("Quantities & Pricing") {
                    TextField("Quantity (shares / tokens)", text: $quantityString)
                        .keyboardType(.decimalPad)
                    TextField("Average Purchase Cost ($)", text: $costString)
                        .keyboardType(.decimalPad)
                    TextField("Current Market Price ($)", text: $currentPriceString)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Investment Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let qty = Double(quantityString),
                           let cost = Double(costString),
                           let cur = Double(currentPriceString),
                           !name.isEmpty {
                            let inv = Investment(
                                name: name,
                                symbol: symbol.isEmpty ? name : symbol.uppercased(),
                                assetClass: assetClass,
                                quantity: qty,
                                averageCost: cost,
                                currentPrice: cur,
                                institution: institution.isEmpty ? "Brokerage" : institution
                            )
                            store.addInvestment(inv)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || Double(quantityString) == nil)
                }
            }
        }
    }
}
