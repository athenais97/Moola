import Foundation

/// Daily Credit: one claim per calendar day (device-local).
enum DailyCreditStore {
    static func lastClaimKey(email: String) -> String {
        let normalized = email.lowercased()
        return "daily_credit_last_claim_\(normalized)"
    }
    
    static func hasClaimedToday(email: String, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        let key = lastClaimKey(email: email)
        guard let stored = UserDefaults.standard.string(forKey: key),
              let today = dayStamp(for: now, calendar: calendar) else {
            return false
        }
        return stored == today
    }
    
    static func markClaimedToday(email: String, now: Date = Date(), calendar: Calendar = .current) {
        guard let stamp = dayStamp(for: now, calendar: calendar) else { return }
        UserDefaults.standard.set(stamp, forKey: lastClaimKey(email: email))
    }
    
    private static func dayStamp(for date: Date, calendar: Calendar) -> String? {
        // Stable per locale/timezone: we want "today" in the user's calendar.
        var cal = calendar
        cal.locale = Locale(identifier: "en_US_POSIX")
        
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return nil }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}

