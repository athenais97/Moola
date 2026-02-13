import SwiftUI

/// Step 2: Secure Bridge Interstitial
/// The "Handoff" screen shown before launching the bank's OAuth
/// UX Intent: Eliminate user anxiety by clearly explaining the transition
/// to a secure, bank-owned environment. This is the "professional handshake."
/// 
/// UX JUSTIFICATION: External Browser Handoff vs. Embedded iFrame
/// - Security: SFSafariViewController shows the legitimate bank URL, allowing
///   users to verify they're on the real bank website (prevents phishing)
/// - Trust: Users see familiar browser chrome and can inspect the SSL certificate
/// - Compliance: Banks prefer OAuth over credential collection in-app
/// - Native feel: iOS handles cookies and sessions securely
struct SecureBridgeInterstitialView: View {
    @ObservedObject var viewModel: BankLinkingViewModel
    
    @State private var showSecurityAnimation: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Main content
            VStack(spacing: 32) {
                // Animated security illustration
                securityIllustration
                
                // Explanation content
                explanationContent
                
                // Security assurances
                securityAssurances
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Bottom section with CTA
            bottomSection
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                showSecurityAnimation = true
            }
            startPulseAnimation()
        }
    }
    
    // MARK: - Security Illustration
    
    private var securityIllustration: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 2)
                .frame(width: 140, height: 140)
                .scaleEffect(pulseScale)
                .opacity(showSecurityAnimation ? 1 : 0)
            
            // Middle ring
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                .frame(width: 110, height: 110)
                .opacity(showSecurityAnimation ? 1 : 0)
            
            // Inner filled circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.15), Color.green.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)
            
            // Lock icon with bank name
            VStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
                    .scaleEffect(showSecurityAnimation ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSecurityAnimation)
            }
        }
    }
    
    // MARK: - Explanation Content
    
    private var explanationContent: some View {
        VStack(spacing: 16) {
            // Title with bank name
            VStack(spacing: 8) {
                Text("Connecting to")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                Text(viewModel.selectedBank?.name ?? "Your Bank")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Explanation
            Text("You're about to be directed to your bank's secure login page. This ensures your credentials are handled directly by your bank.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Security Assurances
    
    private var securityAssurances: some View {
        VStack(spacing: 14) {
            SecurityAssuranceRow(
                icon: "eye.slash.fill",
                iconColor: .blue,
                text: "We never see your bank password"
            )
            
            SecurityAssuranceRow(
                icon: "lock.fill",
                iconColor: .green,
                text: "Only read-access to account data"
            )
            
            SecurityAssuranceRow(
                icon: "checkmark.shield.fill",
                iconColor: .purple,
                text: "256-bit encrypted connection"
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 16) {
            // Browser preview hint
            HStack(spacing: 8) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("Opens in secure browser")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Continue button
            PrimaryButton(
                title: "Continue to \(viewModel.selectedBank?.name ?? "Bank")",
                isEnabled: true,
                isLoading: viewModel.connectionState == .connecting
            ) {
                viewModel.initiateSecureConnection()
            }
            
            // Demo mode button - simulates successful connection
            #if DEBUG
            Button(action: {
                simulateDemoConnection()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 14))
                    Text("Demo: Simulate Successful Connection")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.orange)
                .padding(.vertical, 8)
            }
            #endif
            
            // Error state
            if let error = viewModel.error {
                errorView(error)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }
    
    // MARK: - Demo Mode
    
    private func simulateDemoConnection() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Simulate the OAuth callback success
        viewModel.simulateSuccessfulConnection()
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: BankConnectionError) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: error.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                
                Text(error.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text(error.message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.retryConnection()
            }) {
                Text("Try Again")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - Animations
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Security Assurance Row

/// Individual row for security assurance list
struct SecurityAssuranceRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            // Text
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Secure Bridge") {
    let viewModel = BankLinkingViewModel()
    viewModel.selectBank(Bank.sampleBanks[0])
    return SecureBridgeInterstitialView(viewModel: viewModel)
}

#Preview("With Error") {
    let viewModel = BankLinkingViewModel()
    viewModel.selectBank(Bank.sampleBanks[0])
    return SecureBridgeInterstitialView(viewModel: viewModel)
}
