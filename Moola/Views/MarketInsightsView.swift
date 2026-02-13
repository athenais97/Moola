import SwiftUI

// MARK: - Market Insights View
/// "Forward Analysis" / "Market Impact" dashboard view
///
/// UX Intent:
/// - Immersive, analytical dashboard for curated news and events
/// - Each insight linked to specific accounts/assets (What this means for YOU)
/// - Balance "Urgency" (news) with "Calm" (premium design)
///
/// Foundation Compliance:
/// - Mobile-first: Thumb-friendly, scannable in seconds
/// - One clear intent per section: Climate → Insights → Events
/// - Progressive disclosure: Top 3 by default, expand on demand
/// - Visual hierarchy over raw density
/// - Information must have context and meaning
///
/// Information Hierarchy:
/// 1. Portfolio Climate Header - Overall sentiment for holdings
/// 2. Impact Feed - "Smart Insight Cards" with personal relevance
/// 3. Future Calendar - Upcoming events watchlist
/// 4. Legal Disclaimer - Always visible at bottom
struct MarketInsightsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @StateObject private var viewModel = MarketInsightsViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showInsightsPaywall: Bool = false
    
    /// When used as a root tab, we shouldn't show a "close" control.
    private let showsCloseButton: Bool
    
    init(showsCloseButton: Bool = true) {
        self.showsCloseButton = showsCloseButton
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.backgroundCanvas
                    .ignoresSafeArea()
                
                // Main content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.displayedInsights.isEmpty {
                    emptyStateView
                } else {
                    mainContent
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.ink)
                            .frame(width: 24, height: 24)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Market Insights")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.ink)
                }
            }
            .sheet(isPresented: $viewModel.showInsightDetail) {
                if let insight = viewModel.selectedInsight {
                    InsightDetailSheet(
                        insight: insight,
                        onDismiss: { viewModel.closeInsightDetail() }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $viewModel.showEventDetail) {
                if let event = viewModel.selectedEvent {
                    EventDetailSheet(
                        event: event,
                        onDismiss: { viewModel.closeEventDetail() },
                        onToggleWatch: { viewModel.toggleWatchEvent(event) }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showInsightsPaywall) {
                InsightsPaywallSheet(
                    onStartTrial: {
                        // Hook up to purchase flow when available.
                        showInsightsPaywall = false
                    },
                    onDismiss: {
                        showInsightsPaywall = false
                    }
                )
            }
        }
        .task {
            await viewModel.fetchInsights()
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                MarketInsightsClimateCardV2(
                    climate: viewModel.climate,
                    isFresh: viewModel.isFresh,
                    lastRefresh: viewModel.lastRefreshFormatted
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                topInsightsSectionV2
                    .padding(.top, 37)
                
                watchlistSectionV2
                    .padding(.top, 28)
                
                // Keep disclaimer in the product, but visually low-noise.
                LegalDisclaimer(style: .inline)
                    .padding(.top, 22)
                    .padding(.bottom, 14)
                
                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - V2 Sections (Figma)
    
    private var topInsightsSectionV2: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Top Insights For Your Portfolio")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
                .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                if let insight = viewModel.topInsights.first {
                    MarketInsightArticleCardV2(
                        headline: insight.headline,
                        summary: insight.summary,
                        tags: insight.tags,
                        heroSymbolName: insight.heroSymbolName,
                        onTap: { viewModel.openInsightDetail(insight) }
                    )
                }
                
                if hasInsightsAccess {
                    ForEach(Array(viewModel.topInsights.dropFirst().prefix(2))) { insight in
                        MarketInsightArticleCardV2(
                            headline: insight.headline,
                            summary: insight.summary,
                            tags: insight.tags,
                            heroSymbolName: insight.heroSymbolName,
                            onTap: { viewModel.openInsightDetail(insight) }
                        )
                    }
                } else {
                    MarketInsightLockedCardV2(onTap: { showInsightsPaywall = true })
                    MarketInsightLockedCardV2(onTap: { showInsightsPaywall = true })
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var watchlistSectionV2: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Watchlist of dates affecting your portfolio")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(DesignSystem.Colors.inkSectionHeader)
                .padding(.horizontal, 16)
            
            VStack(spacing: 15) {
                ForEach(viewModel.upcomingEvents.prefix(3)) { event in
                    WatchlistEventRowV2(
                        event: event,
                        onTap: {
                            viewModel.timelineInteractionHaptic()
                            viewModel.openEventDetail(event)
                        },
                        onToggleWatch: {
                            viewModel.toggleWatchEvent(event)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var hasInsightsAccess: Bool {
        // Prefer real entitlement state if available.
        // Falls back to the local membership flag.
        if subscriptions.isPro { return true }
        let level = appState.currentUser?.membershipLevel ?? .standard
        return level != .standard
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Skeleton header
                SkeletonClimateHeader()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Skeleton cards
                VStack(spacing: 14) {
                    InsightCardSkeleton()
                    InsightCardSkeleton()
                    InsightCardSkeleton()
                }
                .padding(.horizontal, 16)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.1),
                                Color.purple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.line.text.clipboard")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.accentColor)
            }
            
            // Message
            VStack(spacing: 8) {
                Text("No Market Insights")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Connect accounts to see personalized\nmarket insights for your portfolio.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
            
            // Disclaimer still visible
            LegalDisclaimer(style: .inline)
                .padding(.bottom, 32)
        }
    }
    
    // (Toolbar migrated to Figma V2 above.)
}

// MARK: - Skeleton Climate Header

/// Loading skeleton for the climate header
private struct SkeletonClimateHeader: View {
    @State private var shimmerOffset: CGFloat = -1.0
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                // Icon skeleton
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 22)
                }
                
                Spacer()
                
                // Gauge skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 8)
            }
            
            // Description skeleton
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 14)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 4)
        )
        .overlay(
            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: UnitPoint(x: shimmerOffset - 0.3, y: 0.5),
                            endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.0
            }
        }
    }
}

