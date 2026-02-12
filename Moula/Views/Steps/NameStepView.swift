import SwiftUI

/// First step: Collect user's name
/// UX: Single focused input with friendly tone
struct NameStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            VStack(spacing: 12) {
                Text(OnboardingStep.name.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.name.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 48)
            
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                TextField("Your first name", text: $viewModel.userName)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .focused($isNameFocused)
                    .dsInputField(isFocused: isNameFocused, hasError: ValidationService().nameError(viewModel.userName) != nil)
                
                // Validation hint
                if let error = ValidationService().nameError(viewModel.userName) {
                    Text(error)
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
                isNameFocused = false
                viewModel.goToNextStep()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            // Auto-focus after transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
}

#Preview {
    NameStepView(viewModel: OnboardingViewModel())
}
