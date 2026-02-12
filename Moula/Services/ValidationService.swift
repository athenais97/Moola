import Foundation

/// Service for validating user inputs during onboarding
struct ValidationService {
    
    // MARK: - Name Validation
    
    func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 50
    }
    
    func nameError(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return nil // No error for empty (just not valid yet)
        }
        
        if trimmed.count < 2 {
            return "Name must be at least 2 characters"
        }
        
        if trimmed.count > 50 {
            return "Name is too long"
        }
        
        return nil
    }
    
    // MARK: - Age Validation
    
    func isValidAge(_ ageString: String) -> Bool {
        guard let age = Int(ageString) else { return false }
        return age >= 13 && age <= 120
    }
    
    func ageError(_ ageString: String) -> String? {
        guard !ageString.isEmpty else { return nil }
        
        guard let age = Int(ageString) else {
            return "Please enter a valid number"
        }
        
        if age < 13 {
            return "You must be at least 13 years old"
        }
        
        if age > 120 {
            return "Please enter a valid age"
        }
        
        return nil
    }
    
    // MARK: - Email Validation
    
    func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic email regex pattern
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return predicate.evaluate(with: trimmed)
    }
    
    func emailError(_ email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else { return nil }
        
        if !isValidEmail(trimmed) {
            return "Please enter a valid email address"
        }
        
        return nil
    }
    
    // MARK: - Verification Code Validation
    
    func isValidVerificationCode(_ code: String) -> Bool {
        let digitsOnly = code.filter { $0.isNumber }
        return digitsOnly.count == 6
    }
}
