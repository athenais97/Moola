import Foundation
import Combine

/// Errors that can occur during authentication
enum AuthenticationError: Error, Equatable {
    case invalidPIN
    case accountLocked(remainingSeconds: Int)
    case networkUnavailable
    case sessionExpired
    
    var message: String {
        switch self {
        case .invalidPIN:
            return "Incorrect PIN. Please try again."
        case .accountLocked(let seconds):
            if seconds >= 60 {
                let minutes = seconds / 60
                return "Too many attempts. Try again in \(minutes) minute\(minutes > 1 ? "s" : "")."
            }
            return "Too many attempts. Try again in \(seconds) seconds."
        case .networkUnavailable:
            return "Unable to connect. Please check your connection and try again."
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        }
    }
}

/// Represents the current authentication session state
enum SessionState: Equatable {
    case unauthenticated
    case authenticated(user: UserModel)
    case locked(until: Date)
    
    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let user1), .authenticated(let user2)):
            return user1.email == user2.email
        case (.locked(let date1), .locked(let date2)):
            return date1 == date2
        default:
            return false
        }
    }
}

/// Service responsible for handling user authentication
/// Manages PIN verification, session state, and security lockouts
final class AuthenticationService: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var sessionState: SessionState = .unauthenticated
    @Published private(set) var failedAttempts: Int = 0
    @Published private(set) var lockoutEndTime: Date?
    
    // MARK: - Dependencies
    
    private let pinService: PINService
    private var lockoutTimer: Timer?
    
    // MARK: - Constants
    
    private let maxAttemptsBeforeLock = 3
    private let userDefaultsKey = "stored_user"
    private let attemptsKey = "failed_pin_attempts"
    private let lockoutKey = "lockout_end_time"
    private let linkedAccountIdsKey = "linked_account_ids"
    
    // MARK: - Initialization
    
    init(pinService: PINService = PINService()) {
        self.pinService = pinService
        loadPersistedState()
    }
    
    // MARK: - Public Methods
    
    /// Attempts to authenticate user with the provided PIN
    /// Returns true on success, throws AuthenticationError on failure
    @discardableResult
    func authenticate(with pin: String) async throws -> Bool {
        // Check if currently locked out
        if let lockoutEnd = lockoutEndTime, Date() < lockoutEnd {
            let remaining = Int(lockoutEnd.timeIntervalSinceNow)
            throw AuthenticationError.accountLocked(remainingSeconds: remaining)
        }
        
        // Get stored user (in production, this would validate against server)
        guard let storedUser = getStoredUser() else {
            // No user found - should redirect to onboarding
            throw AuthenticationError.sessionExpired
        }
        
        // Verify PIN against stored hash
        let isValid = pinService.verifyPIN(pin, against: storedUser.pinHash)
        
        if isValid {
            await handleSuccessfulLogin(user: storedUser)
            return true
        } else {
            await handleFailedAttempt()
            
            // Check if we should lock
            if failedAttempts >= maxAttemptsBeforeLock {
                let lockoutDuration = pinService.lockoutDuration(forAttempts: failedAttempts)
                if lockoutDuration > 0 {
                    let lockoutEnd = Date().addingTimeInterval(lockoutDuration)
                    await setLockout(until: lockoutEnd)
                    throw AuthenticationError.accountLocked(remainingSeconds: Int(lockoutDuration))
                }
            }
            
            throw AuthenticationError.invalidPIN
        }
    }
    
    /// Returns the number of remaining attempts before lockout
    var remainingAttempts: Int {
        max(0, maxAttemptsBeforeLock - failedAttempts)
    }
    
    /// Returns true if the user is currently locked out
    var isLockedOut: Bool {
        guard let lockoutEnd = lockoutEndTime else { return false }
        return Date() < lockoutEnd
    }
    
    /// Returns seconds remaining in lockout, or nil if not locked
    var lockoutSecondsRemaining: Int? {
        guard let lockoutEnd = lockoutEndTime else { return nil }
        let remaining = lockoutEnd.timeIntervalSinceNow
        return remaining > 0 ? Int(remaining) : nil
    }
    
    /// Logs out the current user
    func logout() {
        DispatchQueue.main.async {
            self.sessionState = .unauthenticated
        }
    }
    
    /// Clears all authentication state (for testing or account reset)
    func clearState() {
        DispatchQueue.main.async {
            self.failedAttempts = 0
            self.lockoutEndTime = nil
            self.sessionState = .unauthenticated
        }
        lockoutTimer?.invalidate()
        lockoutTimer = nil
        UserDefaults.standard.removeObject(forKey: attemptsKey)
        UserDefaults.standard.removeObject(forKey: lockoutKey)
    }

    /// Clears only the stored user (removes the saved account on this device).
    func clearStoredUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        DispatchQueue.main.async {
            self.sessionState = .unauthenticated
        }
    }

    /// Removes all locally persisted state for a fresh start.
    func resetAllLocalState() {
        clearStoredUser()
        clearState()
        UserDefaults.standard.removeObject(forKey: linkedAccountIdsKey)
    }
    
    /// Stores user after successful onboarding (called from onboarding flow)
    func storeUser(_ user: UserModel) {
        if let encoded = try? JSONEncoder().encode(CodableUser(from: user)) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    /// Checks if a user account exists (for routing decisions)
    var hasStoredUser: Bool {
        return getStoredUser() != nil
    }
    
    /// Gets the stored user's display name for the login screen
    var storedUserName: String? {
        return getStoredUser()?.name
    }
    
    /// Gets the stored user's email for recovery purposes
    var storedUserEmail: String? {
        return getStoredUser()?.email
    }
    
    /// Gets the full stored user model (used after successful authentication)
    func getAuthenticatedUser() -> UserModel? {
        return getStoredUser()
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func handleSuccessfulLogin(user: UserModel) {
        failedAttempts = 0
        lockoutEndTime = nil
        sessionState = .authenticated(user: user)
        persistState()
    }
    
    @MainActor
    private func handleFailedAttempt() {
        failedAttempts += 1
        persistState()
    }
    
    @MainActor
    private func setLockout(until date: Date) {
        lockoutEndTime = date
        sessionState = .locked(until: date)
        persistState()
        startLockoutTimer()
    }
    
    private func startLockoutTimer() {
        lockoutTimer?.invalidate()
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkLockoutStatus()
        }
    }
    
    private func checkLockoutStatus() {
        guard let lockoutEnd = lockoutEndTime else {
            lockoutTimer?.invalidate()
            return
        }
        
        if Date() >= lockoutEnd {
            DispatchQueue.main.async {
                self.lockoutEndTime = nil
                if case .locked = self.sessionState {
                    self.sessionState = .unauthenticated
                }
            }
            lockoutTimer?.invalidate()
            persistState()
        }
    }
    
    private func getStoredUser() -> UserModel? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let codableUser = try? JSONDecoder().decode(CodableUser.self, from: data) else {
            return nil
        }
        return codableUser.toUserModel()
    }
    
    private func persistState() {
        UserDefaults.standard.set(failedAttempts, forKey: attemptsKey)
        if let lockoutEnd = lockoutEndTime {
            UserDefaults.standard.set(lockoutEnd.timeIntervalSince1970, forKey: lockoutKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lockoutKey)
        }
    }
    
    private func loadPersistedState() {
        failedAttempts = UserDefaults.standard.integer(forKey: attemptsKey)
        
        let lockoutTimestamp = UserDefaults.standard.double(forKey: lockoutKey)
        if lockoutTimestamp > 0 {
            let lockoutEnd = Date(timeIntervalSince1970: lockoutTimestamp)
            if Date() < lockoutEnd {
                lockoutEndTime = lockoutEnd
                sessionState = .locked(until: lockoutEnd)
                startLockoutTimer()
            } else {
                // Lockout has expired
                UserDefaults.standard.removeObject(forKey: lockoutKey)
            }
        }
    }
}

// MARK: - Codable User Wrapper

/// Wrapper to make UserModel codable for persistence
private struct CodableUser: Codable {
    let name: String
    let age: Int
    let email: String
    let phone: String
    let isEmailVerified: Bool
    let pinHash: String
    let investorProfile: InvestorProfile?
    let membershipLevel: MembershipLevel
    
    init(from user: UserModel) {
        self.name = user.name
        self.age = user.age
        self.email = user.email
        self.phone = user.phone
        self.isEmailVerified = user.isEmailVerified
        self.pinHash = user.pinHash
        self.investorProfile = user.investorProfile
        self.membershipLevel = user.membershipLevel
    }
    
    func toUserModel() -> UserModel {
        return UserModel(
            name: name,
            age: age,
            email: email,
            phone: phone,
            isEmailVerified: isEmailVerified,
            pinHash: pinHash,
            investorProfile: investorProfile,
            membershipLevel: membershipLevel
        )
    }
}
