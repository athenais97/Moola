import SwiftUI

// MARK: - Metric Toggle

/// Thumb-friendly toggle between Currency ($) and Percentage (%)
///
/// UX Intent:
/// - Single-tap to switch metrics
/// - Clear visual indication of selected state
/// - Consistent with app's segmented control patterns
struct MetricToggle: View {
    @Binding var selectedMetric: PerformanceMetric
    
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(PerformanceMetric.allCases) { metric in
                metricButton(for: metric)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    private func metricButton(for metric: PerformanceMetric) -> some View {
        let isSelected = selectedMetric == metric
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMetric = metric
            }
        }) {
            Text(metric.symbol)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(width: 44, height: 32)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                            .matchedGeometryEffect(id: "metricSelection", in: animation)
                    }
                }
        }
        .buttonStyle(MetricToggleButtonStyle())
        .accessibilityLabel(metric.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct MetricToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Podium Card (Top Performer)

/// Specialized card for the #1 ranked account
///
/// UX Intent:
/// - Celebrate the top performer with distinct styling
/// - Show mini-sparkline for trajectory context
/// - Subtle "halo" effect (gold/emerald accent)
struct PodiumCard: View {
    let account: RankedAccount
    let metric: PerformanceMetric
    let isPrivacyMode: Bool
    let isDefensiveMode: Bool
    
    @State private var glowAnimation: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Winner badge
            winnerBadge
                .padding(.top, 16)
            
            // Account info
            accountInfo
                .padding(.top, 12)
            
            // Performance value
            performanceValue
                .padding(.top, 8)
            
            // Mini sparkline
            sparkline
                .padding(.top, 16)
                .padding(.horizontal, 24)
            
            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
        .background(podiumBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: accentColor.opacity(0.15), radius: 16, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
        }
    }
    
    // MARK: - Winner Badge
    
    private var winnerBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.system(size: 14))
                .foregroundColor(accentColor)
            
            Text("TOP PERFORMER")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accentColor)
                .tracking(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(accentColor.opacity(0.15))
        )
    }
    
    // MARK: - Account Info
    
    private var accountInfo: some View {
        HStack(spacing: 10) {
            // Institution icon
            ZStack {
                Circle()
                    .fill(account.brandColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: account.institutionLogoName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(account.brandColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.accountName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(account.institutionName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Performance Value
    
    private var performanceValue: some View {
        VStack(spacing: 4) {
            Text(account.displayValue(for: metric, masked: isPrivacyMode && metric == .currency))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(account.performanceColor)
                .contentTransition(.numericText())
            
            // Secondary metric
            Text(metric == .currency ? account.formattedPercentageGain : account.formattedAbsoluteGain)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .opacity(isPrivacyMode && metric == .percentage ? 0.5 : 1.0)
        }
    }
    
    // MARK: - Sparkline
    
    private var sparkline: some View {
        Group {
            if !account.balanceHistory.isEmpty {
                SparklineView(
                    dataPoints: account.balanceHistory,
                    isPositive: account.isPositive,
                    height: 50
                )
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 50)
                    .cornerRadius(4)
            }
        }
    }
    
    // MARK: - Background
    
    private var podiumBackground: some View {
        ZStack {
            // Base background
            Color(.systemBackground)
            
            // Subtle gradient glow effect
            RadialGradient(
                colors: [
                    accentColor.opacity(glowAnimation ? 0.08 : 0.04),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 200
            )
        }
    }
    
    // MARK: - Accent Color
    
    private var accentColor: Color {
        if isDefensiveMode {
            return Color(red: 0.95, green: 0.75, blue: 0.3) // Amber for defensive
        }
        return account.isPositive
            ? Color(red: 0.85, green: 0.75, blue: 0.35) // Gold
            : Color(red: 0.7, green: 0.8, blue: 0.4)    // Yellow-green for least loss
    }
}

// MARK: - Performance Bar

/// Horizontal bar showing relative performance
///
/// UX Intent:
/// - Visual comparison at a glance
/// - Color-coded by performance (greener = better)
/// - Animated fill for engagement
struct PerformanceBar: View {
    let fill: CGFloat       // 0...1
    let color: Color
    let isDefensiveMode: Bool
    
    @State private var animatedFill: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                
                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.8),
                                color
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedFill, height: 8)
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animatedFill = fill
            }
        }
        .onChange(of: fill) { newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animatedFill = newValue
            }
        }
    }
}

