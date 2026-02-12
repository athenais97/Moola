import SwiftUI
import UIKit

// MARK: - Market Insights Components
/// Reusable UI components for the Market Insights & Portfolio Impact Projection feature
///
/// UX Intent:
/// - Premium, immersive analytical experience
/// - Balance "Urgency" (news) with "Calm" (premium design)
/// - Visual indicators over text where possible
///
/// Foundation Compliance:
/// - Information scannable in seconds
/// - Visual hierarchy over raw density
/// - Subtle, purposeful animations only

// MARK: - Impact Tag

/// Visual indicator showing how much a news story matters to the user's holdings
/// UX: Clear, glanceable impact classification with color coding
struct ImpactTag: View {
    let level: ImpactLevel
    let style: TagStyle
    
    enum TagStyle {
        case full       // Emoji + text
        case compact    // Just emoji and abbreviated text
        case minimal    // Just emoji
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(level.emoji)
                .font(.system(size: style == .minimal ? 12 : 10))
            
            if style != .minimal {
                Text(style == .compact ? compactLabel : level.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(level.color)
            }
        }
        .padding(.horizontal, style == .minimal ? 6 : 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(level.backgroundColor)
        )
    }
    
    private var compactLabel: String {
        switch level {
        case .high: return "High"
        case .medium: return "Med"
        case .low: return "Low"
        case .general: return "General"
        }
    }
}

// MARK: - Sentiment Gauge

/// Bullish/Bearish gauge visualization for portfolio sentiment
/// UX: Subtle, premium gauge showing market mood
struct SentimentGauge: View {
    let climate: PortfolioClimate
    let size: GaugeSize
    
    enum GaugeSize {
        case small      // For compact headers
        case medium     // For detail views
        case large      // For hero display
        
        var width: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 140
            }
        }
        
        var height: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Gauge bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: size.height / 2)
                        .fill(Color(.systemGray5))
                    
                    // Filled portion
                    RoundedRectangle(cornerRadius: size.height / 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    climate.color.opacity(0.7),
                                    climate.color
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * climate.gaugeValue)
                }
            }
            .frame(width: size.width, height: size.height)
            
            // Labels (for medium and large only)
            if size != .small {
                HStack {
                    Text("Bearish")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Bullish")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: size.width)
            }
        }
    }
}

// MARK: - Portfolio Climate Header

/// High-level summary of the "Portfolio Climate" based on current news
/// UX: Answers "What's the overall market feeling for my holdings?"
struct PortfolioClimateHeader: View {
    let climate: PortfolioClimate
    let lastRefresh: String
    let isFresh: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Main climate display
            HStack(spacing: 14) {
                // Sentiment icon
                ZStack {
                    Circle()
                        .fill(climate.backgroundColor)
                        .frame(width: 48, height: 48)
                    
                    Text(climate.emoji)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(climate.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Climate")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(climate.rawValue)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Sentiment gauge
                SentimentGauge(climate: climate, size: .medium)
            }
            
            // Description and refresh indicator
            HStack {
                Text(climate.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(isFresh ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    
                    Text(isFresh ? "Live" : lastRefresh)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 6)
        )
    }
}

// MARK: - Exposure Badge

/// Pill-shaped badge showing which account is affected
/// UX: "Your Exposure" indicator linking news to specific holdings
struct ExposureBadge: View {
    let account: AffectedAccount
    let style: BadgeStyle
    
    enum BadgeStyle {
        case full       // Full label
        case compact    // Abbreviated
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(account.color)
                .frame(width: 6, height: 6)
            
            Text(style == .full ? account.displayLabel : account.accountLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(account.color)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(account.color.opacity(0.1))
        )
    }
}

// MARK: - Vibrancy Indicator

/// Non-deterministic visual indicator for potential movement
/// UX: "Heat" indicator without specific price predictions
struct VibrancyIndicator: View {
    let level: VibrancyLevel
    @State private var isAnimating: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            // Animated bars
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    VibrancyBar(
                        isActive: barIsActive(index),
                        color: level.color,
                        isAnimating: isAnimating && level == .elevated,
                        delay: Double(index) * 0.15
                    )
                }
            }
            .frame(height: 14)
            
            Text(level.rawValue)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(level.color)
        }
        .onAppear {
            if level == .elevated {
                isAnimating = true
            }
        }
    }
    
    private func barIsActive(_ index: Int) -> Bool {
        switch level {
        case .elevated: return true
        case .moderate: return index < 2
        case .calm: return index < 1
        }
    }
}

