import SwiftUI

/// Landing screen that lets users choose Login vs Create Account.
/// - Returning users are redirected to PIN login on app launch; this still gives an explicit path to sign up again.
struct AuthLandingView: View {
    @EnvironmentObject var appState: AppState
    let onRequestReplaceAccount: () -> Void
    
    private let baseSize = CGSize(width: 390, height: 844)
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let scale = min(size.width / baseSize.width, size.height / baseSize.height)
            
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                // Decorative card images (match Figma positioning/rotation)
                Image("AuthCardLeft")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 358 * scale, height: 225 * scale)
                    .rotationEffect(.degrees(-52))
                    .position(x: -49.1455 * scale, y: 435.316 * scale)
                    .allowsHitTesting(false)
                
                Image("AuthCardRight")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 266.747 * scale, height: 167.492 * scale)
                    .rotationEffect(.degrees(-117))
                    .shadow(color: Color.white.opacity(0.10), radius: 17.73 * scale, x: 0, y: 3 * scale)
                    .position(x: 417.1685 * scale, y: 494.8565 * scale)
                    .allowsHitTesting(false)
                
                // Header block (logo + title + subtitle)
                header(scale: scale)
                    .position(x: size.width / 2, y: 207 * scale)
                
                // CTA buttons + helper text
                actions(scale: scale)
                    .position(x: size.width / 2, y: 708 * scale)
            }
        }
    }
    
    private func header(scale: CGFloat) -> some View {
        VStack(spacing: 17 * scale) {
            Image("AuthLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 78 * scale, height: 78 * scale)
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius * scale,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY * scale
                )
            
            VStack(spacing: 12 * scale) {
                Text("Elevate Your Portfolio.")
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: 24 * scale))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Log in to continue, or create\na new account to get started")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14 * scale))
                    .foregroundColor(DesignSystem.Colors.inkSecondary)
                    .multilineTextAlignment(.center)
                    // Figma line-height 1.25
                    .lineSpacing((14 * 1.25 - 14) * scale)
                    .frame(width: 276 * scale)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // Avoid hard height caps: otherwise text gets clipped on some devices / font fallbacks.
        .frame(width: 258 * scale)
        .allowsHitTesting(false)
    }
    
    private func actions(scale: CGFloat) -> some View {
        VStack(spacing: 12 * scale) {
            VStack(spacing: 8 * scale) {
                PrimaryButton(
                    title: "Log In",
                    isEnabled: appState.authService.hasStoredUser,
                    isLoading: false
                ) {
                    appState.showLogin()
                }
                .frame(width: 360 * scale)
                
                SecondaryButton(title: "Create Account", isEnabled: true) {
                    if appState.authService.hasStoredUser {
                        onRequestReplaceAccount()
                    } else {
                        appState.startOnboarding()
                    }
                }
                .frame(width: 360 * scale)
            }
            
            Text("Want to sign up ? Creating a new account\nwill remove the saved account on this device.")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 14 * scale))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing((14 * 1.25 - 14) * scale)
                .frame(width: 289 * scale)
        }
        .frame(width: 360 * scale)
    }
}

#Preview {
    AuthLandingView(onRequestReplaceAccount: {})
        .environmentObject(AppState())
}
