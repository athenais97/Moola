import Foundation

/// Represents the user's investment profile captured during profiling
/// This "Investor DNA" personalizes the dashboard, suggestions, and guidance level
struct InvestorProfile: Codable, Equatable {
    var objective: InvestmentObjective?
    var riskTolerance: Double // 0.0 (conservative) to 1.0 (aggressive)
    var knowledgeLevel: KnowledgeLevel?
    
    init(
        objective: InvestmentObjective? = nil,
        riskTolerance: Double = 0.5,
        knowledgeLevel: KnowledgeLevel? = nil
    ) {
        self.objective = objective
        self.riskTolerance = riskTolerance
        self.knowledgeLevel = knowledgeLevel
    }
    
    /// Whether the profile has been completed
    var isComplete: Bool {
        objective != nil && knowledgeLevel != nil
    }
}

// MARK: - Investment Objective

/// The user's primary investment goal
/// Determines suggested portfolio allocation and dashboard emphasis
enum InvestmentObjective: String, Codable, CaseIterable {
    case security
    case balanced
    case growth
    
    /// User-facing title
    var title: String {
        switch self {
        case .security:
            return "Security"
        case .balanced:
            return "Balanced"
        case .growth:
            return "Growth"
        }
    }
    
    /// Outcome-oriented description (human, not technical)
    var description: String {
        switch self {
        case .security:
            return "Preserve what I have"
        case .balanced:
            return "Steady, reliable growth"
        case .growth:
            return "Maximize my returns"
        }
    }
    
    /// Longer explanation for progressive disclosure
    var detailedExplanation: String {
        switch self {
        case .security:
            return "Your portfolio will prioritize stability. You'll see lower volatility and more conservative options that help protect your capital."
        case .balanced:
            return "Your portfolio will blend stability with growth opportunities. A mix that aims for solid returns while managing risk."
        case .growth:
            return "Your portfolio will emphasize higher growth potential. This means more volatility, but greater opportunity over time."
        }
    }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .security:
            return "shield.fill"
        case .balanced:
            return "scale.3d"
        case .growth:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    /// Whether this is the recommended default option
    var isRecommended: Bool {
        self == .balanced
    }
}

// MARK: - Knowledge Level

/// User's self-assessed financial literacy
/// Affects guidance level and explanation depth, never feature access
enum KnowledgeLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case expert
    
    /// User-facing title
    var title: String {
        switch self {
        case .beginner:
            return "I'm just starting"
        case .intermediate:
            return "I know the basics"
        case .expert:
            return "I'm experienced"
        }
    }
    
    /// Supportive description that avoids judgment
    var description: String {
        switch self {
        case .beginner:
            return "New to investing or prefer guided help"
        case .intermediate:
            return "Familiar with common investment terms"
        case .expert:
            return "Comfortable making independent decisions"
        }
    }
    
    /// Reassuring message shown after selection
    var confirmationMessage: String {
        switch self {
        case .beginner:
            return "We'll guide you step by step"
        case .intermediate:
            return "We'll provide context when helpful"
        case .expert:
            return "We'll keep things streamlined"
        }
    }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .beginner:
            return "lightbulb.fill"
        case .intermediate:
            return "book.fill"
        case .expert:
            return "star.fill"
        }
    }
}

// MARK: - Risk Tolerance Helpers

extension InvestorProfile {
    /// Human-readable risk label based on tolerance value
    var riskLabel: String {
        switch riskTolerance {
        case 0..<0.25:
            return "Conservative"
        case 0.25..<0.5:
            return "Cautious"
        case 0.5..<0.75:
            return "Moderate"
        case 0.75...1.0:
            return "Adventurous"
        default:
            return "Moderate"
        }
    }
    
    /// Emotional framing of risk tolerance for microcopy
    var riskMicrocopy: String {
        switch riskTolerance {
        case 0..<0.2:
            return "I sleep well knowing my investments are safe"
        case 0.2..<0.4:
            return "I prefer stability, with some room for growth"
        case 0.4..<0.6:
            return "I'm okay with ups and downs for better returns"
        case 0.6..<0.8:
            return "I can handle volatility for higher potential"
        case 0.8...1.0:
            return "I'm comfortable with significant swings"
        default:
            return "I'm okay with ups and downs for better returns"
        }
    }
}
