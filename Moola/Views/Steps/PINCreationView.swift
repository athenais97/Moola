import SwiftUI

/// Fifth step: PIN creation with custom numeric keypad
/// UX: No system keyboard, masked input, micro-interactions
struct PINCreationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            VStack(spacing: 12) {
                Text(OnboardingStep.pinCreation.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.pinCreation.subtitle)
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
                    filledCount: viewModel.currentPINLength,
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
            }
            .frame(height: 80)
            
            Spacer()
            
            // Custom numeric keypad
            NumericKeypad(
                onDigitTap: { digit in
                    viewModel.appendPINDigit(digit)
                    
                    // Auto-advance when complete
                    if viewModel.pinState.isComplete {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            viewModel.goToNextStep()
                        }
                    }
                },
                onDelete: {
                    viewModel.deletePINDigit()
                }
            )
            
            Spacer()
                .frame(height: 32)
            
            // Help text
            Text("Choose a PIN you'll remember")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showPINError)
    }
}

#Preview {
    PINCreationView(viewModel: OnboardingViewModel())
}
