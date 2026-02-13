import Foundation
import SwiftUI

// MARK: - Market Insights ViewModel

/// ViewModel for the Market Insights & Portfolio Impact Projection feature
///
/// UX Intent:
/// - Manage curated news and events linked to user's portfolio
/// - Implement "Top 3 for You" algorithm to prevent cognitive overload
/// - Handle real-time data refresh with proper loading states
///
/// Foundation Compliance:
/// - Fast, fluid, intentional data updates
/// - Clear feedback on loading and refresh states
/// - Privacy-aware data handling
@MainActor
final class MarketInsightsViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var state: MarketInsightsState = .empty
    @Published var selectedInsight: MarketInsight? = nil
    @Published var showInsightDetail: Bool = false
    @Published var showEventDetail: Bool = false
    @Published var selectedEvent: ScheduledEvent? = nil
    
    // MARK: - Computed Properties
    
    var climate: PortfolioClimate {
        state.climate
    }
    
    var displayedInsights: [MarketInsight] {
        state.displayedInsights
    }
    
    var topInsights: [MarketInsight] {
        state.topInsights
    }
    
    var allInsights: [MarketInsight] {
        state.insights.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    var upcomingEvents: [ScheduledEvent] {
        state.upcomingEvents
    }
    
    var thisWeekEvents: [ScheduledEvent] {
        state.thisWeekEvents
    }
    
    var isLoading: Bool {
        state.isLoading
    }
    
    var showAllInsights: Bool {
        state.showAllInsights
    }
    
    var isFresh: Bool {
        state.isFresh
    }
    
    var lastRefreshFormatted: String {
        state.lastRefreshFormatted
    }
    
    /// Count of insights the user hasn't seen
    var unreadCount: Int {
        // In production: track read state per insight
        displayedInsights.filter { $0.isLive }.count
    }
    
    /// Whether there are high-impact insights
    var hasHighImpactInsights: Bool {
        displayedInsights.contains { $0.impactLevel == .high }
    }
    
    /// Count of high-impact events this week
    var urgentEventsCount: Int {
        thisWeekEvents.filter { $0.expectedImpact == .high }.count
    }
    
    // MARK: - Actions
    
    /// Fetch initial market insights data
    func fetchInsights() async {
        state.isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        // Load randomized finance mock data (in production: fetch from API)
        state.insights = MarketInsight.randomizedFinanceInsights(
            count: 10,
            seed: UInt64(Date().timeIntervalSince1970)
        )
        state.events = ScheduledEvent.sampleEvents
        state.climate = calculateClimate()
        state.lastRefresh = Date()
        state.isLoading = false
    }
    
    /// Refresh data (pull-to-refresh)
    func refresh() async {
        // Soft loading - don't clear existing data
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Update with fresh data
        state.insights = MarketInsight.randomizedFinanceInsights(
            count: 10,
            seed: UInt64(Date().timeIntervalSince1970)
        )
        state.events = ScheduledEvent.sampleEvents
        state.climate = calculateClimate()
        state.lastRefresh = Date()
    }
    
    /// Toggle between "Top 3" and all insights
    func toggleShowAllInsights() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            state.showAllInsights.toggle()
        }
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Open insight detail sheet
    func openInsightDetail(_ insight: MarketInsight) {
        selectedInsight = insight
        showInsightDetail = true
        
        // Soft pulse haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
    }
    
    /// Close insight detail sheet
    func closeInsightDetail() {
        showInsightDetail = false
        selectedInsight = nil
    }
    
    /// Open event detail
    func openEventDetail(_ event: ScheduledEvent) {
        selectedEvent = event
        showEventDetail = true
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
    }
    
    /// Close event detail
    func closeEventDetail() {
        showEventDetail = false
        selectedEvent = nil
    }
    
    /// Toggle watch status for an event
    func toggleWatchEvent(_ event: ScheduledEvent) {
        if let index = state.events.firstIndex(where: { $0.id == event.id }) {
            var updatedEvent = state.events[index]
            updatedEvent = ScheduledEvent(
                id: updatedEvent.id,
                title: updatedEvent.title,
                description: updatedEvent.description,
                date: updatedEvent.date,
                eventType: updatedEvent.eventType,
                expectedImpact: updatedEvent.expectedImpact,
                relatedAccounts: updatedEvent.relatedAccounts,
                isWatched: !updatedEvent.isWatched
            )
            state.events[index] = updatedEvent
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(updatedEvent.isWatched ? .success : .warning)
        }
    }
    
    /// Provide timeline interaction haptic
    func timelineInteractionHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.5)
    }
    
    // MARK: - Insight Action Handlers (Upgrade)
    // Light, optional decision guidance actions
    // UX: Help users answer "What should I consider doing?"
    
    /// Handle an insight action (Review, Set Alert, Ignore)
    /// Intent: Non-prescriptive guidance - user decides next step
    func handleInsightAction(_ action: InsightAction, for insight: MarketInsight) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
        
        switch action {
        case .review:
            // Open detail sheet to review affected holdings
            // UX: "Review" helps user see their exposure without prescribing action
            openInsightDetail(insight)
            
        case .setAlert:
            // Toggle alert for this insight's topic
            // In production: persist alert preference and set up notifications
            toggleAlertForInsight(insight)
            
        case .ignore:
            // Remove from displayed insights (soft dismiss)
            // UX: Respects user agency - they decide what matters
            dismissInsight(insight)
        }
    }
    
    /// Toggle alert notification for an insight topic
    /// Intent: User can opt-in to updates without being pushed
    func toggleAlertForInsight(_ insight: MarketInsight) {
        // In production: update user preferences, register for push notifications
        // For now: provide feedback that alert was set
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Future: Track alert state per insight category/topic
        // state.alertedTopics.toggle(insight.category)
    }
    
    /// Soft dismiss an insight from the user's feed
    /// UX: "Ignore" is non-destructive - can be undone
    func dismissInsight(_ insight: MarketInsight) {
        withAnimation(.easeOut(duration: 0.25)) {
            state.insights.removeAll { $0.id == insight.id }
        }
        
        // Subtle haptic for dismissal
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.4)
    }
    
    // MARK: - Insight Feedback Handler (Engagement Upgrade)
    // Lightweight feedback mechanism - user signals relevance
    // UX: "I'm in control" - non-blocking, optional feedback
    
    /// Handle user feedback on insight relevance
    /// Intent: Improve future recommendations without disrupting flow
    /// This is lightweight and non-blocking - user can dismiss anytime
    func handleInsightFeedback(_ feedback: InsightFeedback, for insight: MarketInsight) {
        // In production: persist feedback to improve recommendation algorithm
        // Track: (insightId, category, feedback, timestamp)
        
        // Log feedback for analytics (future: send to backend)
        print("[Insight Feedback] \(feedback.rawValue) for insight: \(insight.id)")
        
        // Future enhancements:
        // - Adjust relevance scoring based on feedback patterns
        // - Learn user preferences per category
        // - Personalize "Top 3 for You" algorithm
        
        // Note: No haptic here - the feedback button already provides it
    }
    
    // MARK: - Private Methods
    
    /// Calculate overall portfolio climate based on insights
    private func calculateClimate() -> PortfolioClimate {
        guard !state.insights.isEmpty else { return .neutral }
        
        // Weight high-impact insights more heavily
        var score: Double = 50 // Start neutral
        
        for insight in state.insights.filter({ $0.impactLevel != .general }) {
            let impactWeight: Double = {
                switch insight.impactLevel {
                case .high: return 15
                case .medium: return 8
                case .low: return 3
                case .general: return 0
                }
            }()
            
            // Positive vibrancy in certain categories suggests bullish
            let vibrancyModifier: Double = {
                switch (insight.category, insight.vibrancy) {
                case (.earnings, .elevated), (.earnings, .moderate):
                    return impactWeight * 0.8  // Earnings news is usually positive
                case (.interestRates, _) where insight.headline.lowercased().contains("cut"):
                    return impactWeight * 1.0  // Rate cuts are bullish
                case (.interestRates, _) where insight.headline.lowercased().contains("hike"):
                    return -impactWeight * 0.8  // Rate hikes are bearish
                case (.crypto, .elevated):
                    return impactWeight * 0.5
                case (.geopolitical, .elevated):
                    return -impactWeight * 0.6  // Geopolitical tension is concerning
                default:
                    return impactWeight * 0.3
                }
            }()
            
            score += vibrancyModifier
        }
        
        // Clamp and convert to climate
        score = max(0, min(100, score))
        
        switch score {
        case 0..<25: return .veryBearish
        case 25..<40: return .bearish
        case 40..<60: return .neutral
        case 60..<80: return .bullish
        default: return .veryBullish
        }
    }
    
    /// Filter insights by account exposure
    func insightsForAccount(_ accountId: String) -> [MarketInsight] {
        state.insights.filter { insight in
            insight.affectedAccounts.contains { $0.id == accountId }
        }
    }
    
    /// Get events for a specific date range
    func events(from startDate: Date, to endDate: Date) -> [ScheduledEvent] {
        state.events.filter { event in
            event.date >= startDate && event.date <= endDate
        }
    }
    
    // MARK: - Sample Data Loading (Development)
    
    func loadSampleData() {
        state.insights = MarketInsight.sampleInsights
        state.events = ScheduledEvent.sampleEvents
        state.climate = calculateClimate()
        state.lastRefresh = Date()
        state.isLoading = false
    }
}

// MARK: - Preview Helpers

extension MarketInsightsViewModel {
    
    /// Create a preview instance with sample data
    static var preview: MarketInsightsViewModel {
        let viewModel = MarketInsightsViewModel()
        viewModel.loadSampleData()
        return viewModel
    }
    
    /// Create a preview instance in loading state
    static var previewLoading: MarketInsightsViewModel {
        let viewModel = MarketInsightsViewModel()
        viewModel.state.isLoading = true
        return viewModel
    }
    
    /// Create a preview instance with no data
    static var previewEmpty: MarketInsightsViewModel {
        let viewModel = MarketInsightsViewModel()
        viewModel.state = MarketInsightsState(
            climate: .neutral,
            insights: [],
            events: [],
            lastRefresh: Date(),
            isLoading: false,
            showAllInsights: false
        )
        return viewModel
    }
}
