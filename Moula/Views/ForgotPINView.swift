import SwiftUI

/// Recovery flow state
enum RecoveryStep: Int, CaseIterable {
    case emailVerification
    case newPIN
    case confirmPIN
    case success
    
    var title: String {
        switch self {
        case .emailVerification:
            return "Verify your email"
        case .newPIN:
            return "Create a new PIN"
        case .confirmPIN:
            return "Confirm your PIN"
        case .success:
            return "PIN updated"
        }
    }
    
    var subtitle: String {
        switch self {
        case .emailVerification:
            return "We'll send a code to verify it's you"
        case .newPIN:
            return "Choose a 4-digit PIN you'll remember"
        case .confirmPIN:
            return "Enter your new PIN again to confirm"
        case .success:
            return "You can now log in with your new PIN"
        }
    }
}

/// Forgot PIN recovery flow
/// UX Intent: Secure but frictionless PIN reset with email verification
/// - Progressive disclosure: one step at a time
/// - Clear progress indication
/// - Reuses existing PIN creation patterns for consistency
struct ForgotPINView: View {
    @StateObject private var viewModel: ForgotPINViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// Callback when PIN is successfully reset
    var onComplete: () -> Void
    
    init(authService: AuthenticationService, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ForgotPINViewModel(authService: authService))
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                
                // Step content
                stepContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.currentStep != .emailVerification)
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= viewModel.currentStep.rawValue ? Color.accentColor : Color(.systemGray4))
                    .frame(height: 4)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .emailVerification:
            emailVerificationStep
        case .newPIN:
            newPINStep
        case .confirmPIN:
            confirmPINStep
        case .success:
            successStep
        }
    }
    
    // MARK: - Email Verification Step
    
    private var emailVerificationStep: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 48)
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 8)
                
                Text(viewModel.currentStep.title)
                    .font(.system(size: 24, weight: .bold))
                
                if let email = viewModel.maskedEmail {
                    Text("We'll send a verification code to \(email)")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
                .frame(height: 32)
            
            // Verification code input
            if viewModel.isCodeSent {
                verificationCodeInput
            }
            
            Spacer()
            
            // Action button
            VStack(spacing: 16) {
                if !viewModel.isCodeSent {
                    PrimaryButton(title: "Send verification code") {
                        viewModel.sendVerificationCode()
                    }
                    .padding(.horizontal, 24)
                } else {
                    PrimaryButton(
                        title: "Verify",
                        isEnabled: viewModel.verificationCode.count == 6
                    ) {
                        viewModel.verifyCode()
                    }
                    .padding(.horizontal, 24)
                    
                    // Resend option
                    if viewModel.canResendCode {
                        Button("Resend code") {
                            viewModel.sendVerificationCode()
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.accentColor)
                    } else {
                        Text("Resend in \(viewModel.resendCountdown)s")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 32)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isCodeSent)
    }
    
    private var verificationCodeInput: some View {
        VStack(spacing: 16) {
            // 6-digit code input
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    CodeDigitView(
                        digit: viewModel.codeDigit(at: index),
                        isFocused: index == viewModel.verificationCode.count
                    )
                }
            }
            .padding(.horizontal, 32)
            
            // Hidden text field for input
            TextField("", text: $viewModel.verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .opacity(0)
                .frame(width: 1, height: 1)
                .focused($isCodeFieldFocused)
        }
        .onTapGesture {
            isCodeFieldFocused = true
        }
        .onAppear {
            isCodeFieldFocused = true
        }
    }
    
    @FocusState private var isCodeFieldFocused: Bool
    
    // MARK: - New PIN Step
    
    private var newPINStep: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 48)
            
            // Header
            VStack(spacing: 12) {
                Text(viewModel.currentStep.title)
                    .font(.system(size: 24, weight: .bold))
                
                Text(viewModel.currentStep.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
                .frame(height: 40)
            
            // PIN dots
            VStack(spacing: 16) {
                PINDotsView(
                    filledCount: viewModel.newPIN.count,
                    hasError: viewModel.showPINError
                )
                
                if let error = viewModel.pinErrorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(height: 60)
            
            Spacer()
            
            // Keypad
            NumericKeypad(
                onDigitTap: { digit in
                    viewModel.appendNewPINDigit(digit)
                },
                onDelete: {
                    viewModel.deleteNewPINDigit()
                }
            )
            
            Spacer()
                .frame(height: 32)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showPINError)
    }
    
    // MARK: - Confirm PIN Step
    
    private var confirmPINStep: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 48)
            
            // Header
            VStack(spacing: 12) {
                Text(viewModel.currentStep.title)
                    .font(.system(size: 24, weight: .bold))
                
                Text(viewModel.currentStep.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
                .frame(height: 40)
            
            // PIN dots
            VStack(spacing: 16) {
                PINDotsView(
                    filledCount: viewModel.confirmPIN.count,
                    hasError: viewModel.showConfirmError
                )
                
                if viewModel.showConfirmError {
                    Text("PINs don't match. Please try again.")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(height: 60)
            
            Spacer()
            
            // Keypad
            NumericKeypad(
                onDigitTap: { digit in
                    viewModel.appendConfirmPINDigit(digit)
                },
                onDelete: {
                    viewModel.deleteConfirmPINDigit()
                }
            )
            
            Spacer()
                .frame(height: 32)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showConfirmError)
    }
    
    // MARK: - Success Step
    
    private var successStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text(viewModel.currentStep.title)
                    .font(.system(size: 24, weight: .bold))
                
                Text(viewModel.currentStep.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            PrimaryButton(title: "Back to login") {
                onComplete()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Code Digit View

private struct CodeDigitView: View {
    let digit: String?
    let isFocused: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(width: 48, height: 56)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                .frame(width: 48, height: 56)
            
            if let digit = digit {
                Text(digit)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
            } else if isFocused {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2, height: 24)
                    .opacity(isFocused ? 1 : 0)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: digit)
    }
}

// MARK: - ViewModel

@MainActor
final class ForgotPINViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var currentStep: RecoveryStep = .emailVerification
    @Published var verificationCode: String = "" {
        didSet {
            // Limit to 6 digits
            if verificationCode.count > 6 {
                verificationCode = String(verificationCode.prefix(6))
            }
            // Only allow digits
            verificationCode = verificationCode.filter { $0.isNumber }
        }
    }
    @Published var isCodeSent: Bool = false
    @Published var canResendCode: Bool = false
    @Published var resendCountdown: Int = 30
    @Published var errorMessage: String?
    
    @Published var newPIN: String = ""
    @Published var confirmPIN: String = ""
    @Published var showPINError: Bool = false
    @Published var showConfirmError: Bool = false
    @Published var pinErrorMessage: String?
    
    // MARK: - Dependencies
    
    private let authService: AuthenticationService
    private let pinService = PINService()
    private var resendTimer: Timer?
    
    // MARK: - Computed Properties
    
    var maskedEmail: String? {
        authService.storedUserEmail.map { email in
            let parts = email.split(separator: "@")
            guard parts.count == 2 else { return email }
            let local = String(parts[0])
            let domain = String(parts[1])
            if local.count <= 2 { return "\(local)***@\(domain)" }
            return "\(local.prefix(2))***@\(domain)"
        }
    }
    
    // MARK: - Initialization
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    func codeDigit(at index: Int) -> String? {
        guard index < verificationCode.count else { return nil }
        let codeIndex = verificationCode.index(verificationCode.startIndex, offsetBy: index)
        return String(verificationCode[codeIndex])
    }
    
    func sendVerificationCode() {
        // Simulate sending code (in production, call API)
        isCodeSent = true
        errorMessage = nil
        startResendCountdown()
    }
    
    func verifyCode() {
        // Simulate verification (in production, validate with server)
        // For demo, accept "123456"
        if verificationCode == "123456" || verificationCode.count == 6 {
            withAnimation {
                currentStep = .newPIN
            }
        } else {
            errorMessage = "Invalid code. Please try again."
        }
    }
    
    func appendNewPINDigit(_ digit: String) {
        guard newPIN.count < 4 else { return }
        
        if showPINError {
            showPINError = false
            pinErrorMessage = nil
        }
        
        newPIN += digit
        
        // Validate when complete
        if newPIN.count == 4 {
            validateNewPIN()
        }
    }
    
    func deleteNewPINDigit() {
        guard !newPIN.isEmpty else { return }
        newPIN.removeLast()
        showPINError = false
        pinErrorMessage = nil
    }
    
    func appendConfirmPINDigit(_ digit: String) {
        guard confirmPIN.count < 4 else { return }
        
        if showConfirmError {
            showConfirmError = false
        }
        
        confirmPIN += digit
        
        // Validate when complete
        if confirmPIN.count == 4 {
            validateConfirmPIN()
        }
    }
    
    func deleteConfirmPINDigit() {
        guard !confirmPIN.isEmpty else { return }
        confirmPIN.removeLast()
        showConfirmError = false
    }
    
    // MARK: - Private Methods
    
    private func validateNewPIN() {
        if let error = pinService.validatePIN(newPIN) {
            showPINError = true
            pinErrorMessage = error.message
            
            // Clear after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.newPIN = ""
            }
        } else {
            // Valid PIN, move to confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    self.currentStep = .confirmPIN
                }
            }
        }
    }
    
    private func validateConfirmPIN() {
        if confirmPIN == newPIN {
            // PINs match - save and complete
            savePIN()
        } else {
            showConfirmError = true
            
            // Clear and let user retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.confirmPIN = ""
            }
        }
    }
    
    private func savePIN() {
        // Hash and store the new PIN
        let hashedPIN = pinService.hashPIN(newPIN)
        
        // In production, this would update via API
        // For now, we update the stored user locally
        if let email = authService.storedUserEmail,
           let name = authService.storedUserName {
            let updatedUser = UserModel(
                name: name,
                age: 0, // Not stored in preview
                email: email,
                isEmailVerified: true,
                pinHash: hashedPIN
            )
            authService.storeUser(updatedUser)
            authService.clearState() // Clear failed attempts
        }
        
        // Show success
        withAnimation {
            currentStep = .success
        }
    }
    
    private func startResendCountdown() {
        canResendCode = false
        resendCountdown = 30
        
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateResendCountdown()
            }
        }
    }
    
    private func updateResendCountdown() {
        resendCountdown -= 1
        if resendCountdown <= 0 {
            canResendCode = true
            resendTimer?.invalidate()
        }
    }
    
    deinit {
        resendTimer?.invalidate()
    }
}

// MARK: - Previews

#Preview("Email Verification") {
    let authService = AuthenticationService()
    authService.storeUser(UserModel(
        name: "Sarah",
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: ""
    ))
    
    return ForgotPINView(authService: authService, onComplete: {})
}

#Preview("New PIN") {
    let authService = AuthenticationService()
    return ForgotPINView(authService: authService, onComplete: {})
}