// MARK: - Ranking Row

/// Individual row in the ranking list
///
/// UX Intent:
/// - Clear visual hierarchy: Rank → Identity → Performance
/// - Tappable for drill-down to account details
/// - Performance bar for visual comparison
struct RankingRow: View {
    let account: RankedAccount
    let rank: Int
    let metric: PerformanceMetric
    let barFill: CGFloat
    let barColor: Color
    let isPrivacyMode: Bool
    let isDefensiveMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Rank number
                rankIndicator
                
                // Account identity
                accountIdentity
                
                Spacer(minLength: 8)
                
                // Performance value and bar
                performanceSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
        }
        .buttonStyle(RankingRowButtonStyle())
    }
    
    // MARK: - Rank Indicator
    
    private var rankIndicator: some View {
        ZStack {
            Circle()
                .fill(rankBackground)
                .frame(width: 32, height: 32)
            
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(rankTextColor)
        }
    }
    
    private var rankBackground: Color {
        switch rank {
        case 1:
            return isDefensiveMode
                ? Color(red: 0.95, green: 0.75, blue: 0.3).opacity(0.2)
                : Color(red: 0.85, green: 0.75, blue: 0.35).opacity(0.2)
        case 2:
            return Color(.systemGray4).opacity(0.5)
        case 3:
            return Color(red: 0.8, green: 0.6, blue: 0.4).opacity(0.2)
        default:
            return Color(.systemGray5)
        }
    }
    
    private var rankTextColor: Color {
        switch rank {
        case 1:
            return isDefensiveMode
                ? Color(red: 0.8, green: 0.6, blue: 0.2)
                : Color(red: 0.75, green: 0.6, blue: 0.2)
        case 2:
            return Color(.systemGray)
        case 3:
            return Color(red: 0.7, green: 0.5, blue: 0.3)
        default:
            return .secondary
        }
    }
    
    // MARK: - Account Identity
    
    private var accountIdentity: some View {
        HStack(spacing: 10) {
            // Institution logo
            ZStack {
                Circle()
                    .fill(account.brandColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: account.institutionLogoName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(account.brandColor)
            }
            
            // Account name
            VStack(alignment: .leading, spacing: 2) {
                Text(account.accountName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(account.institutionName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Value
            Text(account.displayValue(for: metric, masked: isPrivacyMode && metric == .currency))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(account.performanceColor)
            
            // Performance bar
            PerformanceBar(
                fill: barFill,
                color: barColor,
                isDefensiveMode: isDefensiveMode
            )
            .frame(width: 80)
        }
    }
}

private struct RankingRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Insufficient Data Row

/// Row for accounts with less than 24h of data
///
/// UX Intent:
/// - Clear "Calculating..." state
/// - Non-interactive (not tappable for details)
/// - Placed at bottom of list
struct InsufficientDataRow: View {
    let account: RankedAccount
    
    @State private var pulseAnimation: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 32)
                
                ProgressView()
                    .scaleEffect(0.6)
            }
            
            // Account identity
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(account.brandColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: account.institutionLogoName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(account.brandColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.accountName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(account.institutionName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Calculating state
            VStack(alignment: .trailing, spacing: 2) {
                Text("Calculating...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Needs 24h of data")
                    .font(.system(size: 11))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground).opacity(0.6))
    }
}

// MARK: - Defensive Mode Banner

/// Banner shown when all accounts are negative
///
/// UX Intent:
/// - Reassure user that we're showing "least loss"
/// - Non-alarmist, human tone
struct DefensiveModeBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.3))
            
            Text("Showing accounts by smallest decline")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.95, green: 0.75, blue: 0.3).opacity(0.1))
        )
    }
}

