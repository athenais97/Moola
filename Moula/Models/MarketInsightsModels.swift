import Foundation
import SwiftUI

// MARK: - Market Insights Models
/// Data models for the Market Insights & Portfolio Impact Projection feature
///
/// UX Intent:
/// - Curated news linked to user's specific accounts/assets
/// - "What this means for you" perspective on market events
/// - Non-deterministic impact indicators (avoid specific price predictions)
///
/// Foundation Compliance:
/// - Visual hierarchy over raw density
/// - Context and meaning, not just numbers
/// - Avoid financial advice language (use "Market Sentiment", "Analyst Consensus")

// MARK: - Portfolio Climate (Sentiment)

/// Overall sentiment/mood for the user's portfolio based on current news
/// UX: High-level summary answering "What's the market feeling like for my holdings?"
enum PortfolioClimate: String, CaseIterable {
    case veryBullish = "Very Positive"
    case bullish = "Positive"
    case neutral = "Neutral"
    case bearish = "Mediocre"
    case veryBearish = "Uncertain"
    
    /// Display color (requested mapping):
    /// - Good: green
    /// - Mediocre: orange
    /// - Bad: red
    var color: Color {
        switch self {
        case .veryBullish, .bullish:
            return Color(red: 0.18, green: 0.72, blue: 0.45)  // Green
        case .neutral:
            return Color(red: 0.55, green: 0.55, blue: 0.6)   // Neutral gray
        case .bearish:
            return Color(red: 0.95, green: 0.62, blue: 0.20)  // Orange
        case .veryBearish:
            return Color(red: 0.90, green: 0.20, blue: 0.22)  // Red
        }
    }
    
    /// Background tint for sentiment header
    var backgroundColor: Color {
        color.opacity(0.08)
    }
    
    /// Icon representing the climate
    var iconName: String {
        switch self {
        case .veryBullish:
            return "arrow.up.right.circle.fill"
        case .bullish:
            return "arrow.up.right"
        case .neutral:
            return "arrow.left.arrow.right"
        case .bearish:
            return "arrow.down.right"
        case .veryBearish:
            return "arrow.down.right.circle.fill"
        }
    }
    
    /// Emoji “smiley” icon for the climate (safe offline iconography).
    var emoji: String {
        switch self {
        case .veryBullish, .bullish:
            return "😊"
        case .neutral:
            return "😐"
        case .bearish: // "Mediocre"
            return "🙁"
        case .veryBearish:
            return "😡"
        }
    }
    
    /// Human-readable description
    var description: String {
        switch self {
        case .veryBullish:
            return "Market sentiment strongly favors your holdings"
        case .bullish:
            return "Analyst consensus is generally optimistic"
        case .neutral:
            return "Mixed signals across your portfolio"
        case .bearish:
            return "Some headwinds may affect your positions"
        case .veryBearish:
            return "Market conditions warrant close monitoring"
        }
    }
    
    /// Sentiment value for gauge visualization (0.0 to 1.0)
    var gaugeValue: Double {
        switch self {
        case .veryBullish: return 0.9
        case .bullish: return 0.7
        case .neutral: return 0.5
        case .bearish: return 0.3
        case .veryBearish: return 0.1
        }
    }
}

// MARK: - Impact Level

/// How much a news event matters to the user's specific holdings
/// UX: "Impact Tags" with clear visual hierarchy
enum ImpactLevel: String, CaseIterable, Comparable {
    case high = "High Impact"
    case medium = "Medium"
    case low = "Low Impact"
    case general = "General Market"  // No direct exposure
    
    var emoji: String {
        switch self {
        case .high: return "🔴"
        case .medium: return "🟠"
        case .low: return "🟢"
        case .general: return "⚪"
        }
    }
    
    var color: Color {
        switch self {
        case .high:
            return Color(red: 0.92, green: 0.45, blue: 0.42)  // Soft red
        case .medium:
            return Color(red: 0.95, green: 0.68, blue: 0.35)  // Amber
        case .low:
            return Color(red: 0.35, green: 0.75, blue: 0.55)  // Soft green
        case .general:
            return Color(red: 0.55, green: 0.55, blue: 0.6)   // Neutral gray
        }
    }
    
