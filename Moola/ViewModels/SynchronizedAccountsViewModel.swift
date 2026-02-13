import Foundation
import Combine
import SwiftUI

/// ViewModel managing the synchronized accounts screen state
/// Handles data loading, privacy mode, institution expansion, and user actions
/// UX Intent: Smooth state management with appropriate loading and error feedback
@MainActor
final class SynchronizedAccountsViewModel: ObservableObject {
    private let linkedAccountIdsKey = "linked_account_ids"
    
    // MARK: - Published State
    
    /// Current loading state
    @Published private(set) var loadingState: LoadingState = .idle
    
    /// All synchronized institutions
    @Published private(set) var institutions: [SynchronizedInstitution] = []
    
    /// Aggregated portfolio data
    @Published private(set) var portfolio: AggregatedPortfolio = .empty
    
    /// Whether privacy mode is enabled (hide all balances)
    @Published var isPrivacyModeEnabled: Bool = false
    
    /// IDs of expanded institutions
    @Published private(set) var expandedInstitutionIds: Set<String> = []
    
    /// Institution pending reconnection
    @Published var institutionToReconnect: SynchronizedInstitution?
    
    /// Error message to display
    @Published var errorMessage: String?
    
    /// Whether the add account flow should be shown
    @Published var showAddAccount: Bool = false
    
    /// Whether a sync is in progress
    @Published private(set) var isSyncing: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let baseCurrencyCode: String = "USD"
    
    // MARK: - Computed Properties
    
    /// Whether data has been loaded at least once
    var hasLoadedOnce: Bool {
        loadingState == .loaded || loadingState == .refreshing
    }
    
    /// Whether there are any linked institutions
    var hasInstitutions: Bool {
        !institutions.isEmpty
    }
    
    /// Total number of accounts across all institutions
    var totalAccountCount: Int {
        institutions.reduce(0) { $0 + $1.accounts.count }
    }
    
    /// Number of institutions needing attention
    var attentionCount: Int {
        institutions.filter { $0.needsAttention }.count
    }
    
    // MARK: - Loading State
    
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case refreshing
        case error(String)
        
        var isLoading: Bool {
            self == .loading
        }
        
        var isRefreshing: Bool {
            self == .refreshing
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Auto-expand first institution on load
        $institutions
            .sink { [weak self] institutions in
                if let first = institutions.first, self?.expandedInstitutionIds.isEmpty == true {
                    self?.expandedInstitutionIds.insert(first.id)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    /// Fetches synchronized institutions from the backend
    func fetchInstitutions() async {
        guard loadingState != .loading else { return }
        
        loadingState = hasLoadedOnce ? .refreshing : .loading
        errorMessage = nil
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s

            // If no linked accounts exist, show an empty state (avoid demo data).
            let linkedIds = UserDefaults.standard.stringArray(forKey: linkedAccountIdsKey) ?? []
            guard !linkedIds.isEmpty else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    institutions = []
                    portfolio = .empty
                    loadingState = .loaded
                }
                return
            }

            // Connected demo data (single source of truth).
            let userKey = DemoDataStore.shared.currentUserKeyFromStoredUser() ?? "guest"
            DemoDataStore.shared.ensureSeededIfNeeded(for: userKey)
            institutions = DemoDataStore.shared.synchronizedInstitutions(for: userKey)
            
            // Update portfolio aggregation
            portfolio = AggregatedPortfolio(
                institutions: institutions,
                baseCurrencyCode: baseCurrencyCode
            )
            
            loadingState = .loaded
        } catch {
            loadingState = .error("Unable to load accounts. Please try again.")
            errorMessage = "Unable to load accounts. Please try again."
        }
    }
    
    /// Refreshes data (pull-to-refresh)
    func refresh() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        loadingState = .refreshing
        