/// Individual vibrancy bar with animation
private struct VibrancyBar: View {
    let isActive: Bool
    let color: Color
    let isAnimating: Bool
    let delay: Double
    
    @State private var height: CGFloat = 4
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(isActive ? color : Color(.systemGray5))
            .frame(width: 3, height: height)
            .onAppear {
                if isAnimating {
                    withAnimation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                    ) {
                        height = 14
                    }
                } else {
                    height = isActive ? 10 : 4
                }
            }
    }
}

// MARK: - Smart Insight Card

/// Card displaying a curated market insight with personal relevance
/// UX: "What this means for you" perspective on market news
/// Upgrade: Now includes "Why it matters" guidance and optional actions
struct SmartInsightCard: View {
    let insight: MarketInsight
    let onTap: () -> Void
    var onAction: ((InsightAction) -> Void)? = nil  // Optional action handler
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Category + Impact + Live
                HStack {
                    // Category badge
                    HStack(spacing: 5) {
                        Image(systemName: insight.category.iconName)
                            .font(.system(size: 10, weight: .semibold))
                        
                        Text(insight.category.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(insight.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(insight.category.color.opacity(0.1))
                    )
                    
                    Spacer()
                    
                    // Impact tag
                    ImpactTag(level: insight.impactLevel, style: .compact)
                    
                    // Live indicator
                    if insight.isLive {
                        LiveIndicator()
                    }
                }
                
                // Headline
                Text(insight.headline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Summary
                Text(insight.summary)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // MARK: - Why It Matters (Upgrade)
                // Decision guidance: helps user answer "Does this matter to me?"
                // Neutral, supportive tone - avoids financial advice
                if let whyItMatters = insight.whyItMatters {
                    WhyItMattersView(text: whyItMatters)
                }
                
                // Your Exposure
                if !insight.affectedAccounts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("YOUR EXPOSURE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(insight.affectedAccounts) { account in
                                    ExposureBadge(account: account, style: .compact)
                                }
                            }
                        }
                    }
                }
                
                // Footer: Source + Time + Vibrancy
                HStack {
                    Text("\(insight.source) · \(insight.formattedTime)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Vibrancy indicator
                    VibrancyIndicator(level: insight.vibrancy)
                }
                
                // MARK: - Quick Actions (Upgrade)
                // Optional, light decision guidance
                // Helps user answer "What should I consider doing?"
                if !insight.suggestedActions.isEmpty, let onAction = onAction {
                    InsightQuickActions(
                        actions: insight.suggestedActions,
                        onAction: onAction
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        insight.impactLevel == .high
                            ? insight.impactLevel.color.opacity(0.2)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(CardPressStyle())
    }
}

// MARK: - Why It Matters View

/// Compact guidance section explaining personal relevance
/// UX: Neutral, supportive tone - helps without prescribing
struct WhyItMattersView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Subtle icon to draw attention without alarm
            Image(systemName: "lightbulb")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.accentColor.opacity(0.8))
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary.opacity(0.85))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.06))
        )
    }
}

// MARK: - Insight Quick Actions

