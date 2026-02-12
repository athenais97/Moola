import Foundation

/// Shared credits persistence for the Pulse assistant + related paywall flows.
/// Backed by `UserDefaults` to match existing behavior.
enum PulseCreditsStore {
    /// Keep aligned with `PulseAssistantView`'s historical default.
    static let startingFreeCredits: Int = 5
    
    static func storageKey(email: String) -> String {
        let normalized = email.lowercased()
        return "pulse_assistant_credits_\(normalized)"
    }
    
    /// Ensures a stored credits value exists for this user and returns it.
    @discardableResult
    static func hydrateIfNeeded(email: String) -> Int {
        let key = storageKey(email: email)
        if let existing = UserDefaults.standard.object(forKey: key) as? Int {
            return existing
        }
        UserDefaults.standard.set(startingFreeCredits, forKey: key)
        return startingFreeCredits
    }
    
    static func get(email: String) -> Int {
        let key = storageKey(email: email)
        if let existing = UserDefaults.standard.object(forKey: key) as? Int {
            return existing
        }
        return startingFreeCredits
    }
    
    static func set(email: String, credits: Int) {
        UserDefaults.standard.set(max(0, credits), forKey: storageKey(email: email))
    }
    
    @discardableResult
    static func add(email: String, delta: Int) -> Int {
        let current = hydrateIfNeeded(email: email)
        let updated = max(0, current + delta)
        set(email: email, credits: updated)
        return updated
    }
}

