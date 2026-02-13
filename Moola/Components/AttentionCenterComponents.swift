import SwiftUI

// MARK: - Attention Center Container

/// Main container for the Attention Center displayed at top of dashboard
///
/// UX Intent:
/// - High-priority, glanceable area for at-risk accounts
/// - Horizontal carousel preserves screen real estate
/// - Clear visual distinction between errors and advisories
///
/// Foundation Compliance:
/// - Information scannable in seconds
/// - One clear intent: resolve the current issue
/// - Visual urgency without panic
struct AttentionCenterView: View {
    @ObservedObject var viewModel: AttentionCenterViewModel
    let isPrivacyMode: Bool
    let onAction: (AttentionAction.ActionType) -> Void
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        if viewModel.isLoading {
            loadingState
        } else if viewModel.isAllClear {
            allClearState
        } else {
            attentionContent
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.secondary)
            
            Text("Checking accounts...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - All Clear State
    
    private var allClearState: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.75, blue: 0.45))
            
            Text("You're all set")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Attention Content
    
    private var attentionContent: some View {
        VStack(spacing: 12) {
            // Header with count
            attentionHeader
            
            // Horizontal carousel of cards
            attentionCarousel
            
            // Page indicator (if multiple items)
            if viewModel.activeItems.count > 1 {
                pageIndicator
            }
        }
    }
    
    // MARK: - Header
    
    private var attentionHeader: some View {
        HStack {
            // Attention badge
            HStack(spacing: 6) {
                if viewModel.hasCriticalItems {
                    Circle()
                        .fill(AttentionCategory.syncFailure.color)
                        .frame(width: 8, height: 8)
                        .modifier(PulseAnimationModifier())
                }
                
                Text(viewModel.headerMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Mute preferences button
            Button(action: {
                viewModel.showMutePreferences = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Carousel
    
    private var attentionCarousel: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - 48  // Side padding
            let spacing: CGFloat = 12
            
            HStack(spacing: spacing) {
                ForEach(Array(viewModel.activeItems.enumerated()), id: \.element.id) { index, item in
                    AttentionCard(
                        item: item,
                        isPrivacyMode: isPrivacyMode,
                        isResolving: viewModel.resolvingItemId == item.id,
                        onAction: {
                            let actionType = viewModel.executeAction(for: item)
                            onAction(actionType)
                        },
                        onDismiss: item.isDismissible ? {
                            viewModel.dismissItem(item)
                        } : nil
                    )
                    .frame(width: cardWidth)
                }
            }
            .padding(.horizontal, 24)
            .offset(x: calculateOffset(cardWidth: cardWidth, spacing: spacing))
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        handleDragEnd(
                            translation: value.translation.width,
                            velocity: value.predictedEndTranslation.width,
                            cardWidth: cardWidth
                        )
                    }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.focusedIndex)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        }
        .frame(height: 140)
    }
    
    private func calculateOffset(cardWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        let totalCardWidth = cardWidth + spacing
        return -CGFloat(viewModel.focusedIndex) * totalCardWidth
    }
    
    private func handleDragEnd(translation: CGFloat, velocity: CGFloat, cardWidth: CGFloat) {
        let threshold = cardWidth * 0.3
        let velocityThreshold: CGFloat = 200
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            dragOffset = 0
            
            if translation < -threshold || velocity < -velocityThreshold {
                viewModel.moveToNextItem()
            } else if translation > threshold || velocity > velocityThreshold {
                viewModel.moveToPreviousItem()
            }
        }
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.activeItems.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.focusedIndex ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: index == viewModel.focusedIndex ? 8 : 6, height: index == viewModel.focusedIndex ? 8 : 6)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.focusedIndex)
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Attention Card

/// Individual card displaying an attention item
/// UX: Lightweight, elevated surface with clear visual hierarchy
struct AttentionCard: View {
    let item: AttentionItem
    let isPrivacyMode: Bool
    let isResolving: Bool
    let onAction: () -> Void
    let onDismiss: (() -> Void)?
    
    @State private var swipeOffset: CGFloat = 0
    @State private var showDismissHint: Bool = false
    
    private let dismissThreshold: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Dismiss background (revealed on swipe)
            if onDismiss != nil {
                dismissBackground
            }
            
            // Main card content
            cardContent
                .offset(x: swipeOffset)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Dismiss Background
    
