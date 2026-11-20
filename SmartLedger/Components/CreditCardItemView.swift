import SwiftUI

public struct CreditCardItemView: View {
    public let card: CreditCard
    public var onPayTapped: (() -> Void)? = nil
    
    public init(card: CreditCard, onPayTapped: (() -> Void)? = nil) {
        self.card = card
        self.onPayTapped = onPayTapped
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Front
            VStack(alignment: .leading, spacing: 16) {
                // Top row: Network & Contactless
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: card.cardNetwork.iconSymbol)
                            .font(.title3)
                            .foregroundColor(.white)
                        Text(card.cardName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "wave.3.forward")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // EMV Chip Representation
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color(hex: "#FFD700"), Color(hex: "#FFA000")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                    Spacer()
                    
                    Text("••••  \(card.last4Digits)")
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 4)
                
                // Bottom row: Current Balance vs Limit & Due Date
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CURRENT BALANCE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(0.8)
                        
                        Text(card.currentBalance.formattedCurrency(code: card.currency))
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("DUE IN \(card.daysUntilDue) DAYS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(card.daysUntilDue <= 3 ? Color(hex: "#FF8A80") : .white.opacity(0.8))
                            .tracking(0.6)
                        
                        Text("Min: \(card.minimumDue.formattedCurrency(code: card.currency))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.95))
                    }
                }
                
                // Credit Utilization Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Limit: \(card.creditLimit.formattedCurrency(code: card.currency))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                        Text("\(String(format: "%.1f", card.utilizationPercentage))% used")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(card.utilizationPercentage > 30 ? Color(hex: "#FFAB91") : .white.opacity(0.9))
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(card.utilizationPercentage > 30 ? Color(hex: "#FF5252") : Color(hex: "#69F0AE"))
                                .frame(width: min(geo.size.width, geo.size.width * CGFloat(card.utilizationPercentage / 100.0)), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: card.colorGradientHex.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
        }
    }
}
