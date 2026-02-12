import Foundation
import Combine
import SwiftUI

/// ViewModel managing the Attention Center state and interactions
///
/// UX Intent:
/// - Surfaces at-risk or noteworthy accounts requiring user action
/// - Distinguishes between Critical Errors and Advisory Insights
/// - Provides immediate, one-tap resolution paths
///
/// Foundation Compliance:
/// - Reduce cognitive load: Items pre-sorted by priority
/// - Every interaction provides clear visual feedback
/// - Errors are helpful and never blaming
@MainActor
final class AttentionCenterViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current attention state with all items and filters
    @Published private(set) var state: AttentionState = .empty
    
    /// Loading state for data fetch
    @Published private(set) var isLoading: Bool = false
    
    /// Whether the attention center is collapsed/minimized
    @Published var isCollapsed: Bool = false
    
    /// Currently focused item index (for carousel)
    @Published var focusedIndex: Int = 0
    
    /// Item being resolved (shows loading state on card)
    @Published private(set) var resolvingItemId: String?
    
    /// Whether to show mute preferences sheet
    @Published var showMutePreferences: Bool = false
    
    /// Success message for temporary toast display
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Haptic generators
    private let warningHaptic = UINotificationFeedbackGenerator()
    private let selectionHaptic = UISelectionFeedbackGenerator()
    private let impactHaptic = UIImpactFeedbackGenerator(style: .light)
    
    // MARK: - Computed Properties
    
    /// Active items to display
    var activeItems: [AttentionItem] {
        state.activeItems
    }
    
    /// Whether there are any items to display
    var hasItems: Bool {
        !state.activeItems.isEmpty
    }
    
    /// Whether all items are clear (show success state)
    var isAllClear: Bool {
        state.isAllClear
    }
    
    /// Header message text
    var headerMessage: String {
        state.headerMessage
    }
    
    /// Count badge number (nil if 0)
    var badgeCount: Int? {
        let count = state.totalCount
        return count > 0 ? count : nil
    }
    
    /// Whether there are critical items requiring immediate action
    var hasCriticalItems: Bool {
        state.criticalCount > 0
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Auto-clear success message after delay
        $successMessage
            .compactMap { $0 }
            .delay(for: .seconds(2.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.successMessage = nil
                }
            }
            .store(in: &cancellables)
        
        // Trigger warning haptic when scrolling to critical item
        $focusedIndex
            .removeDuplicates()
            .sink { [weak self] index in
                guard let self = self else { return }
                let items = self.activeItems
                guard index < items.count else { return }
                
                let item = items[index]
                if item.priority.triggersHaptic {
                    self.warningHaptic.notificationOccurred(.warning)
                } else {
                    self.selectionHaptic.selectionChanged()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    /// Fetches attention items from backend/local cache
    /// UX: Fast local calculation to avoid dashboard latency
    func fetchItems() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            // Simulate brief delay (in production: local calculation or cached data)
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            
            // Load items (in production: from local database + background sync)
            let items = AttentionItem.sampleItems
            
            // Load persisted dismissed/muted preferences
            let dismissedIds = loadDismissedItemIds()
            let mutedTypes = loadMutedTypes()
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                state = AttentionState(
                    items: items,
                    dismissedItemIds: dismissedIds,
                    mutedTypes: mutedTypes,
                    recentlyResolvedIds: []
                )
            }
            
            isLoading = false
        } catch {
            isLoading = false
        }
    }
    
    /// Refreshes attention items
    func refresh() async {
        await fetchItems()
    }
    
    // MARK: - Item Actions
    
    /// Executes the primary action for an attention item
    /// Returns the action type for navigation handling
    func executeAction(for item: AttentionItem) -> AttentionAction.ActionType {
        impactHaptic.impactOccurred()
        
        // Mark as resolving for loading state
        resolvingItemId = item.id
        
        // Return action type for parent view to handle navigation
        return item.action.actionType
    }
    
    /// Marks an item as resolved (removes with animation)
    func markResolved(itemId: String) {
        guard state.items.contains(where: { $0.id == itemId }) else { return }
        
        // Add to recently resolved for collapse animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            state.recentlyResolvedIds.insert(itemId)
        }
        
        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            withAnimation(.easeOut(duration: 0.25)) {
                self?.state.items.removeAll { $0.id == itemId }
                self?.state.recentlyResolvedIds.remove(itemId)
                self?.resolvingItemId = nil
            }
        }
        
        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show success toast
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            successMessage = "Issue resolved"
        }
    }
    
    /// Clears the resolving state (e.g., if action was cancelled)
    func clearResolvingState() {
        resolvingItemId = nil
    }
    
    // MARK: - Dismiss Actions
    
    /// Dismisses an advisory item (only works for dismissible items)
    /// UX: "Swipe to dismiss" pattern for advisories
    func dismissItem(_ item: AttentionItem) {
        guard item.isDismissible else {
            // Critical items cannot be dismissed
            warningHaptic.notificationOccurred(.error)
            return
        }
        
        impactHaptic.impactOccurred()
        
        // Add to dismissed set
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            state.dismissedItemIds.insert(item.id)
        }
        
        // Persist preference
        saveDismissedItemIds(state.dismissedItemIds)
        
        // Adjust focused index if needed
        if focusedIndex >= activeItems.count {
            focusedIndex = max(0, activeItems.count - 1)
        }
    }
    
    /// Restores a dismissed item (undo)
    func restoreDismissedItem(id: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            state.dismissedItemIds.remove(id)
        }
        saveDismissedItemIds(state.dismissedItemIds)
    }
    
    // MARK: - Mute Preferences
    
    /// Toggles mute status for an insight type
    func toggleMute(for type: MutedInsightType) {
        impactHaptic.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if state.mutedTypes.contains(type) {
                state.mutedTypes.remove(type)
            } else {
                state.mutedTypes.insert(type)
            }
        }
        
        saveMutedTypes(state.mutedTypes)
    }
    
    /// Checks if a type is muted
    func isMuted(_ type: MutedInsightType) -> Bool {
        state.mutedTypes.contains(type)
    }
    
    // MARK: - Carousel Navigation
    
    /// Moves to the next item in carousel
    func moveToNextItem() {
        guard focusedIndex < activeItems.count - 1 else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            focusedIndex += 1
        }
    }
    
    /// Moves to the previous item in carousel
    func moveToPreviousItem() {
        guard focusedIndex > 0 else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            focusedIndex -= 1
        }
    }
    
    /// Moves to specific item
    func moveToItem(at index: Int) {
        guard index >= 0 && index < activeItems.count else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            focusedIndex = index
        }
    }
    
    // MARK: - Persistence (UserDefaults for MVP)
    
    private let dismissedIdsKey = "attentionCenter.dismissedIds"
    private let mutedTypesKey = "attentionCenter.mutedTypes"
    
    private func loadDismissedItemIds() -> Set<String> {
        let ids = UserDefaults.standard.stringArray(forKey: dismissedIdsKey) ?? []
        return Set(ids)
    }
    
    private func saveDismissedItemIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: dismissedIdsKey)
    }
    
    private func loadMutedTypes() -> Set<MutedInsightType> {
        guard let data = UserDefaults.standard.data(forKey: mutedTypesKey),
              let types = try? JSONDecoder().decode([MutedInsightType].self, from: data) else {
            return []
        }
        return Set(types)
    }
    
    private func saveMutedTypes(_ types: Set<MutedInsightType>) {
        if let data = try? JSONEncoder().encode(Array(types)) {
            UserDefaults.standard.set(data, forKey: mutedTypesKey)
        }
    }
    
    // MARK: - Debug/Preview Helpers
    
    #if DEBUG
    /// Loads sample data for previews
    func loadSampleData() {
        state = AttentionState(
            items: AttentionItem.sampleItems,
            dismissedItemIds: [],
            mutedTypes: [],
            recentlyResolvedIds: []
        )
    }
    
    /// Simulates clearing all items
    func simulateClearAll() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            state.items.removeAll()
        }
    }
    #endif
}
