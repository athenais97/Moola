import SwiftUI

/// Main login screen for returning users
/// UX Intent: Fast, focused, reassuring PIN entry experience
/// - Single clear action: Enter your 4-digit PIN
/// - Personalized greeting to confirm identity
/// - Non-intrusive "Forgot PIN?" fallback
/// - Smooth micro-interactions for all states
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @EnvironmentObject var appState: AppState
    
    /// Callback for navigating to forgot PIN flow
    var onForgotPIN: () -> Void
    
    init(authService: AuthenticationService, onForgotPIN: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authService: authService))
        self.onForgotPIN = onForgotPIN
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            // Header with personalized greeting
            headerSection
            
            Spacer()
                .frame(height: 48)
            
            // PIN dots and status
            pinStatusSection
            
            Spacer()
            
            // Custom numeric keypad
            NumericKeypad(
                onDigitTap: { digit in
                    viewModel.appendDigit(digit)
                },
                onDelete: {
                    viewModel.deleteDigit()
                }
            )
            .opacity(viewModel.isInputDisabled ? 0.5 : 1.0)
            .allowsHitTesting(!viewModel.isInputDisabled)
            
            Spacer()
                .frame(height: 24)
            
            // Forgot PIN link
            forgotPINSection
            
            Spacer()
                .frame(height: 16)
            
            // Switch account link - allows returning to auth entry
            switchAccountSection
            
            Spacer()
                .frame(height: 32)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showError)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isInputDisabled)
        .onChange(of: viewModel.loginResult) { _, newValue in
            if newValue == .success {
                handleSuccessfulLogin()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // App icon or avatar placeholder (future: user avatar)
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            // Personalized greeting
            if let name = viewModel.userName {
                Text("Welcome back, \(name)")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
            } else {
                Text("Welcome back")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            
            Text("Enter your PIN to continue")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - PIN Status Section
    
    private var pinStatusSection: some View {
        VStack(spacing: 16) {
            // PIN dots
            PINDotsView(
                filledCount: viewModel.currentPINLength,
                hasError: viewModel.showError
            )
            
            // Status message area (error or lockout countdown)
            statusMessageView
                .frame(height: 50)
        }
    }
    
    @ViewBuilder
    private var statusMessageView: some View {
        switch viewModel.loginResult {
        case .locked(let seconds):
            lockoutMessageView(seconds: seconds)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
        case .failure(let message):
            errorMessageView(message: message)
                .transition(.opacity.combined(with: .move(edge: .top)))
            
        case .validating:
            ProgressView()
                .scaleEffect(0.9)
                .transition(.opacity)
            
        default:
            // Show remaining attempts if less than max
            if viewModel.remainingAttempts < 3 && viewModel.remainingAttempts > 0 {
                Text("\(viewModel.remainingAttempts) attempt\(viewModel.remainingAttempts == 1 ? "" : "s") remaining")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            } else {
                Color.clear
            }
        }
    }
    
    private func errorMessageView(message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }
    
    private func lockoutMessageView(seconds: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            Text(formatLockoutTime(seconds))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }
    
    // MARK: - Forgot PIN Section
    
    private var forgotPINSection: some View {
        Button(action: onForgotPIN) {
            Text("Forgot PIN?")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .opacity(viewModel.loginResult == .locked(secondsRemaining: viewModel.lockoutCountdown) ? 0.5 : 1.0)
    }
    
    // MARK: - Switch Account Section
    
    /// Allows user to return to auth entry to switch accounts or create a new one
    /// UX: Subtle, non-intrusive placement to avoid confusion
    private var switchAccountSection: some View {
        Button(action: {
            appState.returnToAuthEntry()
        }) {
            if let name = viewModel.userName {
                Text("Not \(name)?")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                Text("Use a different account")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    private func formatLockoutTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "Try again in %d:%02d", minutes, secs)
        }
        return "Try again in \(seconds)s"
    }
    
    private func handleSuccessfulLogin() {
        // Brief delay to show success state, then transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Get the authenticated user and properly transition the flow
            if let user = appState.authService.getAuthenticatedUser() {
                appState.loginSuccessful(user: user)
            }
        }
    }
}

// MARK: - Preview

#Preview("Default") {
    let authService = AuthenticationService()
    // Store a mock user for preview
    authService.storeUser(UserModel(
        name: "Sarah",
        age: 28,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: PINService().hashPIN("1234")
    ))
    
    return LoginView(authService: authService, onForgotPIN: {})
        .environmentObject(AppState())
}

#Preview("Locked Out") {
    let authService = AuthenticationService()
    authService.storeUser(UserModel(
        name: "Sarah",
        age: 28,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: PINService().hashPIN("1234")
    ))
    
    return LoginView(authService: authService, onForgotPIN: {})
        .environmentObject(AppState())
}