/// Optional action buttons for light decision guidance
/// UX: Secondary styling, non-prescriptive - user chooses
struct InsightQuickActions: View {
    let actions: [InsightAction]
    let onAction: (InsightAction) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(actions) { action in
                Button(action: {
                    onAction(action)
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: action.iconName)
                            .font(.system(size: 11, weight: .medium))
                        
                        Text(action.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(action.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(action.color.opacity(0.1))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Live Indicator

/// Pulsing indicator showing real-time data
struct LiveIndicator: View {
    @State private var isPulsing: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
            
            Text("LIVE")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.red)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Event Timeline Item

/// Individual item in the event timeline
/// UX: Upcoming dates that may trigger portfolio changes
struct EventTimelineItem: View {
    let event: ScheduledEvent
    let onTap: () -> Void
    let onToggleWatch: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Date column
                VStack(spacing: 2) {
                    Text(event.formattedDate)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(event.isToday ? .red : .primary)
                    
                    if event.isToday {
                        Text(event.formattedTime)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 50)
                
                // Vertical connector line
                Rectangle()
                    .fill(event.eventType.color.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                
                // Event content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        // Event type icon
                        Image(systemName: event.eventType.iconName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(event.eventType.color)
                        
                        Text(event.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Impact tag
                        ImpactTag(level: event.expectedImpact, style: .minimal)
                    }
                    
                    Text(event.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Related accounts
                    if !event.relatedAccounts.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(event.relatedAccounts.prefix(2)) { account in
                                ExposureBadge(account: account, style: .compact)
                            }
                            
                            if event.relatedAccounts.count > 2 {
                                Text("+\(event.relatedAccounts.count - 2)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Watch button
                Button(action: onToggleWatch) {
                    Image(systemName: event.isWatched ? "bell.fill" : "bell")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(event.isWatched ? .accentColor : .secondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(CardPressStyle())
    }
}

// MARK: - Legal Disclaimer

/// Mandatory legal disclaimer for financial projections
/// UX: Clear but styled to fit premium aesthetic (small, centered, elegant)
struct LegalDisclaimer: View {
    let style: DisclaimerStyle
    
    enum DisclaimerStyle {
        case inline     // Small, single line
        case block      // Full block with both languages
    }
    
    var body: some View {
        Group {
            if style == .inline {
                inlineDisclaimer
            } else {
                blockDisclaimer
            }
        }
    }
    
    private var inlineDisclaimer: some View {
        Text("Past performance is not indicative of future results")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary.opacity(0.7))
            .multilineTextAlignment(.center)
    }
    
    private var blockDisclaimer: some View {
        VStack(spacing: 6) {
            Text("Past performance is not indicative of future results")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary.opacity(0.8))
            
            Text("Les performances passées ne présagent pas des performances futures")
                .font(.system(size: 10, weight: .regular, design: .default))
                .foregroundColor(.secondary.opacity(0.6))
                .italic()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Section Header

/// Styled section header for Market Insights
struct InsightsSectionHeader: View {
    let title: String
    let subtitle: String?
    let actionLabel: String?
    let onAction: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.onAction = onAction
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            Spacer()
            
            if let actionLabel = actionLabel, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// MARK: - Show All Toggle

/// Toggle between "Top 3" and all insights
struct ShowAllToggle: View {
    let showAll: Bool
    let totalCount: Int
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Text(showAll ? "Show Top 3" : "Show All (\(totalCount))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                
                Image(systemName: showAll ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.1))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Button Styles

/// Card press animation style
private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Loading Skeleton

/// Skeleton view for loading state
struct InsightCardSkeleton: View {
    @State private var shimmerOffset: CGFloat = -1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack {
                SkeletonRectangle(width: 80, height: 22)
                Spacer()
                SkeletonRectangle(width: 60, height: 22)
            }
            
            // Headline skeleton
            SkeletonRectangle(width: nil, height: 20)
            SkeletonRectangle(width: 200, height: 20)
            
            // Summary skeleton
            SkeletonRectangle(width: nil, height: 14)
            SkeletonRectangle(width: nil, height: 14)
            SkeletonRectangle(width: 150, height: 14)
            
            // Footer skeleton
            HStack {
                SkeletonRectangle(width: 120, height: 14)
                Spacer()
                SkeletonRectangle(width: 80, height: 14)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .overlay(
            shimmerOverlay
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.0
            }
        }
    }
    
    private var shimmerOverlay: some View {
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
    }
}

/// Skeleton rectangle helper
private struct SkeletonRectangle: View {
    let width: CGFloat?
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

// MARK: - Market Insights V2 (Figma)

/// Figma V2 climate card (Market Insights header block).
struct MarketInsightsClimateCardV2: View {
    let climate: PortfolioClimate
    let isFresh: Bool
    let lastRefresh: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 16) {
                MarketInsightsClimateIconV2(climate: climate)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("portfolio climate")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                        .foregroundColor(DesignSystem.Colors.inkSecondary)
                    
                    Text(climate.rawValue)
                        .font(DesignSystem.Typography.plusJakarta(.semibold, size: 24))
                        .foregroundColor(DesignSystem.Colors.ink)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
            
            HStack(alignment: .top, spacing: 12) {
                Text(climate.description)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                MarketInsightsPill(
                    text: isFresh ? "Live" : lastRefresh,
                    fill: DesignSystem.Colors.livePillFill,
                    ink: DesignSystem.Colors.livePillInk
                )
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 19)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
}

private struct MarketInsightsClimateIconV2: View {
    let climate: PortfolioClimate
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(climate.color.opacity(0.16))
                .frame(width: 66, height: 66)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(climate.color.opacity(0.22))
                    .frame(width: 40, height: 40)
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 40, height: 40)
                    .scaleEffect(0.82)
                
                Text(climate.emoji)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(climate.color)
            }
            .rotationEffect(.degrees(-45))
        }
    }
}

private struct MarketInsightsPill: View {
    let text: String
    let fill: Color
    let ink: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ink)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .lineLimit(1)
    }
}

/// Figma V2 insight article preview card.
struct MarketInsightArticleCardV2: View {
    let headline: String
    let summary: String
    let tags: [String]
    let heroSymbolName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    MarketInsightRandomImage(
                        seed: abs(headline.hashValue),
                        symbolName: heroSymbolName
                    )
                        .frame(height: 101)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headline)
                            .font(DesignSystem.Typography.plusJakarta(.bold, size: 14))
                            .foregroundColor(DesignSystem.Colors.ink)
                            .lineLimit(1)
                        
                        Text(summary)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.ink.opacity(0.80))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                }
                
                MarketInsightsTagsRow(tags: tags)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
        }
        .buttonStyle(.plain)
    }
}

/// Deterministic “random” hero image per article.
/// UX: Avoids repeating placeholders; stays offline; stable per headline.
private struct MarketInsightRandomImage: View {
    let seed: Int
    let symbolName: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: palette.map { $0.opacity(0.9) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: symbolName)
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.55))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            
            // Subtle shapes for texture (keeps calm, premium feel).
            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 120, height: 120)
                .offset(x: -90, y: -60)
            
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 160, height: 160)
                .offset(x: 110, y: 50)
            
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .frame(width: 140, height: 44)
                .rotationEffect(.degrees(-8))
                .offset(x: 20, y: 30)
        }
        .overlay(
            LinearGradient(
                colors: [Color.white.opacity(0.22), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var palette: [Color] {
        // Calm palettes, deterministic selection.
        let palettes: [[Color]] = [
            [Color(hex: "C5E2FD") ?? .blue.opacity(0.2), Color(hex: "DBCDFC") ?? .purple.opacity(0.2), Color(hex: "FBFBFB") ?? .white],
            [Color(hex: "E7F4FF") ?? .blue.opacity(0.16), Color(hex: "D7FFF1") ?? .mint.opacity(0.18), Color(hex: "FBFBFB") ?? .white],
            [Color(hex: "F0F3FF") ?? .indigo.opacity(0.14), Color(hex: "FFE6F0") ?? .pink.opacity(0.18), Color(hex: "FBFBFB") ?? .white],
            [Color(hex: "FFF0D6") ?? .yellow.opacity(0.16), Color(hex: "DCCBFF") ?? .purple.opacity(0.2), Color(hex: "FBFBFB") ?? .white]
        ]
        let idx = abs(seed) % palettes.count
        return palettes[idx]
    }
}

private struct MarketInsightsTagsRow: View {
    let tags: [String]
    
    var body: some View {
        let shown = Array(tags.prefix(2))
        let remaining = max(0, tags.count - shown.count)
        
        return HStack(spacing: 8) {
            ForEach(shown, id: \.self) { tag in
                MarketInsightsTagPill(tag: tag)
            }
            
            if remaining > 0 {
                MarketInsightsMorePill(text: "+\(remaining) more")
            }
        }
    }
}

private struct MarketInsightsTagPill: View {
    let tag: String
    
    var body: some View {
        let style = styleForTag(tag)
        
        return Text(tag)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(style.ink)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(style.fill)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .lineLimit(1)
    }
    
    private func styleForTag(_ tag: String) -> (fill: Color, ink: Color) {
        let key = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if key.contains("tech") {
            return (DesignSystem.Colors.chipTechFill, DesignSystem.Colors.chipTechInk)
        }
        if key.contains("bond") {
            return (DesignSystem.Colors.chipBondFill, DesignSystem.Colors.chipBondInk)
        }
        if key == "us" {
            return (DesignSystem.Colors.chipUSFill, DesignSystem.Colors.chipUSInk)
        }
        return (DesignSystem.Colors.inputBackground, DesignSystem.Colors.inkSecondary)
    }
}

private struct MarketInsightsMorePill: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(DesignSystem.Colors.chipMoreInk)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(DesignSystem.Colors.chipMoreFill)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
            .lineLimit(1)
    }
}

