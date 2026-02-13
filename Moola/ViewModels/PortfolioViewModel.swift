import Foundation
import Combine
import SwiftUI

/// ViewModel managing the Pulse dashboard state
/// UX Intent: Provide a fast, responsive experience with smart data refresh
/// Implements debouncing to prevent excessive API calls
final class PortfolioViewModel: ObservableObject {
    private let linkedAccountIdsKey = "linked_account_ids"
    
    // MARK: - Published State
    
    /// Current portfolio summary data
    @Published private(set) var portfolio: PortfolioSummary = .empty
    
    /// Whether data is currently being fetched
    @Published private(set) var isLoading: Bool = false
    
    /// Whether initial load is complete
    @Published private(set) var hasLoadedOnce: Bool = false
    
    /// Error message if fetch failed
    @Published var errorMessage: String?
    
    /// Whether balances should be hidden for privacy
    @Published var isPrivacyModeEnabled: Bool = false {
        didSet {
            // Persist privacy preference
            UserDefaults.standard.set(isPrivacyModeEnabled, forKey: "pulse_privacy_mode")
        }
    }
    
    /// Current balance display mode (Net Worth vs Invested)
    @Published var balanceDisplayMode: BalanceDisplayMode = .totalNetWorth
    
    /// Whether the screen is currently being refreshed via pull-to-refresh
    @Published var isRefreshing: Bool = false
    
    // MARK: - Private Properties
    
    /// Last time data was fetched (for debouncing)
    private var lastFetchTime: Date?
    
    /// Minimum interval between fetches (debounce)
    private let minimumFetchInterval: TimeInterval = 30 // 30 seconds
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Timer for auto-refresh (optional background updates)
    private var autoRefreshTimer: Timer?
    
    // MARK: - Computed Properties
    
    /// Current balance based on display mode
    var displayBalance: Decimal {
        switch balanceDisplayMode {
        case .totalNetWorth:
            return portfolio.totalBalance
        case .investedCapital:
            return portfolio.investedCapital
        }
    }
    
    /// Formatted balance string
    var formattedBalance: String {
        if isPrivacyModeEnabled {
            return "••••••"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        return formatter.string(from: NSDecimalNumber(decimal: displayBalance)) ?? "$0.00"
    }
    
    /// Whether there are any linked accounts
    var hasAccounts: Bool {
        !portfolio.accounts.isEmpty
    }
    
    /// Whether data is stale and needs refresh indicator
    var showStaleIndicator: Bool {
        portfolio.isStale && hasLoadedOnce
    }
    
    /// Number of unread notifications (mock for now)
    var notificationCount: Int {
        3 // Mock value - would come from notification service
    }
    
    // MARK: - Initialization
    
    init() {
        // Restore privacy preference
        isPrivacyModeEnabled = UserDefaults.standard.bool(forKey: "pulse_privacy_mode")
    }
    
    deinit {
        autoRefreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Fetches portfolio data with debounce protection
    /// UX: Prevents hammering the API on rapid screen opens
    @MainActor
    func fetchPortfolio(force: Bool = false) async {
        // Debounce check - skip if recently fetched (unless forced)
        if !force, let lastFetch = lastFetchTime {
            let timeSinceFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceFetch < minimumFetchInterval {
                // Data is fresh enough, skip fetch
                return
            }
        }
        
        // Don't start another fetch if already loading
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate network fetch (replace with actual API call)
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8s
            
            // If no linked accounts exist, show empty state (avoid demo data).
            let linkedIds = UserDefaults.standard.stringArray(forKey: linkedAccountIdsKey) ?? []
            if linkedIds.isEmpty {
                portfolio = .empty
            } else {
                // Connected demo data (single source of truth).
                let userKey = DemoDataStore.shared.currentUserKeyFromStoredUser() ?? "guest"
                DemoDataStore.shared.ensureSeededIfNeeded(for: userKey)
                portfolio = DemoDataStore.shared.portfolioSummary(for: userKey)
            }
            lastFetchTime = Date()
            hasLoadedOnce = true
            
        } catch {
            if !Task.isCancelled {
                errorMessage = "Unable to refresh portfolio"
            }
        }
        
        isLoading = false
        isRefreshing = false
    }
    
    /// Pull-to-refresh handler
    /// UX: Provides haptic feedback and forces a fresh fetch
    @MainActor
    func refresh() async {
        // Haptic feedback for pull-to-refresh
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        isRefreshing = true
        
        // Force refresh bypasses debounce
        await fetchPortfolio(force: true)
        
        // Success haptic
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
    }
    
    /// Toggles privacy mode
    func togglePrivacyMode() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isPrivacyModeEnabled.toggle()
        }
    }
    
    /// Toggles between balance display modes
    func toggleBalanceDisplayMode() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        withAnimation(.easeInOut(duration: 0.25)) {
            balanceDisplayMode = balanceDisplayMode.next
        }
    }
    
    /// Starts auto-refresh timer (called when view appears)
    func startAutoRefresh() {
        // Refresh every 5 minutes in the background
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchPortfolio()
            }
        }
    }
    
    /// Stops auto-refresh timer (called when view disappears)
    func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    // MARK: - Action Handlers
    
    /// Handles quick action button taps
    func handleQuickAction(_ action: QuickAction) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // In production, these would navigate to respective screens
        switch action {
        case .addBank:
            // Navigate to bank linking flow
            break
        case .transfer:
            // Navigate to transfer screen
            break
        case .analysis:
            // Navigate to portfolio analysis
            break
        case .budget:
            // Navigate to budget screen
            break
        }
    }
}

// MARK: - Preview Helpers

extension PortfolioViewModel {
    /// Creates a preview instance with sample data loaded
    static var preview: PortfolioViewModel {
        let viewModel = PortfolioViewModel()
        viewModel.portfolio = .sample
        viewModel.hasLoadedOnce = true
        return viewModel
    }
    
    /// Creates a preview instance with stale data
    static var previewStale: PortfolioViewModel {
        let viewModel = PortfolioViewModel()
        viewModel.portfolio = .staleData
        viewModel.hasLoadedOnce = true
        return viewModel
    }
    
    /// Creates a preview instance with no accounts (zero state)
    static var previewEmpty: PortfolioViewModel {
        let viewModel = PortfolioViewModel()
        viewModel.portfolio = .empty
        viewModel.hasLoadedOnce = true
        return viewModel
    }
    
    /// Creates a preview instance in loading state
    static var previewLoading: PortfolioViewModel {
        let viewModel = PortfolioViewModel()
        viewModel.isLoading = true
        return viewModel
    }
}
