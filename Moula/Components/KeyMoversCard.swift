import SwiftUI

/// Key Movers insight cards showing top contributors to performance
///
/// UX Intent:
/// - Answer "Which accounts contributed most to my gains/losses?"
/// - Scannable at a glance with clear visual hierarchy
/// - Progressive disclosure: summary visible, detail on tap
///
/// UX Enhancement: Added explanatory subtitle to help users understand
/// what the section shows and how to interpret the contribution percentages.
///
/// Foundation Compliance:
/// - Information scannable in seconds
/// - Visual hierarchy over raw density
/// - Context and meaning, not just numbers
struct KeyMoversSection: View {
    let movers: [AccountPerformance]
    let timeframe: PerformanceTimeframe
    let isPositive: Bool
    
    /// Explanatory subtitle describing what Key Movers represents
    /// UX: Helps users understand they're seeing contribution attribution
    private var sectionSubtitle: String {
        if movers.isEmpty {
            return "No significant account-level changes"
        }
        let direction = isPositive ? "gains" : "losses"
        return "Accounts that contributed most to your \(direction)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with explanatory context
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("KEY MOVERS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeframe.accessibilityLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Explanatory subtitle - helps users understand what they're seeing
                Text(sectionSubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            // Mover cards
            if movers.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(movers.prefix(3).enumerated()), id: \.element.id) { index, mover in
                        KeyMoverRow(mover: mover, rank: index + 1, isPositive: isPositive)
                        
                        if index < min(movers.count - 1, 2) {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No significant movers")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Portfolio changes were balanced across accounts")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Key Mover Row

/// Individual mover row showing account contribution with explanatory context
/// UX Enhancement: Added contextual description that explains the contribution
/// in plain language (e.g., "Contributed 65% of gains")
struct KeyMoverRow: View {
    let mover: AccountPerformance
    let rank: Int
    let isPositive: Bool
    
    /// Human-readable description of this account's contribution
    /// UX: Helps users understand what the percentage means in context
    private var contributionDescription: String {
        let percent = mover.formattedPercentageOfTotal
        let direction = isPositive ? "gains" : "losses"
        return "Contributed \(percent) of \(direction)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator
            ZStack {
                Circle()
                    .fill(mover.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: mover.accountType.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(mover.color)
            }
            
            // Account info with contextual contribution description
            VStack(alignment: .leading, spacing: 2) {
                Text(mover.accountName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Replaced raw institution name with contribution context
                // This directly answers "how much did this account contribute?"
                Text(contributionDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Contribution amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(mover.formattedContribution)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(mover.color)
                
                // Institution name moved here as secondary info
                Text(mover.institutionName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Compact Key Movers

/// Compact horizontal scroll version for space-constrained layouts
struct CompactKeyMovers: View {
    let movers: [AccountPerformance]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(movers.prefix(3)) { mover in
                    CompactMoverCard(mover: mover)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

/// Compact card for horizontal layout
private struct CompactMoverCard: View {
    let mover: AccountPerformance
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and name
            HStack(spacing: 8) {
                Image(systemName: mover.accountType.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(mover.color)
                
                Text(mover.accountName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Contribution
            Text(mover.formattedContribution)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(mover.color)
            
            // Institution
            Text(mover.institutionName)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(minWidth: 140)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Performance Insight Card

/// A simple text card that explains the performance change in plain language
/// UX Intent: Answer "What changed?" and "Why did it change?" with human-readable text
/// rather than requiring users to interpret numbers themselves.
///
/// Design Rationale: Uses explanatory text over visuals to reduce cognitive load
/// and provide immediate understanding. The insight summary and driver explanation
/// work together to create a narrative that helps users understand their portfolio.
struct PerformanceInsightCard: View {
    /// Main summary explaining what happened (e.g., "Your portfolio grew modestly this week.")
    let insightSummary: String
    
    /// Optional explanation of why (e.g., "Your Investment Portfolio drove most of the gains.")
    let driverExplanation: String?
    
    /// Whether the overall change was positive, neutral, or negative
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with subtle icon
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange.opacity(0.8))
                
                Text("INSIGHT")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            // Insight content - plain language explanation
            VStack(alignment: .leading, spacing: 8) {
                // Primary insight: What changed?
                Text(insightSummary)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Secondary insight: Why did it change?
                // Only shown when we have meaningful attribution
                if let driver = driverExplanation {
                    Text(driver)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Performance Delta Header

/// Header showing the overall performance delta with contextual interpretation
/// Used at the top of the Performance view
///
/// UX Enhancement: Added contextLabel parameter to provide users with a quick,
/// human-readable assessment of their performance (e.g., "Solid growth", "Minor dip").
/// This helps users understand whether their performance is good or bad in context,
/// without requiring them to interpret percentage values themselves.
struct PerformanceDeltaHeader: View {
    let balance: String
    let absoluteChange: String
    let percentageChange: String
    let isPositive: Bool
    let scrubDate: String?
    let showDelta: Bool
    
    /// Optional contextual label providing a plain-language assessment
    /// Examples: "Solid growth", "Minor pullback", "Steady gains"
    var contextLabel: String? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            // Date label (shown during scrub)
            if let date = scrubDate {
                Text(date)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            
            // Main balance
            Text(balance)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            
            // Delta indicator with context
            if showDelta {
                VStack(spacing: 6) {
                    deltaIndicator
                    
                    // Context label - provides interpretability
                    // Helps users understand "is this good or bad?" at a glance
                    if let label = contextLabel {
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: scrubDate != nil)
        .animation(.easeInOut(duration: 0.2), value: showDelta)
    }
    
    private var deltaIndicator: some View {
        HStack(spacing: 6) {
            // Direction arrow
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(trendColor)
            
            // Absolute change
            Text(absoluteChange)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(trendColor)
            
            // Divider
            Text("|")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.5))
            
            // Percentage change
            Text(percentageChange)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(trendColor.opacity(0.9))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(trendColor.opacity(0.12))
        )
    }
    
    private var trendColor: Color {
        isPositive
            ? Color(red: 0.2, green: 0.7, blue: 0.4)
            : Color(red: 0.95, green: 0.5, blue: 0.45)
    }
}

// MARK: - Preview

#Preview("Key Movers Section") {
    VStack {
        KeyMoversSection(
            movers: AccountPerformance.sampleMovers,
            timeframe: .week,
            isPositive: true
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Key Movers - Empty") {
    VStack {
        KeyMoversSection(
            movers: [],
            timeframe: .week,
            isPositive: true
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Movers") {
    VStack {
        CompactKeyMovers(movers: AccountPerformance.sampleMovers)
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}

#Preview("Performance Header - Positive with Context") {
    VStack {
        PerformanceDeltaHeader(
            balance: "$127,450.32",
            absoluteChange: "+$2,850.50",
            percentageChange: "+2.3%",
            isPositive: true,
            scrubDate: nil,
            showDelta: true,
            contextLabel: "Solid growth"
        )
        .padding()
    }
    .background(Color(.systemBackground))
}

#Preview("Performance Header - Negative with Context") {
    VStack {
        PerformanceDeltaHeader(
            balance: "$124,599.82",
            absoluteChange: "-$1,240.00",
            percentageChange: "-1.0%",
            isPositive: false,
            scrubDate: nil,
            showDelta: true,
            contextLabel: "Minor pullback"
        )
        .padding()
    }
    .background(Color(.systemBackground))
}

#Preview("Performance Header - Scrubbing") {
    VStack {
        PerformanceDeltaHeader(
            balance: "$125,840.15",
            absoluteChange: "+$2,850.50",
            percentageChange: "+2.3%",
            isPositive: true,
            scrubDate: "Mon, Jan 20",
            showDelta: false
        )
        .padding()
    }
    .background(Color(.systemBackground))
}

#Preview("Performance Insight Card") {
    VStack(spacing: 16) {
        PerformanceInsightCard(
            insightSummary: "Your portfolio grew modestly this week.",
            driverExplanation: "Your Investment Portfolio drove most of the gains.",
            isPositive: true
        )
        
        PerformanceInsightCard(
            insightSummary: "Your portfolio declined slightly this month.",
            driverExplanation: "Changes were spread across multiple accounts.",
            isPositive: false
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
