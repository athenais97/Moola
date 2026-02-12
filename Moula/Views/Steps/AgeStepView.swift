import SwiftUI

/// Second step: Collect user's age
/// UX: Numeric keyboard optimized, clear purpose explanation
struct AgeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isAgeFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            VStack(spacing: 12) {
                Text(OnboardingStep.age.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.age.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 48)
            
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                TextField("Age", text: $viewModel.userAge)
                    .font(.system(size: 20, weight: .medium))
                    .keyboardType(.numberPad)
                    .focused($isAgeFocused)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isAgeFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .onChange(of: viewModel.userAge) { _, newValue in
                        // Limit to 3 digits
                        if newValue.count > 3 {
                            viewModel.userAge = String(newValue.prefix(3))
                        }
                        // Remove non-numeric characters
                        viewModel.userAge = newValue.filter { $0.isNumber }
                    }
                
                // Validation hint
                if let error = ValidationService().ageError(viewModel.userAge) {
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
                isAgeFocused = false
                viewModel.goToNextStep()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAgeFocused = true
            }
        }
    }
}

#Preview {
    AgeStepView(viewModel: OnboardingViewModel())
}
