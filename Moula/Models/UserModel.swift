import Foundation

// MARK: - User Model

/// Represents the user being created during onboarding
struct UserModel {
    var name: String
    var age: Int
    var email: String
    var phone: String
    var isEmailVerified: Bool
    var pinHash: String
    var investorProfile: InvestorProfile?
    var membershipLevel: MembershipLevel
    
    init(
        name: String = "",
        age: Int = 0,
        email: String = "",
        phone: String = "",
        isEmailVerified: Bool = false,
        pinHash: String = "",
        investorProfile: InvestorProfile? = nil,
        membershipLevel: MembershipLevel = .standard
    ) {
        self.name = name
        self.age = age
        self.email = email
        self.phone = phone
        self.isEmailVerified = isEmailVerified
        self.pinHash = pinHash
        self.investorProfile = investorProfile
        self.membershipLevel = membershipLevel
    }
    
    /// Whether the user has completed investor profiling
    var hasCompletedProfiling: Bool {
        investorProfile?.isComplete ?? false
    }
    
    /// Masked phone number showing only last 4 digits
    /// Example: "•••• •••• 1234"
    var maskedPhone: String {
        guard phone.count >= 4 else { return phone }
        let lastFour = String(phone.suffix(4))
        return "•••• •••• \(lastFour)"
    }
    
    /// Masked email showing first 2 chars and domain
    /// Example: "jo••••@example.com"
    var maskedEmail: String {
        guard let atIndex = email.firstIndex(of: "@") else { return email }
        let prefix = String(email.prefix(2))
        let domain = String(email[atIndex...])
        return "\(prefix)••••\(domain)"
    }
}

/// User membership tier for premium features
enum MembershipLevel: String, Codable {
    case standard = "Standard"
    case premium = "Premium Investor"
    case elite = "Elite Investor"
    
    var displayName: String {
        rawValue
    }
}

/// Verification code state
struct VerificationState {
    var code: String = ""
    var isExpired: Bool = false
    var expiresAt: Date?
    var attemptsRemaining: Int = 3
    
    /// Time remaining until expiration
    var timeRemaining: TimeInterval {
        guard let expiresAt = expiresAt else { return 0 }
        return max(0, expiresAt.timeIntervalSinceNow)
    }
    
    var isValid: Bool {
        return !isExpired && attemptsRemaining > 0
    }
}

/// PIN creation state
struct PINState {
    var pin: String = ""
    var confirmPin: String = ""
    var attemptsRemaining: Int = 3
    
    var isComplete: Bool {
        return pin.count == 4
    }
    
    var isConfirmComplete: Bool {
        return confirmPin.count == 4
    }
    
    var pinsMatch: Bool {
        return pin == confirmPin
    }
}