// MARK: - Empty State

/// Empty state for when no accounts are linked
struct RankingEmptyState: View {
    let state: RankingState
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.1),
                                Color.yellow.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.orange)
            }
            
            // Message
            VStack(spacing: 8) {
                Text("No Rankings Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(state.emptyStateMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Skeleton Loading

/// Loading skeleton for the ranking list
struct RankingSkeleton: View {
    @State private var shimmerOffset: CGFloat = -0.5
    
    var body: some View {
        VStack(spacing: 0) {
            // Podium skeleton
            podiumSkeleton
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // List skeleton
            VStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { _ in
                    rowSkeleton
                    Divider()
                        .padding(.leading, 60)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
        }
    }
    
    private var podiumSkeleton: some View {
        VStack(spacing: 12) {
            // Badge
            RoundedRectangle(cornerRadius: 12)
                .fill(shimmerGradient)
                .frame(width: 120, height: 24)
            
            // Account info
            HStack(spacing: 10) {
                Circle()
                    .fill(shimmerGradient)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 120, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 80, height: 12)
                }
            }
            
            // Value
            RoundedRectangle(cornerRadius: 6)
                .fill(shimmerGradient)
                .frame(width: 100, height: 32)
            
            // Sparkline
            RoundedRectangle(cornerRadius: 4)
                .fill(shimmerGradient)
                .frame(height: 40)
                .padding(.horizontal, 24)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    private var rowSkeleton: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(shimmerGradient)
                .frame(width: 32, height: 32)
            
            Circle()
                .fill(shimmerGradient)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 100, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 60, height: 10)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 60, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 80, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemGray5),
                Color(.systemGray4),
                Color(.systemGray5)
            ],
            startPoint: UnitPoint(x: shimmerOffset, y: 0.5),
            endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0.5)
        )
    }
}

// MARK: - Previews

#Preview("Metric Toggle") {
    struct PreviewWrapper: View {
        @State private var metric: PerformanceMetric = .percentage
        
        var body: some View {
            VStack(spacing: 20) {
                MetricToggle(selectedMetric: $metric)
                Text("Selected: \(metric.rawValue)")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Podium Card - Positive") {
    let account = RankedAccount.sampleAccounts[0]
    
    return PodiumCard(
        account: account,
        metric: .percentage,
        isPrivacyMode: false,
        isDefensiveMode: false
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Podium Card - Defensive") {
    let account = RankedAccount.sampleNegativeAccounts[0]
    
    return PodiumCard(
        account: account,
        metric: .percentage,
        isPrivacyMode: false,
        isDefensiveMode: true
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Ranking Row") {
    let account = RankedAccount.sampleAccounts[1]
    
    return VStack(spacing: 0) {
        RankingRow(
            account: account,
            rank: 2,
            metric: .percentage,
            barFill: 0.75,
            barColor: Color(red: 0.3, green: 0.7, blue: 0.4),
            isPrivacyMode: false,
            isDefensiveMode: false,
            onTap: {}
        )
        
        Divider()
            .padding(.leading, 60)
        
        RankingRow(
            account: RankedAccount.sampleAccounts[2],
            rank: 3,
            metric: .percentage,
            barFill: 0.4,
            barColor: Color(red: 0.6, green: 0.7, blue: 0.3),
            isPrivacyMode: false,
            isDefensiveMode: false,
            onTap: {}
        )
    }
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .padding()
}

#Preview("Insufficient Data Row") {
    InsufficientDataRow(account: RankedAccount.sampleAccounts.last!)
        .padding()
}

#Preview("Defensive Banner") {
    DefensiveModeBanner()
        .padding()
}

#Preview("Loading Skeleton") {
    RankingSkeleton()
        .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    RankingEmptyState(state: .insufficientData)
        .background(Color(.systemGroupedBackground))
}
