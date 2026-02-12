import Foundation

/// Represents each step in the investor profiling flow
/// This flow captures the user's "Investor DNA" after account creation
enum InvestorProfilingStep: Int, CaseIterable {
    case objective = 0
    case riskAppetite = 1
    case knowledgeLevel = 2
    
    /// Step title - human, conversational tone
    var title: String {
        switch self {
        case .objective:
            return "What matters most to you?"
        case .riskAppetite:
            return "How do you feel about risk?"
        case .knowledgeLevel:
            return "How familiar are you with investing?"
        }
    }
    
    /// Step subtitle - supportive, outcome-oriented
    var subtitle: String {
        switch self {
        case .objective:
            return "This helps us understand your priorities"
        case .riskAppetite:
            return "There's no right answer—just what feels right"
        case .knowledgeLevel:
            return "We'll tailor your experience accordingly"
        }
    }
    
    /// Total number of profiling steps
    var totalSteps: Int {
        InvestorProfilingStep.allCases.count
    }
    
    /// Progress value from 0 to 1
    var progress: Double {
        Double(self.rawValue + 1) / Double(totalSteps)
    }
    
    /// Whether back navigation is allowed from this step
    var canGoBack: Bool {
        self != .objective
    }
    
    /// Step indicator text (e.g., "1 of 3")
    var stepIndicator: String {
        "\(rawValue + 1) of \(totalSteps)"
    }
}
