import Foundation
import Combine
import SwiftUI

/// Main ViewModel for the onboarding flow
@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentStep: OnboardingStep = .name
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // User Input
    @Published var userName: String = ""
    @Published var userAge: String = ""
    @Published var userEmail: String = ""
    @Published var verificationCode: String = ""
    
    // PIN State
    @Published var pinState = PINState()
    @Published var pinError: PINError?
    @Published var showPINError: Bool = false
    
    // Verification State
    @Published var verificationState = VerificationState()
    @Published var canResendCode: Bool = false
    @Published var resendCooldown: Int = 0
    
    // MARK: - Private Properties
    
    private let validationService = ValidationService()
    private let pinService = PINService()
    private var cancellables = Set<AnyCancellable>()
    private var resendTimer: Timer?
    private var expirationTimer: Timer?
    
    // Simulated verification code for demo
    private var sentVerificationCode: String = ""
    
    // MARK: - Computed Properties
    
    var isCurrentStepValid: Bool {
        switch currentStep {
        case .name:
            return validationService.isValidName(userName)
        case .age:
            return validationService.isValidAge(userAge)
        case .email:
            return validationService.isValidEmail(userEmail)
        case .verification:
            return verificationCode.count == 6
        case .pinCreation:
            return pinState.isComplete
        case .pinConfirmation:
            return pinState.isConfirmComplete
        }
    }
    
    var primaryButtonTitle: String {
        switch currentStep {
        case .verification:
            return "Verify"
        case .pinConfirmation:
            return "Complete Setup"
        default:
            return "Continue"
        }
    }
    
    // MARK: - Navigation
    
    func goToNextStep() {
        Task {
            await handleStepTransition()
        }
    }
    
    func goToPreviousStep() {
        guard currentStep.canGoBack, currentStep.rawValue > 0 else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = previousStep
            }
        }
    }
    
    private func handleStepTransition() async {
        clearError()
        
        switch currentStep {
        case .name:
            if validationService.isValidName(userName) {
                advanceToNextStep()
            }
            
        case .age:
            if validationService.isValidAge(userAge) {
                advanceToNextStep()
            }
            
        case .email:
            await handleEmailStep()
            
        case .verification:
            await handleVerificationStep()
            
        case .pinCreation:
            handlePINCreationStep()
            
        case .pinConfirmation:
            await handlePINConfirmationStep()
        }
    }
    
    private func advanceToNextStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }
    
    // MARK: - Email Handling
    
    private func handleEmailStep() async {
        guard validationService.isValidEmail(userEmail) else {
            showError(message: "Please enter a valid email address")
            return
        }
        
        isLoading = true
        
        // Simulate API call to check if email exists and send verification
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Simulate email already in use (for demo, emails ending with @test.com are "taken")
        if userEmail.lowercased().hasSuffix("@test.com") {
            isLoading = false
            showError(message: "This email is already registered. Please use a different email.")
            return
        }
        
        // Generate and "send" verification code
        sentVerificationCode = String(format: "%06d", Int.random(in: 100000...999999))
        print("📧 Verification code sent: \(sentVerificationCode)") // For testing
        
        // Set expiration (5 minutes)
        verificationState = VerificationState(
            code: "",
            isExpired: false,
            expiresAt: Date().addingTimeInterval(300),
            attemptsRemaining: 3
        )
        
        startExpirationTimer()
        startResendCooldown()
        
        isLoading = false
        advanceToNextStep()
    }
    
    // MARK: - Verification Handling
    
    private func handleVerificationStep() async {
        guard verificationCode.count == 6 else { return }
        
        isLoading = true
        
        // Simulate verification delay
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // Check if expired
        if verificationState.isExpired {
            isLoading = false
            showError(message: "This code has expired. Please request a new one.")
            return
        }
        
        // Check attempts
        if verificationState.attemptsRemaining <= 0 {
            isLoading = false
            showError(message: "Too many attempts. Please request a new code.")
            return
        }
        
        // Verify code
        if verificationCode == sentVerificationCode {
            stopTimers()
            isLoading = false
            advanceToNextStep()
        } else {
            verificationState.attemptsRemaining -= 1
            isLoading = false
            
            if verificationState.attemptsRemaining > 0 {
                showError(message: "Incorrect code. \(verificationState.attemptsRemaining) attempt\(verificationState.attemptsRemaining == 1 ? "" : "s") remaining.")
            } else {
                showError(message: "Too many incorrect attempts. Please request a new code.")
            }
            
            // Clear the code field
            verificationCode = ""
        }
    }
    
    func resendVerificationCode() {
        guard canResendCode else { return }
        
        Task {
            isLoading = true
            
            // Simulate sending new code
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            sentVerificationCode = String(format: "%06d", Int.random(in: 100000...999999))
            print("📧 New verification code sent: \(sentVerificationCode)") // For testing
            
            verificationState = VerificationState(
                code: "",
                isExpired: false,
                expiresAt: Date().addingTimeInterval(300),
                attemptsRemaining: 3
            )
            verificationCode = ""
            
            startExpirationTimer()
            startResendCooldown()
            
            isLoading = false
        }
    }

