import Foundation
import Combine
import SwiftUI

/// State representing login attempt result
enum LoginResult: Equatable {
    case idle
    case validating
    case success
    case failure(message: String)
    case locked(secondsRemaining: Int)
}

/// ViewModel managing the login screen state and interactions
/// Handles PIN entry, validation, error states, and lockout timers
@MainActor
final class LoginViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current PIN being entered (masked, never shown)
    @Published private(set) var enteredPIN: String = ""
    
    /// Current login result state
    @Published private(set) var loginResult: LoginResult = .idle
    
    /// Whether to show error state on PIN dots
    @Published private(set) var showError: Bool = false
    
    /// Error message to display
    @Published private(set) var errorMessage: String?
    
    /// Countdown timer for lockout state
    @Published private(set) var lockoutCountdown: Int = 0
    
    /// Remaining attempts before lockout
    @Published private(set) var remainingAttempts: Int = 3
    
    // MARK: - Dependencies
    
    private let authService: AuthenticationService
    private var lockoutTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Number of digits currently entered
    var currentPINLength: Int {
        enteredPIN.count
    }
    
    /// Whether the PIN is complete (4 digits)
    var isPINComplete: Bool {
        enteredPIN.count == 4
    }
    
    /// Whether input should be disabled (during validation or lockout)
    var isInputDisabled: Bool {
        switch loginResult {
        case .validating, .locked:
            return true
        default:
            return false
        }
    }
    
    /// User's first name for personalized greeting
    var userName: String? {
        authService.storedUserName
    }
    
    /// Masked email for display (jo***@example.com)
    var maskedEmail: String? {
        guard let email = authService.storedUserEmail else { return nil }
        return maskEmail(email)
    }
    
    // MARK: - Initialization
    
    init(authService: AuthenticationService = AuthenticationService()) {
        self.authService = authService
        self.remainingAttempts = authService.remainingAttempts
        
        // Check for existing lockout
        if let seconds = authService.lockoutSecondsRemaining {
            startLockoutCountdown(seconds: seconds)
        }
    }
    
    // MARK: - Public Methods
    
    /// Appends a digit to the current PIN
    func appendDigit(_ digit: String) {
        guard !isInputDisabled else { return }
        guard enteredPIN.count < 4 else { return }
        
        // Clear any previous error state
        if showError {
            clearError()
        }
        
        enteredPIN += digit
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Auto-validate when complete
        if enteredPIN.count == 4 {
            Task {
                await validatePIN()
            }
        }
    }
    
    /// Removes the last digit from the PIN
    func deleteDigit() {
        guard !isInputDisabled else { return }
        guard !enteredPIN.isEmpty else { return }
        
        // Clear error state if present
        if showError {
            clearError()
        }
        
        enteredPIN.removeLast()
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Clears the entire PIN entry
    func clearPIN() {
        enteredPIN = ""
        clearError()
    }
    
    /// Manually triggers PIN validation (if needed)
    func submitPIN() async {
        guard isPINComplete else { return }
        await validatePIN()
    }
    
    // MARK: - Private Methods
    
    private func validatePIN() async {
        loginResult = .validating
        
        do {
            try await authService.authenticate(with: enteredPIN)
            
            // Success - provide strong haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            loginResult = .success
            
        } catch let error as AuthenticationError {
            handleAuthError(error)
        } catch {
            handleAuthError(.networkUnavailable)
        }
    }
    
    private func handleAuthError(_ error: AuthenticationError) {
        // Provide error haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        switch error {
        case .accountLocked(let seconds):
            loginResult = .locked(secondsRemaining: seconds)
            errorMessage = error.message
            startLockoutCountdown(seconds: seconds)
            showError = true
            
            // Clear PIN after brief delay to show the error
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.enteredPIN = ""
            }
            
        case .invalidPIN:
            loginResult = .failure(message: error.message)
            errorMessage = error.message
            showError = true
            remainingAttempts = authService.remainingAttempts
            
            // Reset PIN after showing error animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.enteredPIN = ""
                // Keep error message visible briefly after clearing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if self.loginResult == .failure(message: error.message) {
                        self.clearError()
                        self.loginResult = .idle
                    }
                }
            }
            
        case .networkUnavailable, .sessionExpired:
            loginResult = .failure(message: error.message)
            errorMessage = error.message
            showError = true
            
            // Clear after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.enteredPIN = ""
            }
        }
    }
    
    private func clearError() {
        showError = false
        errorMessage = nil
        loginResult = .idle
    }
    
    private func startLockoutCountdown(seconds: Int) {
        lockoutCountdown = seconds
        loginResult = .locked(secondsRemaining: seconds)
        
        lockoutTimer?.invalidate()
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateLockoutCountdown()
            }
        }
    }
    
    private func updateLockoutCountdown() {
        lockoutCountdown -= 1
        
        if lockoutCountdown <= 0 {
            lockoutTimer?.invalidate()
            lockoutTimer = nil
            loginResult = .idle
            showError = false
            errorMessage = nil
            remainingAttempts = 3 // Reset display (actual attempts tracked in service)
        } else {
            loginResult = .locked(secondsRemaining: lockoutCountdown)
        }
    }
    
    private func maskEmail(_ email: String) -> String {
        let components = email.split(separator: "@")
        guard components.count == 2 else { return email }
        
        let localPart = String(components[0])
        let domain = String(components[1])
        
        if localPart.count <= 2 {
            return "\(localPart)***@\(domain)"
        }
        
        let visibleChars = String(localPart.prefix(2))
        return "\(visibleChars)***@\(domain)"
    }
    
    deinit {
        lockoutTimer?.invalidate()
    }
}
