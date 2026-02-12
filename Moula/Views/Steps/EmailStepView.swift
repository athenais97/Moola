import SwiftUI

/// Third step: Collect user's email
/// UX: Email keyboard, clear feedback on format validation
struct EmailStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            VStack(spacing: 12) {
                Text(OnboardingStep.email.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.email.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 48)
            
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                TextField("email@example.com", text: $viewModel.userEmail)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isEmailFocused)
                    .dsInputField(isFocused: isEmailFocused, hasError: borderColor == .red)
                
                // Validation hint
                if let error = ValidationService().emailError(viewModel.userEmail) {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                } else if viewModel.showError, let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue button
            PrimaryButton(
                title: viewModel.primaryButtonTitle,
                isEnabled: viewModel.isCurrentStepValid,
                isLoading: viewModel.isLoading
            ) {
                isEmailFocused = false
                viewModel.goToNextStep()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isEmailFocused = true
            }
        }
        .onChange(of: viewModel.userEmail) { _, _ in
            viewModel.clearError()
        }
    }
    
    private var borderColor: Color {
        if viewModel.showError {
            return .red
        }
        return isEmailFocused ? DesignSystem.Colors.focusBorder : Color.clear
    }
}

#Preview {
    EmailStepView(viewModel: OnboardingViewModel())
}