        do {
            // Simulate sync delay
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8s

            let linkedIds = UserDefaults.standard.stringArray(forKey: linkedAccountIdsKey) ?? []
            guard !linkedIds.isEmpty else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    institutions = []
                    portfolio = .empty
                    loadingState = .loaded
                }
                isSyncing = false
                return
            }
            
            // Re-fetch data (connected demo)
            let userKey = DemoDataStore.shared.currentUserKeyFromStoredUser() ?? "guest"
            DemoDataStore.shared.ensureSeededIfNeeded(for: userKey)
            institutions = DemoDataStore.shared.synchronizedInstitutions(for: userKey)
            portfolio = AggregatedPortfolio(
                institutions: institutions,
                baseCurrencyCode: baseCurrencyCode
            )
            
            // Haptic feedback for successful sync
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            loadingState = .loaded
            isSyncing = false
        } catch {
            isSyncing = false
            loadingState = .error("Sync failed. Please try again.")
        }
    }
    
    // MARK: - Privacy Mode
    
    /// Toggles privacy mode (hide/show balances)
    func togglePrivacyMode() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isPrivacyModeEnabled.toggle()
        }
    }
    
    // MARK: - Institution Expansion
    
    /// Toggles expansion state for an institution
    func toggleExpansion(for institution: SynchronizedInstitution) {
        if expandedInstitutionIds.contains(institution.id) {
            expandedInstitutionIds.remove(institution.id)
        } else {
            expandedInstitutionIds.insert(institution.id)
        }
    }
    
    /// Checks if an institution is expanded
    func isExpanded(_ institution: SynchronizedInstitution) -> Bool {
        expandedInstitutionIds.contains(institution.id)
    }
    
    /// Expands all institutions
    func expandAll() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            expandedInstitutionIds = Set(institutions.map { $0.id })
        }
    }
    
    /// Collapses all institutions
    func collapseAll() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            expandedInstitutionIds.removeAll()
        }
    }
    
    // MARK: - Institution Actions
    
    /// Initiates reconnection flow for an institution
    func initiateReconnection(for institution: SynchronizedInstitution) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        institutionToReconnect = institution
    }
    
    /// Unlinks an institution and all its accounts
    func unlinkInstitution(_ institution: SynchronizedInstitution) async -> Bool {
        // Haptic for destructive action
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6s
            
            // Remove from local state
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                institutions.removeAll { $0.id == institution.id }
                expandedInstitutionIds.remove(institution.id)
                
                // Update portfolio
                portfolio = AggregatedPortfolio(
                    institutions: institutions,
                    baseCurrencyCode: baseCurrencyCode
                )
            }

            // If this was the last institution, clear linked accounts.
            if institutions.isEmpty {
                UserDefaults.standard.removeObject(forKey: linkedAccountIdsKey)
            }
            
            // Success haptic
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
            
            return true
        } catch {
            errorMessage = "Failed to unlink \(institution.name). Please try again."
            return false
        }
    }
    
    // MARK: - Account Actions
    
    /// Handles tap on an individual account
    func handleAccountTap(_ account: SynchronizedAccount, in institution: SynchronizedInstitution) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        // In production, this would navigate to account details
        print("Tapped account: \(account.name) at \(institution.name)")
    }
    
    // MARK: - Add Account Flow
    
    /// Initiates the add account flow
    func initiateAddAccount() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        showAddAccount = true
    }
    
    /// Handles completion of add account flow
    func handleAddAccountCompletion(accountIds: [String]) {
        showAddAccount = false

        // Persist linked account IDs so other screens (Home, Portfolio) unlock.
        UserDefaults.standard.set(accountIds, forKey: linkedAccountIdsKey)
        
        // Refresh data to show new accounts
        Task {
            await fetchInstitutions()
        }
    }
    
    /// Handles cancellation of add account flow
    func handleAddAccountCancellation() {
        showAddAccount = false
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        errorMessage = nil
    }
    
    /// Retries the last failed operation
    func retry() async {
        errorMessage = nil
        await fetchInstitutions()
    }
}
