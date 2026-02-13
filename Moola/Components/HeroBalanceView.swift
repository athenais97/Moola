import SwiftUI

/// Hero balance display for the Pulse dashboard
/// UX Intent: The most important element on screen - large, readable, tappable
/// Follows foundation principles: high-quality typography, clear visual hierarchy
struct HeroBalanceView: View {
    let balance: String
    let displayMode: BalanceDisplayMode
    let change: BalanceChange
    let isPrivacyMode: Bool
    let onTapBalance: () -> Void
    let onTogglePrivacy: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Display mode label with privacy toggle
            HStack(spacing: 8) {
                Text(displayMode.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Privacy toggle button
                Button(action: onTogglePrivacy) {
                    Image(systemName: isPrivacyMode ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PrivacyButtonStyle())
            }
            
            // Main balance - tappable to toggle display mode
            Button(action: onTapBalance) {
                Text(balance)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
            }
            .buttonStyle(BalanceTapStyle())
            .accessibilityLabel("Balance: \(isPrivacyMode ? "Hidden" : balance)")
            .accessibilityHint("Double tap to switch between Total Net Worth and Invested Capital")
            
            // Trend indicator
            if !isPrivacyMode {
                trendIndicator
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    // MARK: - Trend Indicator
    
    private var trendIndicator: some View {
        HStack(spacing: 6) {
            // Direction arrow
            Image(systemName: change.isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(change.color)
            
            // Amount change
            Text(change.formattedAmount)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(change.color)
            
            // Percentage change
            Text("(\(change.formattedPercentage))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(change.color.opacity(0.8))
            
            // Period label
            Text(change.period.rawValue)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .padding(.leading, 2)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(change.color.opacity(0.1))
        )
    }
}

// MARK: - Button Styles

/// Button style for the balance tap interaction
/// Provides subtle feedback without being distracting
private struct BalanceTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Button style for the privacy toggle
private struct PrivacyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(Color(.systemGray6))
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Hero Balance - Positive") {
    VStack {
        HeroBalanceView(
            balance: "$127,450.32",
            displayMode: .totalNetWorth,
            change: BalanceChange(amount: 1240.50, percentage: 2.4, period: .week),
            isPrivacyMode: false,
            onTapBalance: {},
            onTogglePrivacy: {}
        )
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Hero Balance - Negative") {
    VStack {
        HeroBalanceView(
            balance: "$127,450.32",
            displayMode: .totalNetWorth,
            change: BalanceChange(amount: -850.25, percentage: -1.2, period: .week),
            isPrivacyMode: false,
            onTapBalance: {},
            onTogglePrivacy: {}
        )
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Hero Balance - Privacy Mode") {
    VStack {
        HeroBalanceView(
            balance: "••••••",
            displayMode: .totalNetWorth,
            change: BalanceChange(amount: 1240.50, percentage: 2.4, period: .week),
            isPrivacyMode: true,
            onTapBalance: {},
            onTogglePrivacy: {}
        )
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Hero Balance - Invested Capital") {
    VStack {
        HeroBalanceView(
            balance: "$98,200.00",
            displayMode: .investedCapital,
            change: BalanceChange(amount: 3200.00, percentage: 3.4, period: .week),
            isPrivacyMode: false,
            onTapBalance: {},
            onTogglePrivacy: {}
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
