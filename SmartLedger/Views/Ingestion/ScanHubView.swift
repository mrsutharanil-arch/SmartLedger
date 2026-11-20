import SwiftUI
import PhotosUI

public struct ScanHubView: View {
    @EnvironmentObject var store: DataStore
    @StateObject private var viewModel = IngestionViewModel()
    
    @State private var showingCameraScanner = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showingSMSPasteSheet = false
    @State private var showingEmailPasteSheet = false
    @State private var showingPreparedInbox = false
    @State private var clipboardText: String? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Description
                    VStack(spacing: 6) {
                        Text("Multi-Source Ingestion Engine")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Scan paper receipts, paste bank SMS alerts, or let the backend auto-scan incoming emails and notifications via Gemini AI.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 4)
                    
                    // MARK: - Auto-Scan Prepared Transactions Inbox Banner
                    Button(action: { showingPreparedInbox = true }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "#FF6F00"))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "bolt.badge.automatic.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text("Auto-Scan Inbox")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if store.pendingPreparedCount > 0 {
                                        Text("\(store.pendingPreparedCount) Prepared")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(hex: "#FF6F00"))
                                            .cornerRadius(10)
                                    } else {
                                        Text("Up to date")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text("Automated background transactions prepared by backend webhooks & SMS forwarders.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "#FF6F00").opacity(0.3), lineWidth: 1.5)
                        )
                    }
                    
                    // MARK: - Auto-Detected Clipboard Notification
                    if let clip = clipboardText {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.on.clipboard.fill")
                                    .foregroundColor(.blue)
                                Text("Bank Transaction Alert Detected in Clipboard")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Spacer()
                                Button("Dismiss") {
                                    withAnimation { clipboardText = nil }
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            }
                            
                            Text(clip)
                                .font(.caption)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                viewModel.processTextContent(clip, source: .smsAlert)
                                clipboardText = nil
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Auto-Parse with Gemini AI")
                                }
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                        }
                        .padding(14)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // MARK: - Direct Ingestion Channels Grid
                    VStack(spacing: 12) {
                        // Channel 1: Camera Scanner
                        IngestionChannelCard(
                            title: "Camera Document Scanner",
                            subtitle: "Point camera at receipts, restaurant checks, or printed bills",
                            icon: "camera.viewfinder",
                            badge: "VisionKit + Gemini",
                            gradientColors: [Color(hex: "#1E88E5"), Color(hex: "#1565C0")]
                        ) {
                            showingCameraScanner = true
                        }
                        
                        // Channel 2: Photo Library Picker
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            IngestionChannelCard(
                                title: "Upload Receipt Photo",
                                subtitle: "Select existing screenshots or receipts from your Photos",
                                icon: "photo.on.rectangle.angled",
                                badge: "Photo Library",
                                gradientColors: [Color(hex: "#7E57C2"), Color(hex: "#5E35B1")]
                            ) {}
                        }
                        .buttonStyle(.plain)
                        
                        // Channel 3: SMS Bank Alert Paste
                        IngestionChannelCard(
                            title: "Bank SMS & Push Alerts",
                            subtitle: "Parse debit/credit SMS alerts from Chase, Amex, Apple Pay, etc.",
                            icon: "message.badge.filled.fill",
                            badge: "Instant Regex + AI",
                            gradientColors: [Color(hex: "#00897B"), Color(hex: "#004D40")]
                        ) {
                            showingSMSPasteSheet = true
                        }
                        
                        // Channel 4: Email & PDF Invoice
                        IngestionChannelCard(
                            title: "Email & PDF Invoices",
                            subtitle: "Paste text or e-receipts forwarded from Amazon, Uber, or utilities",
                            icon: "envelope.badge.shield.half.filled.fill",
                            badge: "Email Parser",
                            gradientColors: [Color(hex: "#E65100"), Color(hex: "#BF360C")]
                        ) {
                            showingEmailPasteSheet = true
                        }
                    }
                    
                    // MARK: - AI Processing Status Indicator
                    if viewModel.isAnalyzing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Gemini AI is analyzing document & extracting line items...")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    
                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Ingest & Scan")
            .onAppear {
                clipboardText = viewModel.checkClipboardForAlert()
            }
            .sheet(isPresented: $showingPreparedInbox) {
                PreparedTransactionsInboxView()
            }
            .sheet(isPresented: $showingCameraScanner) {
                #if canImport(VisionKit)
                DocumentScannerView(isPresented: $showingCameraScanner) { scannedImage in
                    viewModel.processScannedImage(scannedImage)
                }
                #else
                Text("VisionKit camera scanner is only available on physical iOS devices.")
                #endif
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.processScannedImage(image)
                    }
                }
            }
            .sheet(isPresented: $showingSMSPasteSheet) {
                TextIngestionSheet(
                    title: "Paste Bank SMS Alert",
                    placeholder: "e.g., 'Alert: Card ending in 1008 spent $45.20 at Trader Joe's on 11/20/2026. Available limit $13,579.'",
                    source: .smsAlert,
                    onProcess: { text in
                        viewModel.processTextContent(text, source: .smsAlert)
                    }
                )
            }
            .sheet(isPresented: $showingEmailPasteSheet) {
                TextIngestionSheet(
                    title: "Paste Email or Invoice Text",
                    placeholder: "Paste forwarded confirmation email, invoice body, or e-ticket details...",
                    source: .emailInvoice,
                    onProcess: { text in
                        viewModel.processTextContent(text, source: .emailInvoice)
                    }
                )
            }
            .sheet(isPresented: $viewModel.showReviewSheet) {
                if let receipt = viewModel.parsedReceipt {
                    ParsedReceiptReviewView(viewModel: viewModel, parsedReceipt: receipt)
                }
            }
        }
    }
}

// MARK: - Ingestion Channel Card Component
struct IngestionChannelCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let badge: String
    let gradientColors: [Color]
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(gradientColors.first)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(gradientColors.first?.opacity(0.12))
                            .cornerRadius(4)
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
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
}

// MARK: - Text Ingestion Sheet (SMS / Email)
struct TextIngestionSheet: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let placeholder: String
    let source: TransactionSource
    var onProcess: (String) -> Void
    
    @State private var text: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $text)
                    .padding(12)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            if text.isEmpty {
                                HStack {
                                    Text(placeholder)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 20)
                                        .padding(.leading, 18)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    )
                
                Button(action: {
                    if let clip = UIPasteboard.general.string {
                        text = clip
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste from Clipboard")
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(16)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Parse with Gemini") {
                        onProcess(text)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