// MARK: - Insight Detail Sheet

/// Bottom sheet with full analysis of an insight
/// UX: "Deep Dive" into the affected assets
/// Upgrade: Now includes decision guidance, personal context, and lightweight feedback
///
/// Engagement Improvements:
/// - Personal context line answers "Why am I seeing this?"
/// - Lightweight feedback gives user agency without blocking dismissal
/// - Reading indicator sets expectations and respects attention
struct InsightDetailSheet: View {
    let insight: MarketInsight
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Personal Context Line (Engagement Upgrade)
                    // UX: Answers "Why am I seeing this?" - makes insight feel curated for the user
                    // Reassuring, warm tone - not algorithmic or cold
                    if !insight.affectedAccounts.isEmpty {
                        PersonalContextBanner(accounts: insight.affectedAccounts)
                    }
                    
                    // Header with category and impact
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: insight.category.iconName)
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text(insight.category.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(insight.category.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(insight.category.color.opacity(0.1))
                        )
                        
                        Spacer()
                        
                        // Reading indicator - sets expectations, respects attention
                        ReadingTimeIndicator()
                        
                        ImpactTag(level: insight.impactLevel, style: .full)
                        
                        if insight.isLive {
                            LiveIndicator()
                        }
                    }
                    
                    // Headline
                    Text(insight.headline)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Source and time
                    HStack(spacing: 8) {
                        Text(insight.source)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("·")
                            .foregroundColor(.secondary)
                        
                        Text(insight.formattedTime)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Full summary
                    Text(insight.summary)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                    
                    // MARK: - Why This Matters (Upgrade)
                    // Decision guidance section - helps user understand personal relevance
                    // UX: Neutral, supportive - avoids financial advice
                    if let whyItMatters = insight.whyItMatters {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHY THIS MATTERS TO YOU")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.accentColor)
                                
                                Text(whyItMatters)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.08))
                            )
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Insight Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Personal Context Banner

/// Warm, brief explanation of why the user is seeing this insight
/// UX: Makes the insight feel curated and personal, not random
/// Tone: Reassuring, human - "We're showing you this because..."
private struct PersonalContextBanner: View {
    let accounts: [AffectedAccount]
    
    var body: some View {
        HStack(spacing: 10) {
            // Subtle personalization icon
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor.opacity(0.8))
            
            Text(contextText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.05))
        )
    }
    
    /// Generate contextual text based on affected accounts
    /// UX: Brief, warm, personal - answers "Why am I seeing this?"
    private var contextText: String {
        if accounts.count == 1 {
            return "Showing because you hold \(accounts[0].accountLabel)"
        } else if accounts.count == 2 {
            return "Relates to your \(accounts[0].accountLabel) and \(accounts[1].accountLabel)"
        } else {
            return "Relates to \(accounts.count) of your accounts"
        }
    }
}

// MARK: - Reading Time Indicator