    var backgroundColor: Color {
        color.opacity(0.1)
    }
    
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        case .general: return 3
        }
    }
    
    static func < (lhs: ImpactLevel, rhs: ImpactLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Vibrancy Level (Movement Indicator)

/// Non-deterministic visual indicator for potential movement
/// UX: "Vibrancy" or "heat" instead of specific price predictions
enum VibrancyLevel: String, CaseIterable {
    case elevated = "Elevated Activity"
    case moderate = "Moderate"
    case calm = "Calm"
    
    var color: Color {
        switch self {
        case .elevated:
            return Color(red: 0.95, green: 0.55, blue: 0.35)  // Warm orange
        case .moderate:
            return Color(red: 0.65, green: 0.6, blue: 0.85)   // Soft purple
        case .calm:
            return Color(red: 0.45, green: 0.7, blue: 0.85)   // Calm blue
        }
    }
    
    /// Animation intensity for visual feedback
    var animationIntensity: Double {
        switch self {
        case .elevated: return 1.0
        case .moderate: return 0.5
        case .calm: return 0.2
        }
    }
    
    var description: String {
        switch self {
        case .elevated:
            return "Higher than usual activity expected"
        case .moderate:
            return "Typical market activity"
        case .calm:
            return "Lower volatility expected"
        }
    }
}

// MARK: - Insight Feedback

/// Feedback types for insight relevance
/// UX: Simple, binary feedback - user signals "helpful" or "not for me"
/// Supports engagement and personalization without complexity
/// Non-blocking - does not require input to dismiss the screen
enum InsightFeedback: String, CaseIterable {
    case helpful = "Helpful"
    case notRelevant = "Not for me"
    
    var iconName: String {
        switch self {
        case .helpful: return "hand.thumbsup"
        case .notRelevant: return "hand.thumbsdown"
        }
    }
    
    var selectedIconName: String {
        switch self {
        case .helpful: return "hand.thumbsup.fill"
        case .notRelevant: return "hand.thumbsdown.fill"
        }
    }
}

// MARK: - Insight Action

/// Optional actions a user can take in response to an insight
/// UX: Light, non-prescriptive decision guidance
/// Avoids financial advice - focuses on awareness and monitoring
enum InsightAction: String, CaseIterable, Identifiable {
    case review = "Review"
    case setAlert = "Set Alert"
    case ignore = "Ignore"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .review: return "doc.text.magnifyingglass"
        case .setAlert: return "bell.badge"
        case .ignore: return "eye.slash"
        }
    }
    
    /// Neutral, supportive description of the action
    var description: String {
        switch self {
        case .review:
            return "View your related holdings"
        case .setAlert:
            return "Get notified of updates"
        case .ignore:
            return "Hide from your feed"
        }
    }
    
    var color: Color {
        switch self {
        case .review: return Color.accentColor
        case .setAlert: return Color(red: 0.65, green: 0.6, blue: 0.85) // Soft purple
        case .ignore: return Color(red: 0.55, green: 0.55, blue: 0.6)   // Neutral gray
        }
    }
}

// MARK: - Market Insight (Smart Insight Card)

/// A curated news insight linked to user's portfolio
/// UX: Each card answers "What does this news mean for ME?"
/// Upgrade: Now includes decision guidance to help users understand relevance
struct MarketInsight: Identifiable, Equatable {
    let id: String
    let headline: String
    let summary: String
    let source: String
    let timestamp: Date
    let impactLevel: ImpactLevel
    let vibrancy: VibrancyLevel
    let affectedAccounts: [AffectedAccount]
    let category: InsightCategory
    let isLive: Bool  // Real-time indicator
    let tags: [String]
    let heroSymbolName: String
    
    // MARK: - Decision Guidance (Upgrade)
    // Short, neutral explanation of why this insight matters to the user
    // Helps answer: "Does this matter to me?"
    let whyItMatters: String?
    
    // Available actions the user can consider (optional, light guidance)
    // Helps answer: "What should I consider doing?"
    let suggestedActions: [InsightAction]
    
