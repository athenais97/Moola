import SwiftUI

// MARK: - Insights Paywall Components
/// Premium preview + paywall content for the new Insights layer.
///
/// Rules:
/// - No interruption on first exposure (no auto-present).
/// - Paywall opens only on user intent (tap).
/// - Preview must not reveal full articles or deep data.

/// Premium header used for the locked Insights preview state.
struct InsightsPremiumHeader: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Insights")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Try free for 7 days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.secondary.opacity(0.8))
        }
    }
}

/// Locked preview content shown to free users instead of the Impact Feed.
struct InsightsLockedPreview: View {
    let climate: PortfolioClimate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Visual: modern skeleton insight illustration (no real content)
            InsightSkeletonIllustration()
                .padding(.bottom, 2)
            
            // Requested headline
            Text("control how the market affects you")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            // High-level state (no headlines/deep data)
            VStack(alignment: .leading, spacing: 8) {
                Text("State of the market today")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                HStack(spacing: 10) {
                    Circle()
                        .fill(climate.color.opacity(0.18))
                        .frame(width: 10, height: 10)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(climate.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(climate.description)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            // Teaser (kept high-level)
            Text("See how the market impacts your revenue")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.96))
                .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
        )
    }
}

/// Compact banner shown at the top of Market Insights for free users.
/// Paywall opens only on user intent (tap on CTA).
struct InsightsTrialBanner: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 0)
            }
            
            PrimaryButton(title: buttonTitle) {
                onTap()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 6)
        )
    }
}

/// Small, modern illustration: a skeleton insight card + sparkline.
private struct InsightSkeletonIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.separator).opacity(0.08), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(width: 92, height: 18)
                    
                    Spacer()
                    
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(width: 58, height: 18)
                }
                
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(.systemGray5))
                    .frame(width: 210, height: 16)
                
                // Graph line (up/down)
                SparklineSkeleton()
                    .frame(height: 34)
                    .padding(.top, 2)
            }
            .padding(14)
        }
        .frame(height: 120)
    }
}

private struct SparklineSkeleton: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let points: [CGPoint] = [
                CGPoint(x: 0.05 * w, y: 0.65 * h),
                CGPoint(x: 0.22 * w, y: 0.35 * h),
                CGPoint(x: 0.38 * w, y: 0.55 * h),
                CGPoint(x: 0.56 * w, y: 0.25 * h),
                CGPoint(x: 0.74 * w, y: 0.62 * h),
                CGPoint(x: 0.92 * w, y: 0.38 * h),
            ]
            
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.65))
                
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for p in points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.35),
                            Color.purple.opacity(0.35),
                            Color.accentColor.opacity(0.35),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
                
                ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(Color.accentColor.opacity(0.25))
                        .frame(width: 7, height: 7)
                        .position(p)
                }
            }
        }
    }
}

/// Non-content placeholders used behind the locked preview overlay.
/// Intent: communicate "there's a feed here" without leaking real articles/data.
struct LockedInsightPlaceholderList: View {
    var body: some View {
        VStack(spacing: 14) {
            LockedInsightPlaceholderCard()
            LockedInsightPlaceholderCard()
            LockedInsightPlaceholderCard()
        }
        .opacity(0.55)
    }
}

/// Compact teaser card used on the main Insights screen.
/// Intent: show "Mediocre + warnings" at a glance without copying the full Market Insights UI.
struct InsightsMarketImpactTeaserCard: View {
    let climate: PortfolioClimate
    let warningsCount: Int
    let highImpactCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(climate.color.opacity(0.12))
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: "wave.3.forward.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(climate.color.opacity(0.9))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Market impact")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("\(climate.rawValue) • \(warningsSummary)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Subtle premium signal without blocking interaction
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary.opacity(0.65))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                
                Text("Tap to see what news is impacting your holdings.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var warningsSummary: String {
        if highImpactCount > 0 {
            return "\(highImpactCount) high-impact warning\(highImpactCount == 1 ? "" : "s")"
        }
        return "\(warningsCount) warning\(warningsCount == 1 ? "" : "s")"
    }
}

private struct LockedInsightPlaceholderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Category pill placeholder
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(width: 90, height: 20)
                
                Spacer()
                
                // Impact tag placeholder
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 20)
            }
            
            // Headline placeholders
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.systemGray5))
                .frame(height: 16)
            
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.systemGray5))
                .frame(width: 220, height: 16)
            
            // Summary placeholders
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.systemGray6))
                .frame(height: 12)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.systemGray6))
                .frame(width: 260, height: 12)
            
            HStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(.systemGray6))
                    .frame(width: 140, height: 12)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.systemGray6))
                        .frame(width: 70, height: 12)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
        )
    }
}

/// Paywall sheet explaining what Insights unlocks and why it matters.
struct InsightsPaywallSheet: View {
    let onStartTrial: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Insights")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Try free for 7 days")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 6)
                    
                    // What it unlocks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What you unlock")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        VStack(spacing: 10) {
                            PaywallBenefitRow(
                                icon: "sparkles",
                                title: "Impact Feed, personalized",
                                subtitle: "Market news linked to the accounts you actually hold"
                            )
                            
                            PaywallBenefitRow(
                                icon: "lightbulb",
                                title: "Why it matters, in plain language",
                                subtitle: "Quick context so you can decide what to watch"
                            )
                            
                            PaywallBenefitRow(
                                icon: "calendar",
                                title: "Upcoming events that affect you",
                                subtitle: "Earnings, rate decisions, and key dates tied to your exposure"
                            )
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    
                    // Why it matters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Why this matters")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text("Insights helps you connect headlines to your portfolio—so you can understand what’s changing, which accounts are exposed, and what’s worth your attention.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                            .lineSpacing(5)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                            )
                    }
                    
                    // CTA
                    VStack(spacing: 10) {
                        PrimaryButton(title: "Start free trial") {
                            onStartTrial()
                        }
                        
                        SecondaryButton(title: "Not now") {
                            onDismiss()
                        }
                    }
                    .padding(.top, 4)
                    
                    LegalDisclaimer(style: .inline)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

private struct PaywallBenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview("Insights Locked Preview") {
    VStack(spacing: 16) {
        InsightsPremiumHeader()
        
        InsightsLockedPreview(climate: .neutral)
        
        LockedInsightPlaceholderList()
        
        InsightsMarketImpactTeaserCard(
            climate: .bearish,
            warningsCount: 4,
            highImpactCount: 1,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

