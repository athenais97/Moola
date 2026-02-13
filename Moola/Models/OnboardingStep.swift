import Foundation

/// Represents each step in the onboarding flow
enum OnboardingStep: Int, CaseIterable {
    case name = 0
    case age = 1
    case email = 2
    case verification = 3
    case pinCreation = 4
    case pinConfirmation = 5
    
    var title: String {
        switch self {
        case .name:
            return "What's your name?"
        case .age:
            return "How old are you?"
        case .email:
            return "What's your email?"
        case .verification:
            return "Check your inbox"
        case .pinCreation:
            return "Create your PIN"
        case .pinConfirmation:
            return "Confirm your PIN"
        }
    }
    
    var subtitle: String {
        switch self {
        case .name:
            return "Let's get to know you"
        case .age:
            return "We'll personalize your experience"
        case .email:
            return "We'll send you a verification code"
        case .verification:
            return "Enter the 6-digit code we sent you"
        case .pinCreation:
            return "Your PIN gives you quick, secure access to the app"
        case .pinConfirmation:
            return "Enter your PIN one more time"
        }
    }
    
    var totalSteps: Int {
        return OnboardingStep.allCases.count
    }
    
    /// Progress value from 0 to 1
    var progress: Double {
        return Double(self.rawValue + 1) / Double(totalSteps)
    }
    
    /// Whether back navigation is allowed from this step
    var canGoBack: Bool {
        switch self {
        case .name:
            return false
        case .pinConfirmation:
            return false // As per requirements, unless justified
        default:
            return true
        }
    }
}