    /// For "Top 3 for You" algorithm - relevance score
    var relevanceScore: Double {
        var score: Double = 0
        
        // Impact level contribution
        switch impactLevel {
        case .high: score += 40
        case .medium: score += 25
        case .low: score += 15
        case .general: score += 5
        }
        
        // Vibrancy contribution
        switch vibrancy {
        case .elevated: score += 30
        case .moderate: score += 15
        case .calm: score += 5
        }
        
        // Recency contribution (fresher = higher)
        let hoursOld = Date().timeIntervalSince(timestamp) / 3600
        if hoursOld < 1 { score += 30 }
        else if hoursOld < 6 { score += 20 }
        else if hoursOld < 24 { score += 10 }
        
        return score
    }
    
    /// Formatted timestamp for display
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    static func == (lhs: MarketInsight, rhs: MarketInsight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Affected Account

/// An account/asset affected by a market insight
/// UX: "Your Exposure" pill showing which holdings are impacted
struct AffectedAccount: Identifiable, Hashable {
    let id: String
    let institutionName: String
    let accountLabel: String  // e.g., "Tech Stocks", "ETF Portfolio"
    let color: Color
    
    /// Display label for the exposure badge
    var displayLabel: String {
        "\(institutionName) - \(accountLabel)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AffectedAccount, rhs: AffectedAccount) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Insight Category

/// Categories of market insights
enum InsightCategory: String, CaseIterable {
    case interestRates = "Interest Rates"
    case earnings = "Earnings"
    case economic = "Economic Data"
    case sector = "Sector News"
    case crypto = "Crypto"
    case geopolitical = "Geopolitical"
    case regulatory = "Regulatory"
    
    var iconName: String {
        switch self {
        case .interestRates: return "percent"
        case .earnings: return "chart.bar.doc.horizontal.fill"
        case .economic: return "chart.line.uptrend.xyaxis"
        case .sector: return "building.2.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .geopolitical: return "globe"
        case .regulatory: return "building.columns.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .interestRates: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .earnings: return Color(red: 0.4, green: 0.75, blue: 0.5)
        case .economic: return Color(red: 0.6, green: 0.5, blue: 0.8)
        case .sector: return Color(red: 0.95, green: 0.65, blue: 0.3)
        case .crypto: return Color(red: 0.95, green: 0.75, blue: 0.25)
        case .geopolitical: return Color(red: 0.5, green: 0.7, blue: 0.85)
        case .regulatory: return Color(red: 0.7, green: 0.55, blue: 0.65)
        }
    }
}

// MARK: - Scheduled Event

/// Future economic or corporate event to watch
/// UX: "Event Timeline" showing upcoming dates that may affect portfolio
struct ScheduledEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let date: Date
    let eventType: EventType
    let expectedImpact: ImpactLevel
    let relatedAccounts: [AffectedAccount]
    let isWatched: Bool  // User has added to watchlist
    
    /// Whether event is happening today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Whether event is in the next 7 days
    var isThisWeek: Bool {
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return date <= weekFromNow && date >= Date()
    }
    
    /// Formatted date for display
    var formattedDate: String {
        if isToday {
            return "Today"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Formatted time for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    /// Days until event
    var daysUntil: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return max(0, components.day ?? 0)
    }
    
    static func == (lhs: ScheduledEvent, rhs: ScheduledEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Event Type

/// Types of scheduled events
enum EventType: String, CaseIterable {
    case earningsCall = "Earnings Call"
    case economicReport = "Economic Report"
    case fedMeeting = "Fed Meeting"
    case dividendDate = "Dividend Date"
    case productLaunch = "Product Launch"
    case regulatoryDeadline = "Regulatory"
    
    var iconName: String {
        switch self {
        case .earningsCall: return "megaphone.fill"
        case .economicReport: return "doc.text.fill"
        case .fedMeeting: return "building.columns.fill"
        case .dividendDate: return "dollarsign.circle.fill"
        case .productLaunch: return "gift.fill"
        case .regulatoryDeadline: return "doc.badge.clock.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .earningsCall: return Color(red: 0.4, green: 0.75, blue: 0.5)
        case .economicReport: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .fedMeeting: return Color(red: 0.6, green: 0.5, blue: 0.8)
        case .dividendDate: return Color(red: 0.95, green: 0.75, blue: 0.25)
        case .productLaunch: return Color(red: 0.95, green: 0.65, blue: 0.3)
        case .regulatoryDeadline: return Color(red: 0.7, green: 0.55, blue: 0.65)
        }
    }
}

// MARK: - Market Insights State

/// Overall state for the Market Insights feature
struct MarketInsightsState: Equatable {
    var climate: PortfolioClimate
    var insights: [MarketInsight]
    var events: [ScheduledEvent]
    var lastRefresh: Date
    var isLoading: Bool
    var showAllInsights: Bool  // Toggle between "Top 3" and all
    
    /// Top insights based on relevance algorithm
    /// UX: Prevents cognitive overload with "Top 3 for You"
    var topInsights: [MarketInsight] {
        let sorted = insights.sorted { $0.relevanceScore > $1.relevanceScore }
        return Array(sorted.prefix(3))
    }
    
    /// Insights to display based on current toggle
    var displayedInsights: [MarketInsight] {
        showAllInsights ? insights : topInsights
    }
    
    /// Upcoming events (future only)
    var upcomingEvents: [ScheduledEvent] {
        events
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }
    
    /// Events in the next 7 days
    var thisWeekEvents: [ScheduledEvent] {
        upcomingEvents.filter { $0.isThisWeek }
    }
    
    /// Whether data is fresh (< 5 minutes old)
    var isFresh: Bool {
        Date().timeIntervalSince(lastRefresh) < 300
    }
    
    /// Formatted last refresh time
    var lastRefreshFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastRefresh, relativeTo: Date())
    }
    
    static let empty = MarketInsightsState(
        climate: .neutral,
        insights: [],
        events: [],
        lastRefresh: Date(),
        isLoading: true,
        showAllInsights: false
    )
}

// MARK: - Sample Data

extension MarketInsight {
    
    /// Sample insights for development and previews
    /// Upgrade: Now includes decision guidance with "whyItMatters" and "suggestedActions"
    static let sampleInsights: [MarketInsight] = [
        MarketInsight(
            id: "insight_001",
            headline: "Federal Reserve Reopens the Door to a Rate Hike",
            summary: "Officials signaled they could keep rates higher for longer if inflation re-accelerates, which can pressure growth assets and borrowing costs.",
            source: "Reuters",
            timestamp: Date().addingTimeInterval(-1800), // 30 min ago
            impactLevel: .high,
            vibrancy: .elevated,
            affectedAccounts: [
                AffectedAccount(
                    id: "acc_001",
                    institutionName: "Fidelity",
                    accountLabel: "Tech Stocks",
                    color: Color(red: 0.4, green: 0.75, blue: 0.5)
                ),
                AffectedAccount(
                    id: "acc_002",
                    institutionName: "Schwab",
                    accountLabel: "Bond Portfolio",
                    color: Color(red: 0.3, green: 0.6, blue: 0.9)
                )
            ],
            category: .interestRates,
            isLive: true,
            tags: ["Interest Rates", "Inflation", "Bonds"],
            heroSymbolName: "percent",
            // Decision guidance: neutral, supportive tone
            whyItMatters: "Rate shifts can affect both your tech holdings and bond prices. This touches 2 of your accounts—worth watching for volatility.",
            suggestedActions: [.review, .setAlert]
        ),
        
        MarketInsight(
            id: "insight_002",
            headline: "Shipping Disruptions Push Up Input Costs",
            summary: "Geopolitical friction and rerouted shipping lanes are increasing delivery times and costs, which can weigh on margins in some sectors.",
            source: "Bloomberg",
            timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
            impactLevel: .medium,
            vibrancy: .elevated,
            affectedAccounts: [
                AffectedAccount(
                    id: "acc_001",
                    institutionName: "Fidelity",
                    accountLabel: "Tech Stocks",
                    color: Color(red: 0.4, green: 0.75, blue: 0.5)
                )
            ],
            category: .geopolitical,
            isLive: true,
            tags: ["Supply Chain", "Margins", "Geopolitics"],
            heroSymbolName: "shippingbox.fill",
            // Decision guidance: clear personal relevance
            whyItMatters: "You have exposure via your Tech Stocks basket. Cost pressure can change sentiment quickly—especially during elevated activity.",
            suggestedActions: [.setAlert, .ignore]
        ),
        
        MarketInsight(
            id: "insight_003",
            headline: "Inflation Print Comes in Hotter Than Expected",
            summary: "Consumer prices rose faster than forecasts, adding uncertainty around the timing of policy changes.",
            source: "Bureau of Labor Statistics",
            timestamp: Date().addingTimeInterval(-14400), // 4 hours ago
            impactLevel: .medium,
            vibrancy: .moderate,
            affectedAccounts: [
                AffectedAccount(
                    id: "acc_002",
                    institutionName: "Schwab",
                    accountLabel: "Bond Portfolio",
                    color: Color(red: 0.3, green: 0.6, blue: 0.9)
                )
            ],
            category: .economic,
            isLive: false,
            tags: ["CPI", "Macro", "Rates"],
            heroSymbolName: "chart.line.uptrend.xyaxis",
            // Decision guidance: explains connection
            whyItMatters: "Inflation trends can move bond prices and rate expectations. This may increase short-term swings in your bond allocation.",
            suggestedActions: [.review, .ignore]
        ),
        
        MarketInsight(
            id: "insight_004",
            headline: "Semiconductor Names See Elevated Volatility",
            summary: "Options activity and mixed guidance are driving faster price moves across chipmakers, which can spill over into broader tech sentiment.",
            source: "Financial Times",
            timestamp: Date().addingTimeInterval(-10800), // 3 hours ago
            impactLevel: .low,
            vibrancy: .elevated,
            affectedAccounts: [
                AffectedAccount(
                    id: "acc_001",
                    institutionName: "Fidelity",
                    accountLabel: "Tech Stocks",
                    color: Color(red: 0.4, green: 0.75, blue: 0.5)
                )
            ],
            category: .sector,
            isLive: true,
            tags: ["Options", "Semis", "Volatility"],
            heroSymbolName: "cpu",
            // Decision guidance: helpful even with no direct exposure
            whyItMatters: "Your Tech Stocks basket can feel this indirectly. Elevated activity usually means wider swings—keep an eye on your exposure.",
            suggestedActions: [.review, .setAlert]
        ),
        
        MarketInsight(
            id: "insight_005",
            headline: "Crypto Volatility Cools After a Fast Move",
            summary: "After a sharp rally, activity has eased. Markets can still move quickly, but conditions look less heated than earlier today.",
            source: "CoinDesk",
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            impactLevel: .low,
            vibrancy: .moderate,
            affectedAccounts: [
                AffectedAccount(
                    id: "acc_003",
                    institutionName: "Coinbase",
                    accountLabel: "Crypto Wallet",
                    color: Color(red: 0.95, green: 0.75, blue: 0.25)
                )
            ],
            category: .crypto,
            isLive: true,
            tags: ["Crypto", "Momentum", "Risk"],
            heroSymbolName: "bitcoinsign.circle.fill",
            // Decision guidance: acknowledges volatility neutrally
            whyItMatters: "Your Coinbase holdings can still swing, but the pace has cooled. This is a lighter watch item versus your rate and equity exposure today.",
            suggestedActions: [.review, .setAlert]
        )
    ]
    
    /// Randomized finance-themed insights (titles, tags, and hero visuals).
    /// Intended for the Market Insights screen mock feed.
    static func randomizedFinanceInsights(
        count: Int,
        seed: UInt64 = UInt64(Date().timeIntervalSince1970)
    ) -> [MarketInsight] {
        let now = Date()
        var rng = SeededGenerator(seed: seed)
        
        let sources = ["Reuters", "Bloomberg", "Financial Times", "WSJ", "CNBC", "The Economist", "MarketWatch", "CoinDesk"]
        let heroSymbols = [
            "chart.line.uptrend.xyaxis",
            "chart.bar.fill",
            "dollarsign.circle.fill",
            "percent",
            "building.columns.fill",
            "banknote.fill",
            "bitcoinsign.circle.fill",
            "globe",
            "briefcase.fill",
            "creditcard.fill"
        ]
        
        let tagsPool = [
            "Macro", "Fed", "Rates", "Bonds", "Inflation", "Earnings", "Guidance", "Valuations",
            "Tech", "Energy", "Banks", "Small Caps", "FX", "Dollar", "Oil", "Gold", "Crypto",
            "Volatility", "Liquidity", "Risk", "Dividends", "Credit Spreads"
        ]
        
        let summaryTemplates: [String] = [
            "Investors weighed new data against expectations, with rate-sensitive assets reacting first and broader indexes following.",
            "Analysts highlighted how policy timing could influence borrowing costs, equity multiples, and short-term volatility.",
            "Flows shifted across sectors as traders balanced growth momentum with valuation discipline and macro uncertainty.",
            "Price action suggests positioning is changing quickly—especially in areas with higher leverage or tighter liquidity.",
            "Moves were concentrated in a handful of names, but the ripple effects reached diversified portfolios."
        ]
        
        let accountPool: [AffectedAccount] = [
            AffectedAccount(id: "acc_tech", institutionName: "Fidelity", accountLabel: "Tech Stocks", color: Color(red: 0.4, green: 0.75, blue: 0.5)),
            AffectedAccount(id: "acc_bonds", institutionName: "Schwab", accountLabel: "Bond Portfolio", color: Color(red: 0.3, green: 0.6, blue: 0.9)),
            AffectedAccount(id: "acc_div", institutionName: "Vanguard", accountLabel: "Dividend ETF", color: Color(red: 0.55, green: 0.6, blue: 0.9)),
            AffectedAccount(id: "acc_us", institutionName: "Robinhood", accountLabel: "US Equity", color: Color(red: 0.6, green: 0.5, blue: 0.8)),
            AffectedAccount(id: "acc_crypto", institutionName: "Coinbase", accountLabel: "Crypto Wallet", color: Color(red: 0.95, green: 0.75, blue: 0.25))
        ]
        
        func randomImpact() -> ImpactLevel {
            // Weighted: mostly medium/low, occasional high.
            let roll = Int.random(in: 0..<100, using: &rng)
            if roll < 15 { return .high }
            if roll < 55 { return .medium }
            return .low
        }
        
        func randomVibrancy() -> VibrancyLevel {
            let roll = Int.random(in: 0..<100, using: &rng)
            if roll < 35 { return .elevated }
            if roll < 75 { return .moderate }
            return .calm
        }
        
        func randomAffectedAccounts() -> [AffectedAccount] {
            let count = Int.random(in: 0...2, using: &rng)
            if count == 0 { return [] }
            return Array(accountPool.shuffled(using: &rng).prefix(count))
        }
        
        func randomTags() -> [String] {
            let tags = Array(tagsPool.shuffled(using: &rng).prefix(Int.random(in: 2...4, using: &rng)))
            return Array(Set(tags)).sorted()
        }
        
        func randomWhyItMatters(impact: ImpactLevel, accounts: [AffectedAccount]) -> String? {
            let roll = Int.random(in: 0..<100, using: &rng)
            guard roll < 75 else { return nil }
            
            if accounts.isEmpty {
                return impact == .high
                ? "Even without direct exposure, broad market shifts can spill into diversified holdings—worth a quick scan."
                : "This looks more like a background trend than a direct driver for your positions."
            }
            
            if accounts.count == 1 {
                return "This relates to your \(accounts[0].accountLabel) exposure—watch for short-term swings as the story develops."
            }
            
            return "This touches \(accounts.count) parts of your portfolio. Keep an eye on volatility and correlations across holdings."
        }
        
        func randomSuggestedActions(for impact: ImpactLevel) -> [InsightAction] {
            switch impact {
            case .high: return [.review, .setAlert]
            case .medium: return Bool.random(using: &rng) ? [.setAlert, .ignore] : [.review, .ignore]
            case .low: return [.ignore]
            case .general: return [.ignore]
            }
        }
        
        return (0..<max(0, count)).map { idx in
            let impact = randomImpact()
            let vibrancy = randomVibrancy()
            let accounts = randomAffectedAccounts()
            let category = InsightCategory.allCases.randomElement(using: &rng) ?? .economic
            let headline: String = {
                switch Int.random(in: 0..<5, using: &rng) {
                case 0:
                    return "Markets Parse Fresh Signals on \(pick(["Rates", "Inflation", "Growth"], using: &rng))"
                case 1:
                    return "\(pick(["Earnings", "Guidance", "Margins"], using: &rng)) in Focus as \(pick(["Mega-Caps", "Banks", "Energy"], using: &rng)) Report"
                case 2:
                    return "\(pick(["Dollar", "Oil", "Gold", "Bitcoin"], using: &rng)) Moves as Traders Reprice \(pick(["Policy", "Risk", "Demand"], using: &rng))"
                case 3:
                    return "Bond Yields Shift After \(pick(["CPI", "Jobs Report", "Fed Minutes"], using: &rng)) Surprise"
                default:
                    return "\(pick(["Tech", "Healthcare", "Industrials", "Financials"], using: &rng)) Leads as Risk Appetite \(pick(["Returns", "Fades"], using: &rng))"
                }
            }()
            let summary = summaryTemplates.randomElement(using: &rng) ?? "Markets moved as investors digested new information."
            let source = sources.randomElement(using: &rng) ?? "Reuters"
            let heroSymbol = heroSymbols.randomElement(using: &rng) ?? "chart.line.uptrend.xyaxis"
            let tags = randomTags()
            
            // Random-ish recency: last ~8 hours.
            let minutesAgo = Int.random(in: 5...(8 * 60), using: &rng)
            let timestamp = now.addingTimeInterval(-Double(minutesAgo * 60))
            
            return MarketInsight(
                id: "insight_rand_\(seed)_\(idx)",
                headline: headline,
                summary: summary,
                source: source,
                timestamp: timestamp,
                impactLevel: impact,
                vibrancy: vibrancy,
                affectedAccounts: accounts,
                category: category,
                isLive: minutesAgo < 60,
                tags: tags,
                heroSymbolName: heroSymbol,
                whyItMatters: randomWhyItMatters(impact: impact, accounts: accounts),
                suggestedActions: randomSuggestedActions(for: impact)
            )
        }
    }
}

// MARK: - Seeded Randomness (Stable mock feeds)

/// Simple deterministic RNG for repeatable mock randomization.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed == 0 ? 0xDEADBEEF : seed
    }
    
    mutating func next() -> UInt64 {
        // LCG constants (Numerical Recipes)
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }
}

private func pick<T>(_ options: [T], using rng: inout SeededGenerator) -> T {
    options.randomElement(using: &rng) ?? options[0]
}

extension ScheduledEvent {
    
    /// Sample events for development and previews
    static let sampleEvents: [ScheduledEvent] = [
        ScheduledEvent(
            id: "event_001",
            title: "NVIDIA Earnings Call",
            description: "Q4 FY2026 financial results and outlook",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!
                .addingTimeInterval(16 * 3600), // 4 PM
            eventType: .earningsCall,
            expectedImpact: .high,
            relatedAccounts: [
                AffectedAccount(
                    id: "acc_001",
                    institutionName: "Fidelity",
                    accountLabel: "Tech Stocks",
                    color: Color(red: 0.4, green: 0.75, blue: 0.5)
                )
            ],
            isWatched: true
        ),
        
        ScheduledEvent(
            id: "event_002",
            title: "Fed Interest Rate Decision",
            description: "Federal Open Market Committee meeting concludes",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!
                .addingTimeInterval(14 * 3600), // 2 PM
            eventType: .fedMeeting,
            expectedImpact: .high,
            relatedAccounts: [
                AffectedAccount(
                    id: "acc_002",
                    institutionName: "Schwab",
                    accountLabel: "Bond Portfolio",
                    color: Color(red: 0.3, green: 0.6, blue: 0.9)
                )
            ],
            isWatched: true
        ),
        
        ScheduledEvent(
            id: "event_003",
            title: "Jobs Report Release",
            description: "U.S. Non-Farm Payrolls for December",
            date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!
                .addingTimeInterval(8.5 * 3600), // 8:30 AM
            eventType: .economicReport,
            expectedImpact: .medium,
            relatedAccounts: [],
            isWatched: false
        ),
        
        ScheduledEvent(
            id: "event_004",
            title: "Apple Dividend Ex-Date",
            description: "Quarterly dividend payment eligibility",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            eventType: .dividendDate,
            expectedImpact: .low,
            relatedAccounts: [
                AffectedAccount(
                    id: "acc_001",
                    institutionName: "Fidelity",
                    accountLabel: "Tech Stocks",
                    color: Color(red: 0.4, green: 0.75, blue: 0.5)
                )
            ],
            isWatched: false
        )
    ]
}
