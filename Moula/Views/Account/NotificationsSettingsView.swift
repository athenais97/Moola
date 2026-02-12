import SwiftUI

/// Full-screen view for managing notification preferences
/// UX Intent: Simple toggle list with clear descriptions
/// Foundation compliance: Progressive disclosure, scannable options
struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Individual notification toggles
    @State private var pushEnabled: Bool = true
    @State private var transactionAlerts: Bool = true
    @State private var priceAlerts: Bool = false
    @State private var weeklyDigest: Bool = true
    @State private var marketNews: Bool = false
    @State private var securityAlerts: Bool = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Master toggle
                    masterToggleSection
                    
                    // Individual preferences (only shown if master is enabled)
                    if pushEnabled {
                        alertsSection
                        digestSection
                    }
                    
                    // Info footer
                    footerInfo
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .onChange(of: pushEnabled) { _, _ in
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var masterToggleSection: some View {
        VStack(spacing: 0) {
            notificationToggleRow(
                icon: "bell.fill",
                iconColor: .orange,
                title: "Push Notifications",
                description: "Receive real-time alerts",
                isOn: $pushEnabled,
                isMaster: true
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ALERTS")
            
            VStack(spacing: 0) {
                notificationToggleRow(
                    icon: "arrow.left.arrow.right",
                    iconColor: .green,
                    title: "Transactions",
                    description: "Activity on your accounts",
                    isOn: $transactionAlerts
                )
                
                Divider().padding(.leading, 62)
                
                notificationToggleRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .blue,
                    title: "Price Alerts",
                    description: "Custom price thresholds",
                    isOn: $priceAlerts
                )
                
                Divider().padding(.leading, 62)
                
                notificationToggleRow(
                    icon: "shield.fill",
                    iconColor: .red,
                    title: "Security",
                    description: "Logins and suspicious activity",
                    isOn: $securityAlerts
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var digestSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("DIGESTS")
            
            VStack(spacing: 0) {
                notificationToggleRow(
                    icon: "calendar",
                    iconColor: .purple,
                    title: "Weekly Summary",
                    description: "Every Monday morning",
                    isOn: $weeklyDigest
                )
                
                Divider().padding(.leading, 62)
                
                notificationToggleRow(
                    icon: "newspaper.fill",
                    iconColor: .teal,
                    title: "Market News",
                    description: "Important updates",
                    isOn: $marketNews
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var footerInfo: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
            
            Text("You can also manage notifications in your device's system settings.")
                .font(.system(size: 12))
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Reusable Row
    
    private func notificationToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        isOn: Binding<Bool>,
        isMaster: Bool = false
    ) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: isMaster ? .semibold : .regular))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: isOn)
                .labelsHidden()
                // Spec: all toggles use the app primary color.
                .tint(DesignSystem.Colors.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            // Allow tapping anywhere on the row to toggle
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            isOn.wrappedValue.toggle()
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }
}

// MARK: - Preview

#Preview("Notifications Settings") {
    NotificationsSettingsView()
}