/// Subtle indicator showing this is a quick read
/// UX: Sets expectations, respects attention, reduces cognitive load
private struct ReadingTimeIndicator: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 10, weight: .medium))
            
            Text("Quick read")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.secondary.opacity(0.7))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Insight Feedback Row

/// Lightweight, non-blocking feedback mechanism
/// UX: "I'm in control" - user can signal preference without disruption
/// Does NOT require input to dismiss - feedback is optional
private struct InsightFeedbackRow: View {
    @Binding var feedbackGiven: InsightFeedback?
    let onFeedback: (InsightFeedback) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Divider with label
            HStack {
                Rectangle()
                    .fill(Color(.separator).opacity(0.3))
                    .frame(height: 1)
                
                Text("Was this helpful?")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
                
                Rectangle()
                    .fill(Color(.separator).opacity(0.3))
                    .frame(height: 1)
            }
            
            // Feedback buttons or confirmation
            if let feedback = feedbackGiven {
                // Show gentle confirmation after feedback
                FeedbackConfirmation(feedback: feedback)
            } else {
                // Show feedback buttons
                HStack(spacing: 16) {
                    ForEach(InsightFeedback.allCases, id: \.rawValue) { feedback in
                        FeedbackButton(feedback: feedback) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                onFeedback(feedback)
                            }
                            
                            // Subtle haptic
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred(intensity: 0.5)
                        }
                    }
                }
            }
        }
    }
}

/// Individual feedback button
private struct FeedbackButton: View {
    let feedback: InsightFeedback
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: feedback.iconName)
                    .font(.system(size: 13, weight: .medium))
                
                Text(feedback.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Gentle confirmation shown after feedback
private struct FeedbackConfirmation: View {
    let feedback: InsightFeedback
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: feedback.selectedIconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(feedback == .helpful ? .accentColor : .secondary)
            
            Text(confirmationText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var confirmationText: String {
        switch feedback {
        case .helpful:
            return "Thanks! We'll show more like this."
        case .notRelevant:
            return "Got it. We'll adjust your feed."
        }
    }
}

// MARK: - Event Detail Sheet

/// Bottom sheet with event details
struct EventDetailSheet: View {
    let event: ScheduledEvent
    let onDismiss: () -> Void
    let onToggleWatch: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event type badge
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: event.eventType.iconName)
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text(event.eventType.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(event.eventType.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(event.eventType.color.opacity(0.1))
                        )
                        
                        Spacer()
                        
                        ImpactTag(level: event.expectedImpact, style: .full)
                    }
                    
                    // Title
                    Text(event.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Date and time
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(event.formattedDate)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(event.isToday ? .red : .primary)
                        
                        if event.isToday {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(event.formattedTime)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        if event.daysUntil > 0 {
                            Text("in \(event.daysUntil) day\(event.daysUntil == 1 ? "" : "s")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    Text(event.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                    
                    // Related accounts
                    if !event.relatedAccounts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RELATED ACCOUNTS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            ForEach(event.relatedAccounts) { account in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(account.color)
                                        .frame(width: 10, height: 10)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.institutionName)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text(account.accountLabel)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Watch button
                    Button(action: onToggleWatch) {
                        HStack {
                            Image(systemName: event.isWatched ? "bell.fill" : "bell")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(event.isWatched ? "Remove from Watchlist" : "Add to Watchlist")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(event.isWatched ? .secondary : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(event.isWatched ? Color(.secondarySystemGroupedBackground) : Color.accentColor)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 16)
                    
                    // Disclaimer
                    LegalDisclaimer(style: .inline)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
                .padding(20)
            }
            .navigationTitle("Event Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Market Insights - Full") {
    let appState = AppState()
    appState.currentUser = UserModel(
        name: "Sarah Johnson",
        age: 32,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: "",
        membershipLevel: .premium
    )
    
    return MarketInsightsView()
        .environmentObject(appState)
}

#Preview("Market Insights - Dark Mode") {
    let appState = AppState()
    appState.currentUser = UserModel(
        name: "Sarah Johnson",
        age: 32,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: "",
        membershipLevel: .premium
    )
    
    return MarketInsightsView()
        .environmentObject(appState)
        .preferredColorScheme(.dark)
}

#Preview("Insight Detail Sheet") {
    InsightDetailSheet(
        insight: MarketInsight.sampleInsights[0],
        onDismiss: {}
    )
}

#Preview("Event Detail Sheet") {
    EventDetailSheet(
        event: ScheduledEvent.sampleEvents[0],
        onDismiss: {},
        onToggleWatch: {}
    )
}
