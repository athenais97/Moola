import SwiftUI

/// Insights view - your personalized financial intelligence hub
/// Repositioned from "Analysis" to emphasize personal relevance and actionable understanding
///
/// UX Intent:
/// - Smarter: Surfaces what matters TO YOU, not just raw data
/// - More personalized: Connects market events to YOUR holdings
/// - More premium: Calm, curated experience vs. data dump
///
/// Content Hierarchy (upgraded):
/// 1. Market Insights impacting YOU (primary)
/// 2. Portfolio exposure explanations (context)
/// 3. Deep metrics (secondary, on-demand)
///
/// Foundation Compliance:
/// - Always answer "What does this mean for me?"
/// - Contextualize numbers, avoid raw data dumps
/// - Prefer explanations over charts when possible
struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToMarketInsights: Bool = false
    // Legacy sections below still reference this state; keep for compilation.
    @State private var showMarketInsights: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundCanvas
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        insightsTopMessage
                            .padding(.top, 4)
                        
                        heroSection
                        
                        onTheWaySection
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var insightsTopMessage: some View {
        HStack(alignment: .center) {
            Color.clear
                .frame(width: 24, height: 24)
            
            Text("Understand what’s driving your\nportfolio and what to watch.")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(DesignSystem.Colors.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            
            Color.clear
                .frame(width: 24, height: 24)
        }
        // Let the 2-line text breathe (prevents cropping).
        .frame(minHeight: 36)
        .padding(.top, 8)
    }
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            InsightStackedPreviewCard()
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                navigateToMarketInsights = true
            } label: {
                Text("Read Market Insights")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(DesignSystem.Colors.accent)
                    )
            }
            .buttonStyle(.plain)
            
            NavigationLink(
                destination: MarketInsightsView(showsCloseButton: false)
                    .environmentObject(appState),
                isActive: $navigateToMarketInsights,
                label: { EmptyView() }
            )
            .hidden()
        }
    }
    
    // MARK: - On the way
    
    private var onTheWaySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("On The Way")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
            
            VStack(spacing: 12) {
                LockedTeaserCard(
                    icon: "trophy.fill",
                    title: "Top Performers",
                    subtitle: "How you got here over time"
                )
                
                LockedTeaserCard(
                    icon: "chart.pie.fill",
                    title: "Allocation Analysis",
                    subtitle: "How you got here over time"
                )
                
                LockedTeaserCard(
                    icon: "wand.and.stars",
                    title: "What-If Scenarios",
                    subtitle: "How you got here over time"
                )
            }
        }
    }
    
    // MARK: - Insights Section (Primary)
    // Upgrade: Now the LEAD section - answers "What's happening that affects ME?"
    // UX Intent: Personal relevance first, market noise filtered out
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header - emphasizes personal relevance
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("For You")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text("What's happening with your money")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
                
                // "See All" opens Market Insights (or paywall for free users)
                Button(action: {
                    showMarketInsights = true
                }) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            if hasInsightsAccess {
                
                // Insight cards - each answers "What does this mean for me?"
                Button(action: {
                    showMarketInsights = true
                }) {
                    VStack(spacing: 0) {
                        PersonalInsightRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Your stocks are up today",
                            context: "Market momentum is helping your tech holdings",
                            detail: "+€124 since yesterday",
                            color: .green,
                            isPositive: true
                        )
                        Divider().padding(.leading, 56)
                        PersonalInsightRow(
                            icon: "building.2",
                            title: "Apple reports earnings Thursday",
                            context: "You hold AAPL in your Fidelity account",
                            detail: "Affects 12% of portfolio",
                            color: .blue,
                            isPositive: nil
                        )
                        Divider().padding(.leading, 56)
                        PersonalInsightRow(
                            icon: "percent",
                            title: "Rates unchanged — good for bonds",
                            context: "Your bond allocation benefits from stability",
                            detail: "33% of your portfolio",
                            color: .orange,
                            isPositive: true
                        )
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            } else {
                // Free users: single teaser card indicating "Mediocre + warnings" (no copy/paste of feed)
                let relevant = MarketInsight.sampleInsights.filter { $0.impactLevel != .general }
                let highImpactCount = relevant.filter { $0.impactLevel == .high }.count
                
                InsightsMarketImpactTeaserCard(
                    climate: .bearish, // Displays as "Mediocre"
                    warningsCount: relevant.count,
                    highImpactCount: highImpactCount,
                    onTap: { showMarketInsights = true }
                )
                .padding(.horizontal)
            }
        }
        // Present MarketInsightsView as a full-screen sheet
        .sheet(isPresented: $showMarketInsights) {
            MarketInsightsView()
                .environmentObject(appState)
        }
    }

    private var hasInsightsAccess: Bool {
        let level = appState.currentUser?.membershipLevel ?? .standard
        return level != .standard
    }

    // (Warnings card intentionally not duplicated here; the Insights screen uses a single teaser card.)
    
    // MARK: - Exposure Section (Secondary)
    // UX Intent: Answer "How am I positioned?" with context, not just percentages
    
    private var exposureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Exposure")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Visual allocation bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * 0.5)
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geo.size.width * 0.33)
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: geo.size.width * 0.17)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 24)
                .padding(.horizontal)
                
                // Contextual explanations (not just percentages)
                VStack(spacing: 12) {
                    ExposureExplanationRow(
                        color: .blue,
                        title: "Growth-focused",
                        percentage: "50%",
                        explanation: "Your stocks aim for long-term growth"
                    )
                    ExposureExplanationRow(
                        color: .green,
                        title: "Income-generating",
                        percentage: "33%",
                        explanation: "Bonds provide steady returns"
                    )
                    ExposureExplanationRow(
                        color: .orange,
                        title: "Safety buffer",
                        percentage: "17%",
                        explanation: "Cash ready for opportunities"
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
}

// MARK: - Supporting Views

/// Personal insight row - answers "What does this mean for ME?"
/// UX: Contextual, warm, personal - not just market data
struct PersonalInsightRow: View {
    let icon: String
    let title: String
    let context: String  // Personal relevance explanation
    let detail: String   // Specific impact on user
    let color: Color
    let isPositive: Bool?  // nil = neutral
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(context)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let positive = isPositive {
                    Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(positive ? .green : .red)
                }
                
                Text(detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Hub components (new)

private struct InsightHubRow: View {
    let iconSystemName: String
    let iconBackground: Color
    let iconTint: Color
    let title: String
    let subtitle: String
    let badgeText: String?
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 46, height: 46)
                
                Image(systemName: iconSystemName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconTint)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let badgeText {
                        Text(badgeText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    
                    Spacer(minLength: 0)
                }
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
    }
}

private struct TeaserRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.55))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.7))
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.55))
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Figma Insight Hub (V2)

