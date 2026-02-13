import SwiftUI

/// Fourth step: Email verification code entry
/// UX: Auto-advancing digit fields, resend flow, change email option
struct VerificationStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isCodeFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            VStack(spacing: 12) {
                Text(OnboardingStep.verification.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(OnboardingStep.verification.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Show email being verified
                Text(viewModel.userEmail)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentColor)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 48)
            
            // Code input
            VStack(spacing: 24) {
                // Hidden TextField for keyboard
                TextField("", text: $viewModel.verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isCodeFocused)
                    .opacity(0)
                    .frame(height: 0)
                    .onChange(of: viewModel.verificationCode) { _, newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            viewModel.verificationCode = String(newValue.prefix(6))
                        }
                        // Remove non-numeric characters
                        viewModel.verificationCode = newValue.filter { $0.isNumber }
                    }
                
                // Visual code boxes
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        CodeDigitBox(
                            digit: digit(at: index),
                            isCurrent: index == viewModel.verificationCode.count,
                            hasError: viewModel.showError
                        )
                        .onTapGesture {
                            isCodeFocused = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Error message
                if viewModel.showError, let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Expiration warning
                if viewModel.verificationState.isExpired {
                    Text("This code has expired")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
                .frame(height: 32)
            
            // Resend and change email options
            VStack(spacing: 16) {
                if viewModel.canResendCode {
                    SecondaryButton(title: "Resend code", isEnabled: true) {
                        viewModel.resendVerificationCode()
                    }
                } else if viewModel.resendCooldown > 0 {
                    Text("Resend code in \(viewModel.resendCooldown)s")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                SecondaryButton(title: "Change email address", isEnabled: true) {
                    viewModel.changeEmail()
                }
                
#if DEBUG
                Button {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    viewModel.confirmEmailForDemo()
                } label: {
                    Text("Demo: confirm without code")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Demo confirm email without code")
#endif
            }
            
            Spacer()
            
            // Verify button
            PrimaryButton(
                title: viewModel.primaryButtonTitle,
                isEnabled: viewModel.isCurrentStepValid,
                isLoading: viewModel.isLoading
            ) {
                isCodeFocused = false
                viewModel.goToNextStep()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCodeFocused = true
            }
        }
        .onChange(of: viewModel.verificationCode) { _, _ in
            if viewModel.showError {
                viewModel.clearError()
            }
        }
    }
    
    private func digit(at index: Int) -> String? {
        let code = viewModel.verificationCode
        guard index < code.count else { return nil }
        let charIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[charIndex])
    }
}

/// Individual digit box for verification code
struct CodeDigitBox: View {
    let digit: String?
    let isCurrent: Bool
    let hasError: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(width: 48, height: 56)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
                .frame(width: 48, height: 56)
            
            if let digit = digit {
                Text(digit)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .animation(.easeOut(duration: 0.1), value: digit)
    }
    
    private var borderColor: Color {
        if hasError {
            return .red
        }
        if isCurrent {
            return .accentColor
        }
        if digit != nil {
            return .accentColor.opacity(0.5)
        }
        return .clear
    }
}

#Preview {
    VerificationStepView(viewModel: OnboardingViewModel())
}
