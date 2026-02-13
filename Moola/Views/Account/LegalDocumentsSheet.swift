import SwiftUI
import SafariServices

// MARK: - Safari View

/// SwiftUI wrapper for SFSafariViewController
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

/// Bottom sheet presenting legal document links
/// UX Intent: Quick access to legal info without full navigation
/// Foundation compliance: Bottom sheet for quick actions
struct LegalDocumentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showTermsOfService: Bool = false
    @State private var showCookiePolicy: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Legal documents list
                VStack(spacing: 0) {
                    legalRow(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        action: { showTermsOfService = true }
                    )
                    
                    Divider().padding(.leading, 54)
                    
                    legalRow(
                        icon: "checkmark.seal.fill",
                        title: "Cookie Policy",
                        action: { showCookiePolicy = true }
                    )
                    
                    Divider().padding(.leading, 54)
                    
                    legalRow(
                        icon: "building.2.fill",
                        title: "Company Information"
                    ) {
                        // Navigate to company info
                    }
                    
                    Divider().padding(.leading, 54)
                    
                    legalRow(
                        icon: "shield.lefthalf.filled",
                        title: "Open Source Licenses"
                    ) {
                        // Navigate to licenses
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                // App version
                VStack(spacing: 4) {
                    Text("Version 1.0.0 (Build 1)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("© 2026 Your Company. All rights reserved.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Legal Notice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showTermsOfService) {
            SafariView(url: URL(string: "https://example.com/terms")!)
        }
        .sheet(isPresented: $showCookiePolicy) {
            SafariView(url: URL(string: "https://example.com/cookies")!)
        }
    }
    
    private func legalRow(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 26)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Preview

#Preview("Legal Documents") {
    LegalDocumentsSheet()
}
