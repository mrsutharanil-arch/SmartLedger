import SwiftUI

public struct CompanyBrandingHeaderView: View {
    public let profile: CompanyProfile
    
    public init(profile: CompanyProfile) {
        self.profile = profile
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Company Logo Graphic
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#0B192C"), Color(hex: "#1E3E62"), Color(hex: "#0077B6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#00B4D8"), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                
                // Vector glyph representing growth ledger & AI
                HStack(alignment: .bottom, spacing: 3) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#00B4D8"))
                        .frame(width: 4, height: 12)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#48CAE4"))
                        .frame(width: 4, height: 18)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#90E0EF"))
                        .frame(width: 4, height: 24)
                }
                
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#FFD700"))
                    .offset(x: 12, y: -12)
            }
            
            // Company Information Text
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.companyName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Text(profile.businessType)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(profile.taxNumber)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
                    Text(profile.city)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