/// Figma V2 locked card (Standard users).
struct MarketInsightLockedCardV2: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 13) {
                Text("Join Infinite to get access")
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: 16))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                
                lockedInnerCard
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Gradients.chatAccent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
        }
        .buttonStyle(.plain)
    }
    
    private var lockedInnerCard: some View {
        // IMPORTANT: Use an explicit blur on the content so the "hidden"
        // card remains visible behind a frosted overlay (matches Figma better
        // than relying purely on UIVisualEffectView on a white background).
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
            
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    MarketInsightRandomImage(seed: 42, symbolName: "chart.line.uptrend.xyaxis")
                        .frame(height: 101)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Federal bank is closing +100 account from 12 banks")
                            .font(DesignSystem.Typography.plusJakarta(.bold, size: 14))
                            .foregroundColor(DesignSystem.Colors.ink)
                            .lineLimit(1)
                        
                        Text("This sat. 9, the Federal Bank of America decided to close")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.ink.opacity(0.80))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                }
                
                HStack(spacing: 8) {
                    MarketInsightsTagPill(tag: "US")
                    MarketInsightsTagPill(tag: "Bond Portfolio")
                    MarketInsightsMorePill(text: "+6 more")
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
            .blur(radius: 14)
        }
        .overlay {
            // Frosted glass layer.
            Color.white
                .opacity(0.22)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .allowsHitTesting(false)
        }
    }
}

