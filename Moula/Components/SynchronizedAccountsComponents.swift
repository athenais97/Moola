import SwiftUI

// MARK: - Aggregated Balance Header

/// Hero header displaying total portfolio value across all institutions
/// UX Intent: Immediate sense of net worth with privacy toggle
/// Foundation compliance: Clear visual hierarchy, one primary metric
struct AggregatedBalanceHeader: View {
    let portfolio: AggregatedPortfolio
    let isPrivacyMode: Bool
    let onTogglePrivacy: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Title with privacy toggle
            HStack {
                Text("Total Connected Balance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onTogglePrivacy) {
                    Image(systemName: isPrivacyMode ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                }
                .buttonStyle(PrivacyToggleButtonStyle())
                .accessibilityLabel(isPrivacyMode ? "Show balances" : "Hide balances")
            }
            
            // Balance display
            VStack(spacing: 8) {
                Text(isPrivacyMode ? "••••••" : portfolio.formattedTotalBalance)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: isPrivacyMode)
                
                // Metadata row
                HStack(spacing: 16) {
                    // Account count
                    Label {
                        Text("\(portfolio.totalAccountCount) accounts")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "square.stack.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    // Last sync time
                    Label {
                        Text(portfolio.lastSyncDescription)
                            .font(.system(size: 13))
                            .foregroundColor(portfolio.isStale ? .orange : .secondary)
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                            .foregroundColor(portfolio.isStale ? .orange : .secondary)
                    }
                }
                
                // Currency conversion note
                if portfolio.hasMultipleCurrencies && !isPrivacyMode {
                    Text("Converted to \(portfolio.baseCurrencyCode) at current rates")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                        .padding(.top, 4)
                }
            }
            
            // Attention indicator
            if portfolio.institutionsNeedingAttention > 0 {
                attentionBanner
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
    
    private var attentionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)
            
            Text("\(portfolio.institutionsNeedingAttention) institution\(portfolio.institutionsNeedingAttention == 1 ? "" : "s") need\(portfolio.institutionsNeedingAttention == 1 ? "s" : "") attention")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .padding(.top, 8)
    }
}

// MARK: - Institution Group View

/// Grouped section for a single financial institution
/// UX Intent: Clear visual separation between banks with nested accounts
/// Foundation compliance: Scannable hierarchy, grouped content
struct InstitutionGroupView: View {
    let institution: SynchronizedInstitution
    let isPrivacyMode: Bool
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onReconnect: () -> Void
    let onUnlink: () -> Void
    let onAccountTap: (SynchronizedAccount) -> Void
    
    @State private var showUnlinkConfirmation: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Institution header
            institutionHeader
            
            // Accounts list (when expanded)
            if isExpanded {
                accountsList
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        .confirmationDialog(
            "Unlink \(institution.name)?",
            isPresented: $showUnlinkConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unlink All Accounts", role: .destructive, action: onUnlink)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All \(institution.accounts.count) account\(institution.accounts.count == 1 ? "" : "s") from \(institution.name) will be removed. You can reconnect anytime.")
        }
    }
    
    // MARK: - Institution Header
    
    private var institutionHeader: some View {
        Button(action: {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                onToggleExpand()
            }
        }) {
            HStack(spacing: 14) {
                // Institution logo
                institutionLogo
                
                // Institution info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(institution.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Status indicator
                        ConnectionStatusBadge(status: institution.connectionStatus)
                    }
                    
                    // Subtitle: account count and last sync
                    Text("\(institution.accounts.count) account\(institution.accounts.count == 1 ? "" : "s") • \(institution.lastSyncDescription)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Balance or reconnect button
                if institution.connectionStatus == .expired || institution.requiresReauthentication {
                    reconnectButton
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(isPrivacyMode ? "••••••" : institution.formattedTotalBalance)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Expand indicator
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(InstitutionHeaderButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                showUnlinkConfirmation = true
            } label: {
                Label("Unlink \(institution.name)", systemImage: "link.badge.minus")
            }
            
            if institution.requiresReauthentication {
                Button {
                    onReconnect()
                } label: {
                    Label("Reconnect", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }
    
    private var institutionLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(institution.brandColor.opacity(0.12))
                .frame(width: 48, height: 48)
            
            Image(systemName: institution.logoName)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(institution.brandColor)
        }
    }
    
    private var reconnectButton: some View {
        Button(action: {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            onReconnect()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .semibold))
                Text("Reconnect")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.orange)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Accounts List
    
    private var accountsList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.leading, 78)
            
            ForEach(Array(institution.accounts.enumerated()), id: \.element.id) { index, account in
                SynchronizedAccountRow(
                    account: account,
                    isPrivacyMode: isPrivacyMode,
                    onTap: { onAccountTap(account) }
                )
                
                if index < institution.accounts.count - 1 {
                    Divider()
                        .padding(.leading, 78)
                }
            }
        }
    }
}

// MARK: - Synchronized Account Row

