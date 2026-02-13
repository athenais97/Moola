import SwiftUI
import SafariServices

/// Main container for the bank linking stepper flow
/// UX Intent: Immersive 3-step flow with clear progress indication
/// Foundation compliance: One clear intent per screen, thumb-friendly navigation
struct BankLinkingContainerView: View {
    @StateObject private var viewModel: BankLinkingViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// Callback when linking is completed successfully
    let onComplete: ([String]) -> Void
    
    /// Callback when user cancels
    let onCancel: () -> Void
    
    init(
        linkRequest: BankLinkRequest = .newConnection,
        onComplete: @escaping ([String]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: BankLinkingViewModel(linkRequest: linkRequest))
        self.onComplete = onComplete
        self.onCancel = onCancel
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation bar with progress
                navigationBar
                
                // Progress indicator (segmented bar)
                StepProgressView(
                    currentStep: viewModel.currentStep.rawValue,
                    totalSteps: BankLinkingStep.allCases.count
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Step content with transitions
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(viewModel.currentStep)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
        .sheet(isPresented: $viewModel.showSafariController) {
            BankSafariView(
                url: viewModel.safariURL ?? URL(string: "https://example.com")!,
                onDismiss: {
                    viewModel.handleSafariDismissed()
                },
                onCallback: { success in
                    viewModel.handleOAuthCallback(success: success)
                }
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            // Cancel/Close button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                viewModel.cancel()
                onCancel()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Step title
            Text(viewModel.currentStep.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .bankSelection:
            BankSelectionStepView(viewModel: viewModel)
            
        case .secureConnection:
            SecureBridgeInterstitialView(viewModel: viewModel)
            
        case .accountSelection:
            AccountSelectionStepView(
                viewModel: viewModel,
                onComplete: { accountIds in
                    onComplete(Array(accountIds))
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Safari View for OAuth

/// Wraps SFSafariViewController for the secure OAuth flow
/// UX Justification: Using SFSafariViewController instead of embedded WebView
/// because it shows the legitimate bank URL in the address bar, building trust.
/// Users can verify they're on the real bank website, reducing phishing concerns.
struct BankSafariView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void
    let onCallback: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = false
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator
        safari.preferredControlTintColor = .systemBlue
        safari.dismissButtonStyle = .close
        
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: BankSafariView
        
        init(_ parent: BankSafariView) {
            self.parent = parent
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.onDismiss()
        }
        
        func safariViewController(
            _ controller: SFSafariViewController,
            initialLoadDidRedirectTo URL: URL
        ) {
            // Check for success callback URL
            // In production, this would check for your app's custom URL scheme
            if URL.absoluteString.contains("callback=success") ||
               URL.absoluteString.contains("oauth/callback") {
                parent.onCallback(true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BankLinkingContainerView(
        onComplete: { accountIds in
            print("Completed with accounts: \(accountIds)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
