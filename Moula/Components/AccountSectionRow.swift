import SwiftUI

/// Badge style for visual differentiation
enum BadgeStyle {
    case info
    case warning
    case success
    case error
}

/// Row type determining the trailing accessory
enum AccountRowAccessory {
    case chevron           // Navigation to another screen
    case toggle(Binding<Bool>)  // In-place toggle
    case badge(String, BadgeStyle)  // Informational badge
    case chevronWithBadge(String, BadgeStyle)  // Navigation + badge
    case none              // No accessory
}

/// Reusable row component for Account screen sections
/// UX Intent: High affordance touch targets with clear visual indicators
/// Following iOS native grouped list patterns
struct AccountSectionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let accessory: AccountRowAccessory
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        icon: String,
        iconColor: Color = .accentColor,
        title: String,
        subtitle: String? = nil,
        accessory: AccountRowAccessory = .chevron,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            
            // Haptic feedback on tap (selection feedback)
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            
            action()
        }) {
            HStack(spacing: 14) {
                // Leading icon
                iconView
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(isDisabled ? .secondary : .primary)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Trailing accessory
                accessoryView
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(AccountRowButtonStyle(isDisabled: isDisabled))
        .disabled(shouldDisableButton)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconColor.opacity(isDisabled ? 0.1 : 0.15))
                .frame(width: 32, height: 32)
            
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDisabled ? .secondary : iconColor)
        }
    }
    
    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
            
        case .toggle(let binding):
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(.accentColor)
            
        case .badge(let text, let style):
            BadgeView(text: text, style: style)
            
        case .chevronWithBadge(let text, let style):
            HStack(spacing: 8) {
                BadgeView(text: text, style: style)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
        case .none:
            EmptyView()
        }
    }
    
    /// Toggles should not disable the button
    private var shouldDisableButton: Bool {
        if case .toggle = accessory {
            return true // Toggle handles its own interaction
        }
        return isDisabled
    }
}

// MARK: - Badge View

/// Small badge indicator for counts or status
struct BadgeView: View {
    let text: String
    let style: BadgeStyle
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .info: return .blue
        case .warning: return .orange
        case .success: return .green
        case .error: return .red
        }
    }
}

// MARK: - Button Style

/// Custom button style for account rows
/// Provides subtle highlight on press
struct AccountRowButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed && !isDisabled
                    ? Color(.systemGray5)
                    : Color.clear
            )
    }
}

// MARK: - Preview

#Preview("Account Rows") {
    VStack(spacing: 0) {
        AccountSectionRow(
            icon: "person.fill",
            iconColor: .blue,
            title: "My Personal Information",
            subtitle: "Name, email, phone",
            action: {}
        )
        
        Divider().padding(.leading, 62)
        
        AccountSectionRow(
            icon: "building.columns.fill",
            iconColor: .green,
            title: "Synced Accounts",
            accessory: .chevronWithBadge("2", .info),
            action: {}
        )
        
        Divider().padding(.leading, 62)
        
        AccountSectionRow(
            icon: "bell.fill",
            iconColor: .orange,
            title: "Notifications",
            accessory: .toggle(.constant(true)),
            action: {}
        )
        
        Divider().padding(.leading, 62)
        
        AccountSectionRow(
            icon: "building.columns.fill",
            iconColor: .gray,
            title: "Synced Accounts",
            accessory: .chevronWithBadge("!", .warning),
            isDisabled: true,
            action: {}
        )
    }
    .background(Color.white)
    .cornerRadius(12)
    .padding()
    .background(Color(.systemGroupedBackground))
}
