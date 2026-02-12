import Foundation
import CryptoKit

/// Errors that can occur during PIN validation
enum PINError: Error, Equatable {
    case tooShort
    case obviousPattern
    case mismatch
    case tooManyAttempts
    
    var message: String {
        switch self {
        case .tooShort:
            return "PIN must be 4 digits"
        case .obviousPattern:
            return "This PIN is too easy to guess. Please choose something more unique."
        case .mismatch:
            return "PINs don't match. Please try again."
        case .tooManyAttempts:
            return "Too many attempts. Let's start over."
        }
    }
}

/// Service for PIN validation, hashing, and security
struct PINService {
    /// Primary salt used for new PIN hashes.
    private let primarySalt = "Moola_PIN_Salt_v1"
    
    /// Legacy salt kept for backwards compatibility with previously stored PIN hashes.
    /// (Stored as base64 to avoid coupling the current codebase to the old app name.)
    private let legacySaltBase64 = "T25ib2FyZGluZ0FwcF9QSU5fU2FsdF92MQ=="
    
    private var legacySalt: String {
        guard
            let data = Data(base64Encoded: legacySaltBase64),
            let str = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return str
    }
    
    // MARK: - Obvious PIN Patterns
    
    /// PINs that are rejected for being too predictable
    private let obviousPINs: Set<String> = [
        // Repeated digits
        "0000", "1111", "2222", "3333", "4444",
        "5555", "6666", "7777", "8888", "9999",
        
        // Sequential patterns
        "0123", "1234", "2345", "3456", "4567",
        "5678", "6789", "9876", "8765", "7654",
        "6543", "5432", "4321", "3210",
        
        // Common patterns
        "1212", "2121", "1010", "0101",
        "1122", "2211", "1221", "2112",
        
        // Years (common birth years)
        "1990", "1991", "1992", "1993", "1994",
        "1995", "1996", "1997", "1998", "1999",
        "2000", "2001", "2002", "2003", "2004",
        "2005", "2006", "2007", "2008", "2009",
        "2010", "2020", "2021", "2022", "2023",
        "2024", "2025", "2026",
        
        // Other common
        "1357", "2468", "1379", "0852",
        "1470", "2580", "3690", "0000"
    ]
    
    // MARK: - Validation
    
    /// Validates a PIN and returns an error if invalid
    func validatePIN(_ pin: String) -> PINError? {
        // Check length
        guard pin.count == 4 else {
            return .tooShort
        }
        
        // Check if all characters are digits
        guard pin.allSatisfy({ $0.isNumber }) else {
            return .tooShort
        }
        
        // Check for obvious patterns
        if obviousPINs.contains(pin) {
            return .obviousPattern
        }
        
        // Check for repeated digit pattern (like 1212, 3434)
        if isRepeatingPattern(pin) {
            return .obviousPattern
        }
        
        return nil
    }
    
    /// Check if PIN is a repeating 2-digit pattern
    private func isRepeatingPattern(_ pin: String) -> Bool {
        guard pin.count == 4 else { return false }
        let chars = Array(pin)
        return chars[0] == chars[2] && chars[1] == chars[3]
    }
    
    // MARK: - Hashing
    
    /// Hashes the PIN using SHA256 with a salt
    /// In production, you would use a more robust KDF like PBKDF2, bcrypt, or Argon2
    func hashPIN(_ pin: String) -> String {
        let data = Data((primarySalt + pin).utf8)
        let hash = SHA256.hash(data: data)
        
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verifies a PIN against a stored hash
    func verifyPIN(_ pin: String, against storedHash: String) -> Bool {
        if hashPIN(pin) == storedHash {
            return true
        }
        
        // Backwards compatibility: allow previously stored hashes created before the rename.
        let legacyHash = SHA256.hash(data: Data((legacySalt + pin).utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
        
        return legacyHash == storedHash
    }
    
    // MARK: - Brute Force Protection
    
    /// Calculates lockout duration based on failed attempts
    func lockoutDuration(forAttempts attempts: Int) -> TimeInterval {
        switch attempts {
        case 0...2:
            return 0 // No lockout
        case 3...4:
            return 30 // 30 seconds
        case 5...6:
            return 60 // 1 minute
        case 7...8:
            return 300 // 5 minutes
        default:
            return 900 // 15 minutes
        }
    }
}