    private var dismissBackground: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                
                Text("Dismiss")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.6))
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Icon + Title + Time
            HStack(spacing: 10) {
                // Status icon with animation
                statusIcon
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayTitle(privacyMode: isPrivacyMode))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.timeSinceCreated)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Institution badge (if applicable)
                if let institutionName = item.institutionName,
                   let color = item.institutionColor {
                    institutionBadge(name: institutionName, color: color)
                }
            }
            
            // Impact description
            Text(item.impactDescription)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Spacer(minLength: 0)
            
            // Action button
            actionButton
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(item.category.color.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Status Icon
    
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(item.category.backgroundColor)
                .frame(width: 36, height: 36)
            
            Image(systemName: item.category.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(item.category.color)
        }
        .modifier(IconAnimationModifier(animation: item.priority.iconAnimation))
    }
    
    // MARK: - Institution Badge
    
    private func institutionBadge(name: String, color: Color) -> some View {
        Text(name)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: onAction) {
            HStack(spacing: 6) {
                if isResolving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: item.action.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                
                Text(item.action.label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(item.category.color)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isResolving)
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard onDismiss != nil else { return }
                
                // Only allow left swipe
                if value.translation.width < 0 {
                    swipeOffset = value.translation.width
                    showDismissHint = abs(swipeOffset) > dismissThreshold * 0.5
                }
            }
            .onEnded { value in
                guard onDismiss != nil else { return }
                
                if value.translation.width < -dismissThreshold {
                    // Dismiss
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        swipeOffset = -400
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss?()
                    }
                } else {
                    // Reset
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        swipeOffset = 0
                        showDismissHint = false
                    }
                }
            }
    }
}

// MARK: - Compact Attention Header

/// Minimal header when attention items exist but dashboard needs space
/// Tappable to expand full attention center
struct CompactAttentionHeader: View {
    let itemCount: Int
    let hasCritical: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Alert indicator
                ZStack {
                    Circle()
                        .fill(hasCritical ? AttentionCategory.syncFailure.color : AttentionCategory.balanceAlert.color)
                        .frame(width: 8, height: 8)
                    
                    if hasCritical {
                        Circle()
                            .fill(AttentionCategory.syncFailure.color.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .modifier(PulseAnimationModifier())
                    }
                }
                
                Text("\(itemCount) \(itemCount == 1 ? "item needs" : "items need") attention")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Mute Preferences Sheet

/// Sheet for managing muted insight types
/// UX: "Silent Mode" for repetitive advisory insights
struct MutePreferencesSheet: View {
    @ObservedObject var viewModel: AttentionCenterViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(MutedInsightType.allCases, id: \.rawValue) { type in
                        MuteToggleRow(
                            type: type,
                            isMuted: viewModel.isMuted(type),
                            onToggle: {
                                viewModel.toggleMute(for: type)
                            }
                        )
                    }
                } header: {
                    Text("Advisory Notifications")
                } footer: {
                    Text("Muted insights won't appear in your attention feed. Critical sync errors will always be shown.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notification Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

/// Individual toggle row for mute preference
private struct MuteToggleRow: View {
    let type: MutedInsightType
    let isMuted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(typeDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { !isMuted },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
    
    private var typeDescription: String {
        switch type {
        case .lowBalanceAlerts:
            return "Alerts when account balances drop below thresholds"
        case .uncategorizedTransactions:
            return "Prompts to categorize large transactions"
        case .spendingSpikes:
            return "Notifications about unusual spending patterns"
        }
    }
}

// MARK: - Animation Modifiers

/// Pulse animation for critical status icons
private struct PulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.6 : 1.0)
            .scaleEffect(isPulsing ? 1.15 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// Icon animation modifier based on priority
private struct IconAnimationModifier: ViewModifier {
    let animation: AttentionPriority.IconAnimation
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        switch animation {
        case .pulse:
            content
                .scaleEffect(isAnimating ? 1.08 : 1.0)
                .opacity(isAnimating ? 0.85 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }
            
        case .subtle:
            content
                .opacity(isAnimating ? 0.9 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }
            
        case .none:
            content
        }
    }
}

// MARK: - Success Toast

/// Temporary toast for success messages
struct AttentionSuccessToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.75, blue: 0.45))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Previews

#Preview("Attention Center - Multiple Items") {
    let viewModel = AttentionCenterViewModel()
    VStack {
        AttentionCenterView(
            viewModel: viewModel,
            isPrivacyMode: false,
            onAction: { _ in }
        )
        Spacer()
    }
    .padding(.top, 20)
    .background(Color(.systemGroupedBackground))
    .task {
        #if DEBUG
        viewModel.loadSampleData()
        #endif
    }
}

#Preview("Attention Center - All Clear") {
    let viewModel = AttentionCenterViewModel()
    
    VStack {
        AttentionCenterView(
            viewModel: viewModel,
            isPrivacyMode: false,
            onAction: { _ in }
        )
        Spacer()
    }
    .padding(.top, 20)
    .background(Color(.systemGroupedBackground))
}

#Preview("Attention Card - Critical") {
    AttentionCard(
        item: AttentionItem.sampleItems[0],
        isPrivacyMode: false,
        isResolving: false,
        onAction: {},
        onDismiss: nil
    )
    .frame(width: 320, height: 140)
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Attention Card - Advisory") {
    AttentionCard(
        item: AttentionItem.sampleItems[1],
        isPrivacyMode: false,
        isResolving: false,
        onAction: {},
        onDismiss: {}
    )
    .frame(width: 320, height: 140)
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Header") {
    VStack {
        CompactAttentionHeader(
            itemCount: 3,
            hasCritical: true,
            onTap: {}
        )
        .padding()
        
        CompactAttentionHeader(
            itemCount: 2,
            hasCritical: false,
            onTap: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Mute Preferences") {
    let viewModel = AttentionCenterViewModel()
    
    MutePreferencesSheet(viewModel: viewModel)
}