/// Figma V2 watchlist row.
struct WatchlistEventRowV2: View {
    let event: ScheduledEvent
    let onTap: () -> Void
    let onToggleWatch: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(event.formattedDate.uppercased()) - \(event.title)")
                            .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                            .foregroundColor(DesignSystem.Colors.ink)
                            .lineLimit(1)
                        
                        Text(event.description)
                            .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                            .foregroundColor(DesignSystem.Colors.inkSecondary)
                            .lineLimit(1)
                    }
                    
                    MarketInsightsTagsRow(tags: event.relatedAccounts.map(\.accountLabel))
                }
                
                Spacer(minLength: 0)
                
                Button(action: onToggleWatch) {
                    Image(systemName: event.isWatched ? "bell.fill" : "bell")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.inkSecondary)
                        .frame(width: 57, height: 57)
                        .background(Color.white.opacity(0.80))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(
                            color: DesignSystem.Shadow.softColor,
                            radius: DesignSystem.Shadow.softRadius,
                            x: DesignSystem.Shadow.softX,
                            y: DesignSystem.Shadow.softY
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 1)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
        }
        .buttonStyle(.plain)
    }
}

/// UIKit blur wrapper to match Figma's frosted overlay.
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Previews

#Preview("Impact Tags") {
    VStack(spacing: 16) {
        ForEach(ImpactLevel.allCases, id: \.rawValue) { level in
            HStack(spacing: 12) {
                ImpactTag(level: level, style: .full)
                ImpactTag(level: level, style: .compact)
                ImpactTag(level: level, style: .minimal)
            }
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Sentiment Gauges") {
    VStack(spacing: 24) {
        ForEach(PortfolioClimate.allCases, id: \.rawValue) { climate in
            HStack {
                Text(climate.rawValue)
                    .font(.system(size: 14))
                    .frame(width: 100, alignment: .leading)
                
                SentimentGauge(climate: climate, size: .medium)
            }
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Portfolio Climate Header") {
    VStack {
        PortfolioClimateHeader(
            climate: .bullish,
            lastRefresh: "2 min ago",
            isFresh: true
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Smart Insight Card") {
    SmartInsightCard(
        insight: MarketInsight.sampleInsights[0],
        onTap: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Event Timeline Item") {
    VStack(spacing: 12) {
        EventTimelineItem(
            event: ScheduledEvent.sampleEvents[0],
            onTap: {},
            onToggleWatch: {}
        )
        
        EventTimelineItem(
            event: ScheduledEvent.sampleEvents[1],
            onTap: {},
            onToggleWatch: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Legal Disclaimer") {
    VStack(spacing: 32) {
        LegalDisclaimer(style: .inline)
        
        Divider()
        
        LegalDisclaimer(style: .block)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Loading Skeleton") {
    VStack(spacing: 16) {
        InsightCardSkeleton()
        InsightCardSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
