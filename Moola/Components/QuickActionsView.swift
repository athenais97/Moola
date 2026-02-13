import SwiftUI

/// Horizontal scrolling quick action buttons
/// UX Intent: Thumb-friendly access to primary actions without cluttering the screen
/// Design: Large touch targets with clear iconography
struct QuickActionsView: View {
    let actions: [QuickAction]
    let onAction: (QuickAction) -> Void
    
    init(
        actions: [QuickAction] = QuickAction.allCases,
        onAction: @escaping (QuickAction) -> Void
    ) {
        self.actions = actions
        self.onAction = onAction
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(actions) { action in
                    QuickActionButton(action: action) {
                        onAction(action)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Quick Action Button

/// Individual action button with icon and label
struct QuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.12))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: action.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(action.color)
                }
                
                // Label
                Text(action.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(width: 76)
        }
        .buttonStyle(QuickActionButtonStyle())
    }
}

// MARK: - Button Style

/// Custom button style with subtle press feedback
private struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Quick Actions") {
    VStack(spacing: 24) {
        QuickActionsView { action in
            print("Tapped: \(action.rawValue)")
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Quick Actions - Dark Mode") {
    VStack(spacing: 24) {
        QuickActionsView { action in
            print("Tapped: \(action.rawValue)")
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

#Preview("Single Action Button") {
    HStack(spacing: 16) {
        QuickActionButton(action: .addBank) {}
        QuickActionButton(action: .transfer) {}
        QuickActionButton(action: .analysis) {}
        QuickActionButton(action: .budget) {}
    }
    .padding()
    .background(Color(.systemBackground))
}