private struct InsightStackedPreviewCard: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.60))
                .frame(width: 268, height: 51)
                .offset(y: 0)
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
            
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .frame(height: 63)
                .padding(.horizontal, 16)
                .offset(y: 11)
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
            
            VStack(alignment: .leading, spacing: 12) {
                Image("InsightCardPlaceholder")
                    .resizable()
                    .scaledToFill()
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
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
            .padding(.top, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LockedTeaserCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.80))
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.inkSecondary.opacity(0.55))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .foregroundColor(DesignSystem.Colors.ink.opacity(0.55))
                
                Text(subtitle)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.inkSecondary.opacity(0.55))
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.inkSecondary.opacity(0.55))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 19)
        .background(Color(hex: "F0F0F0") ?? Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
}

/// Exposure explanation row - explains allocation with meaning
/// UX: "What does this mean for my strategy?" not just percentages
struct ExposureExplanationRow: View {
    let color: Color
    let title: String
    let percentage: String
    let explanation: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(percentage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text(explanation)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

/// Contextual metric card - numbers with meaning
/// UX: Always explains "what does this number mean for me?"
struct ContextualMetricCard: View {
    let title: String
    let value: String
    let context: String  // Explanation of what this means
    let isPositive: Bool?  // nil = neutral
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
            
            HStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(valueColor)
                
                if let positive = isPositive {
                    Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(positive ? DesignSystem.Colors.positive : DesignSystem.Colors.negative)
                }
            }
            
            Text(context)
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.cardPadding)
        .surfaceCard(radius: DesignSystem.Radius.cardSecondary)
    }
    
    private var valueColor: Color {
        guard let positive = isPositive else { return DesignSystem.Colors.ink }
        return positive ? DesignSystem.Colors.positive : DesignSystem.Colors.negative
    }
}

/// Legacy support - kept for any remaining uses
struct AllocationLegendItem: View {
    let color: Color
    let label: String
    let percentage: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Text(percentage)
                .font(.system(size: 13, weight: .medium))
        }
    }
}

/// Legacy support - kept for any remaining uses
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(value.hasPrefix("+") ? .green : .primary)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// Legacy support - kept for any remaining uses
struct InsightRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview("Insights View") {
    InsightsView()
        .environmentObject(AppState())
}