/// Individual account row within an institution group
/// UX Intent: Clear display of account details with tap interaction
struct SynchronizedAccountRow: View {
    let account: SynchronizedAccount
    let isPrivacyMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            onTap()
        }) {
            HStack(spacing: 14) {
                // Account type icon
                ZStack {
                    Circle()
                        .fill(account.accountType.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: account.accountType.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(account.accountType.color)
                }
                .padding(.leading, 24) // Indent under institution logo
                
                // Account info
                VStack(alignment: .leading, spacing: 3) {
                    Text(account.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(account.maskedNumber)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Balance
                Text(isPrivacyMode ? "••••••" : account.formattedBalance)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(account.isActive ? .primary : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(SyncedAccountRowButtonStyle())
    }
}

// MARK: - Connection Status Badge

/// Compact status indicator for connection health
/// UX Intent: Instant visual feedback on connection state
struct ConnectionStatusBadge: View {
    let status: ConnectionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
        }
        .accessibilityLabel(status.description)
    }
}

// MARK: - Empty State View

/// Premium empty state for when no accounts are linked
/// UX Intent: Welcoming, supportive, with clear primary action
/// Foundation compliance: Not blaming, actionable
struct NoAccountsEmptyState: View {
    let onAddAccount: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration
            ZStack {
                // Background rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1 - Double(index) * 0.03),
                                    Color.purple.opacity(0.1 - Double(index) * 0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: CGFloat(100 + index * 40), height: CGFloat(100 + index * 40))
                }
                
                // Center icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.15),
                                    Color.purple.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .frame(height: 180)
            
            // Text content
            VStack(spacing: 12) {
                Text("No Accounts Linked")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Connect your banks and brokerages\nto see your complete financial picture\nin one secure place.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            // Primary action
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onAddAccount()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Link Your First Bank")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            // Security note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("Bank-level encryption protects your data")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Skeleton Loading View

/// Shimmer loading state that mirrors actual content structure
/// UX Intent: Reduce perceived loading time with content preview
struct SyncedAccountsSkeletonView: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header skeleton
            headerSkeleton
            
            // Institution skeletons
            ForEach(0..<2, id: \.self) { _ in
                institutionSkeleton
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    private var headerSkeleton: some View {
        VStack(spacing: 16) {
            HStack {
                SkeletonShape(width: 160, height: 16)
                Spacer()
                SkeletonShape(width: 36, height: 36, isCircle: true)
            }
            
            SkeletonShape(width: 200, height: 38)
            
            HStack(spacing: 20) {
                SkeletonShape(width: 100, height: 14)
                SkeletonShape(width: 120, height: 14)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
        )
    }
    
    private var institutionSkeleton: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                SkeletonShape(width: 48, height: 48, cornerRadius: 12)
                
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonShape(width: 120, height: 16)
                    SkeletonShape(width: 160, height: 12)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    SkeletonShape(width: 80, height: 16)
                    SkeletonShape(width: 16, height: 12)
                }
            }
            .padding(16)
            
            // Account rows
            ForEach(0..<2, id: \.self) { _ in
                Divider().padding(.leading, 78)
                
                HStack(spacing: 14) {
                    SkeletonShape(width: 40, height: 40, isCircle: true)
                        .padding(.leading, 24)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonShape(width: 100, height: 14)
                        SkeletonShape(width: 70, height: 12)
                    }
                    
                    Spacer()
                    
                    SkeletonShape(width: 70, height: 14)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

/// Reusable skeleton shape with shimmer effect
struct SkeletonShape: View {
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = 8
    var isCircle: Bool = false
    
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        Group {
            if isCircle {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: width, height: height)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemGray5))
                    .frame(width: width, height: height)
            }
        }
        .overlay(
            GeometryReader { geometry in
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 100)
                .offset(x: shimmerOffset)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = geometry.size.width + 200
                    }
                }
            }
            .clipped()
        )
        .clipShape(isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: cornerRadius)))
    }
}

/// Type-erased shape for conditional clipping
struct AnyShape: Shape, @unchecked Sendable {
    private let pathBuilder: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

// MARK: - Button Styles

/// Button style for institution header tap
struct InstitutionHeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color(.systemGray5).opacity(0.5)
                    : Color.clear
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Button style for synchronized account row tap
struct SyncedAccountRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color(.systemGray5).opacity(0.5)
                    : Color.clear
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Button style for privacy toggle
struct PrivacyToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Aggregated Balance Header") {
    VStack {
        AggregatedBalanceHeader(
            portfolio: .sample,
            isPrivacyMode: false,
            onTogglePrivacy: {}
        )
        .padding()
        
        AggregatedBalanceHeader(
            portfolio: .sample,
            isPrivacyMode: true,
            onTogglePrivacy: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Institution Group") {
    VStack(spacing: 16) {
        InstitutionGroupView(
            institution: SynchronizedInstitution.sampleInstitutions[0],
            isPrivacyMode: false,
            isExpanded: true,
            onToggleExpand: {},
            onReconnect: {},
            onUnlink: {},
            onAccountTap: { _ in }
        )
        
        InstitutionGroupView(
            institution: SynchronizedInstitution.sampleWithExpired[1],
            isPrivacyMode: false,
            isExpanded: false,
            onToggleExpand: {},
            onReconnect: {},
            onUnlink: {},
            onAccountTap: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

// MARK: - Scale Button Style

/// Button style with scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview("Empty State") {
    NoAccountsEmptyState(onAddAccount: {})
        .background(Color(.systemGroupedBackground))
}

#Preview("Skeleton Loading") {
    SyncedAccountsSkeletonView()
        .padding(.top, 20)
        .background(Color(.systemGroupedBackground))
}
