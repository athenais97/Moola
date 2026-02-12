import SwiftUI

/// Auth Entry View - Routes users to appropriate authentication flow
///
/// UX Intent:
/// - Returning users: Show PIN login screen for quick re-entry
/// - New users: Landing screen -> onboarding flow for account creation
/// - Seamless transitions between flows
struct AuthEntryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showForgotPIN = false
    @State private var showReplaceAccountAlert = false
    
    var body: some View {
        Group {
            switch appState.authFlow {
            case .landing:
                AuthLandingView(
                    onRequestReplaceAccount: {
                        showReplaceAccountAlert = true
                    }
                )
                .environmentObject(appState)
                
            case .login:
                LoginView(
                    authService: appState.authService,
                    onForgotPIN: {
                        showForgotPIN = true
                    }
                )
                .environmentObject(appState)
                
            case .onboarding:
                OnboardingContainerView()
                    .environmentObject(appState)
            }
        }
        .onAppear {
            // Safety: don't show login if there's no stored user.
            if !appState.authService.hasStoredUser, appState.authFlow == .login {
                appState.showAuthLanding()
            }
        }
        .sheet(isPresented: $showForgotPIN) {
            ForgotPINView(
                authService: appState.authService,
                onComplete: {
                    showForgotPIN = false
                }
            )
        }
        .alert("Create a new account?", isPresented: $showReplaceAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Create", role: .destructive) {
                appState.resetAccountAndStartOnboarding()
            }
        } message: {
            Text("This will remove the saved account from this device and start the sign up flow again.")
        }
    }
}

#Preview {
    AuthEntryView()
        .environmentObject(AppState())
}