import SwiftUI

/// Sixth step: PIN confirmation
/// UX: Matches PIN creation UX, clear error states for mismatch
struct PINConfirmationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            VStack(spacing: 12) {
                Text(OnboardingStep.pinConfirmation.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.pinConfirmation.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 24)
            
            Spacer()
                .frame(height: 48)
            
            // PIN dots
            VStack(spacing: 16) {
                PINDotsView(
                    filledCount: viewModel.pinState.confirmPin.count,
                    hasError: viewModel.showPINError
                )
                
                // Error message
                if viewModel.showPINError, let error = viewModel.pinError {
                    Text(error.message)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.horizontal, 24)
                }
                
                // Attempts remaining (if mismatch occurred)
                if viewModel.pinState.attemptsRemaining < 3 && viewModel.pinState.attemptsRemaining > 0 {
                    Text("\(viewModel.pinState.attemptsRemaining) attempt\(viewModel.pinState.attemptsRemaining == 1 ? "" : "s") remaining")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 100)
            
            Spacer()
            
            // Custom numeric keypad
            NumericKeypad(
                onDigitTap: { digit in
                    viewModel.appendPINDigit(digit)
                    
                    // Auto-verify when complete
                    if viewModel.pinState.isConfirmComplete {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            handlePINConfirmation()
                        }
                    }
                },
                onDelete: {
                    viewModel.deletePINDigit()
                }
            )
            
            Spacer()
                .frame(height: 16)
            
            // Restart option
            SecondaryButton(title: "Start over", isEnabled: true) {
                viewModel.restartPINSetup()
            }
            .padding(.bottom, 24)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showPINError)
        .overlay {
            // Loading overlay for account creation
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Creating your account...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray2))
                    )
                }
                .transition(.opacity)
            }
        }
    }
    
    private func handlePINConfirmation() {
        Task {
            viewModel.goToNextStep()
            
            // Wait for validation
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            // If PINs match and validation passed, complete onboarding
            if viewModel.pinState.pinsMatch && !viewModel.showPINError {
                let user = viewModel.createUser()
                appState.completeOnboarding(with: user)
            }
        }
    }
}

#Preview {
    PINConfirmationView(viewModel: OnboardingViewModel())
        .environmentObject(AppState())
}