#if DEBUG
    /// Demo helper: bypass email code entry and continue onboarding.
    /// Keeps the normal success path (stops timers + advances to next step) without requiring input.
    func confirmEmailForDemo() {
        guard currentStep == .verification else { return }
        stopTimers()
        clearError()
        verificationCode = ""
        isLoading = false
        advanceToNextStep()
    }
#endif
    
    func changeEmail() {
        stopTimers()
        verificationCode = ""
        verificationState = VerificationState()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = .email
        }
    }
    
    // MARK: - PIN Handling
    
    private func handlePINCreationStep() {
        guard pinState.isComplete else { return }
        
        // Validate PIN
        if let error = pinService.validatePIN(pinState.pin) {
            pinError = error
            showPINError = true
            
            // Clear PIN after showing error
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.pinState.pin = ""
            }
            return
        }
        
        advanceToNextStep()
    }
    
    private func handlePINConfirmationStep() async {
        guard pinState.isConfirmComplete else { return }
        
        if !pinState.pinsMatch {
            pinState.attemptsRemaining -= 1
            pinError = .mismatch
            showPINError = true
            
            if pinState.attemptsRemaining <= 0 {
                // Reset entire PIN flow
                restartPINSetup()
                showError(message: "Let's start over with your PIN")
            } else {
                // Clear confirmation PIN
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.pinState.confirmPin = ""
                }
            }
            return
        }
        
        // PIN confirmed successfully - hash and complete
        isLoading = true
        
        let hashedPIN = pinService.hashPIN(pinState.pin)
        
        // Simulate account creation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isLoading = false
        
        // Account creation complete
        // This will be handled by the parent view/app state
    }
    
    func restartPINSetup() {
        pinState = PINState()
        pinError = nil
        showPINError = false
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = .pinCreation
        }
    }
    
    // MARK: - PIN Input
    
    func appendPINDigit(_ digit: String) {
        // Clear any previous error
        if showPINError {
            showPINError = false
            pinError = nil
        }
        
        switch currentStep {
        case .pinCreation:
            if pinState.pin.count < 4 {
                pinState.pin += digit
                provideTapticFeedback()
            }
        case .pinConfirmation:
            if pinState.confirmPin.count < 4 {
                pinState.confirmPin += digit
                provideTapticFeedback()
            }
        default:
            break
        }
    }
    
    func deletePINDigit() {
        switch currentStep {
        case .pinCreation:
            if !pinState.pin.isEmpty {
                pinState.pin.removeLast()
                provideTapticFeedback()
            }
        case .pinConfirmation:
            if !pinState.confirmPin.isEmpty {
                pinState.confirmPin.removeLast()
                provideTapticFeedback()
            }
        default:
            break
        }
    }
    
    var currentPINLength: Int {
        switch currentStep {
        case .pinCreation:
            return pinState.pin.count
        case .pinConfirmation:
            return pinState.confirmPin.count
        default:
            return 0
        }
    }
    
    // MARK: - Timers
    
    private func startExpirationTimer() {
        expirationTimer?.invalidate()
        expirationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.verificationState.timeRemaining <= 0 {
                    self.verificationState.isExpired = true
                    self.expirationTimer?.invalidate()
                }
            }
        }
    }
    
    private func startResendCooldown() {
        canResendCode = false
        resendCooldown = 30
        
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.resendCooldown -= 1
                if self.resendCooldown <= 0 {
                    self.canResendCode = true
                    self.resendTimer?.invalidate()
                }
            }
        }
    }
    
    private func stopTimers() {
        expirationTimer?.invalidate()
        resendTimer?.invalidate()
    }
    
    // MARK: - Error Handling
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        provideErrorFeedback()
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
        pinError = nil
        showPINError = false
    }
    
    // MARK: - Haptics
    
    private func provideTapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func provideErrorFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Create Final User
    
    func createUser() -> UserModel {
        return UserModel(
            name: userName,
            age: Int(userAge) ?? 0,
            email: userEmail,
            isEmailVerified: true,
            pinHash: pinService.hashPIN(pinState.pin)
        )
    }
}
