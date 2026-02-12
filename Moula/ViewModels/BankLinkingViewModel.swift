import Foundation
import Combine
import SwiftUI

/// ViewModel managing the bank linking stepper flow
/// Handles bank selection, OAuth coordination, and account selection
/// UX Intent: Fluid transitions between steps with appropriate feedback
@MainActor
final class BankLinkingViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current step in the linking flow
    @Published private(set) var currentStep: BankLinkingStep = .bankSelection
    
    /// All available banks
    @Published private(set) var allBanks: [Bank] = Bank.sampleBanks
    
    /// Search query for filtering banks
    @Published var searchQuery: String = ""
    
    /// Currently selected bank
    @Published private(set) var selectedBank: Bank?
    
    /// Connection state for the OAuth process
    @Published private(set) var connectionState: BankConnectionState = .idle
    
    /// Available accounts after successful connection
    @Published private(set) var availableAccounts: [BankAccount] = []
    
    /// Selected account IDs for syncing
    @Published var selectedAccountIds: Set<String> = []
    
    /// Whether accounts are being loaded
    @Published private(set) var isLoadingAccounts: Bool = false
    
    /// Whether the Safari controller should be presented
    @Published var showSafariController: Bool = false
    
    /// URL to open in Safari controller
    @Published private(set) var safariURL: URL?
    
    /// Error state
    @Published var error: BankConnectionError?
    
    // MARK: - Private Properties
    
    private let linkRequest: BankLinkRequest
    private var cancellables = Set<AnyCancellable>()
    private var connectionTimeoutTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    /// Filtered banks based on search query
    var filteredBanks: [Bank] {
        guard !searchQuery.isEmpty else {
            return allBanks
        }
        return allBanks.filter { bank in
            bank.name.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    /// Popular banks for quick selection
    var popularBanks: [Bank] {
        Bank.popularBanks
    }
    
    /// Whether search is active (has query text)
    var isSearchActive: Bool {
        !searchQuery.isEmpty
    }
    
    /// Number of selected accounts
    var selectedAccountsCount: Int {
        selectedAccountIds.count
    }
    
    /// Whether the confirm button should be enabled
    var canConfirmSelection: Bool {
        !selectedAccountIds.isEmpty
    }
    
    /// Dynamic CTA text for the confirm button
    var confirmButtonTitle: String {
        let count = selectedAccountsCount
        if count == 0 {
            return "Select Accounts to Continue"
        } else if count == 1 {
            return "Confirm Selection (1 Account)"
        } else {
            return "Confirm Selection (\(count) Accounts)"
        }
    }
    
    /// Whether the flow is for re-authentication only
    var isReauthenticationFlow: Bool {
        linkRequest.mode == .updateConnection
    }
    
    // MARK: - Initialization
    
    init(linkRequest: BankLinkRequest = .newConnection) {
        self.linkRequest = linkRequest
        
        // For re-auth, skip directly to secure connection
        if linkRequest.mode == .updateConnection {
            currentStep = .secureConnection
        }
    }
    
    // MARK: - Step Navigation
    
    /// Moves to the next step with animation
    func goToNextStep() {
        guard let nextIndex = BankLinkingStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = nextIndex
        }
    }
    
    /// Handles cancellation/exit from the flow
    func cancel() {
        connectionTimeoutTask?.cancel()
        connectionState = .idle
        selectedBank = nil
        selectedAccountIds.removeAll()
        searchQuery = ""
    }
    
    // MARK: - Step 1: Bank Selection
    
    /// Selects a bank and initiates the connection flow
    func selectBank(_ bank: Bank) {
        selectedBank = bank
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Transition to secure connection step
        goToNextStep()
    }
    
    // MARK: - Step 2: Secure Connection
    
    /// Initiates the OAuth flow for the selected bank
    func initiateSecureConnection() {
        guard let bank = selectedBank else { return }
        
        connectionState = .connecting
        
        // Start timeout monitoring
        startConnectionTimeout()
        
        // Simulate a brief delay before showing Safari (for visual feedback)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            
            guard connectionState == .connecting else { return }
            
            // Set the OAuth URL and show Safari controller
            // In production, this would be the actual bank's OAuth URL
            safariURL = bank.oauthURL ?? URL(string: "https://example.com/oauth")
            connectionState = .awaitingCallback
            showSafariController = true
        }
    }
    
    /// Handles the OAuth callback (called when Safari redirects back)
    func handleOAuthCallback(success: Bool) {
        connectionTimeoutTask?.cancel()
        showSafariController = false
        
        if success {
            connectionState = .processingCallback
            
            // Haptic feedback for success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Fetch accounts from the provider
            fetchAvailableAccounts()
        } else {
            connectionState = .failed(.userCancelled)
            error = .userCancelled
        }
    }
    
    /// Simulates the Safari callback for demo purposes
    func simulateSuccessfulConnection() {
        handleOAuthCallback(success: true)
    }
    
    /// Called when Safari is dismissed without completing
    func handleSafariDismissed() {
        if connectionState == .awaitingCallback {
            connectionState = .failed(.userCancelled)
            error = .userCancelled
        }
    }
    
    // MARK: - Step 3: Account Selection
    
    /// Toggles selection state for an account
    func toggleAccountSelection(_ account: BankAccount) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        if selectedAccountIds.contains(account.id) {
            selectedAccountIds.remove(account.id)
        } else {
            selectedAccountIds.insert(account.id)
        }
    }
    
    /// Checks if an account is selected
    func isAccountSelected(_ account: BankAccount) -> Bool {
        selectedAccountIds.contains(account.id)
    }
    
    /// Selects all available accounts
    func selectAllAccounts() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        selectedAccountIds = Set(availableAccounts.map { $0.id })
    }
    
    /// Deselects all accounts
    func deselectAllAccounts() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        selectedAccountIds.removeAll()
    }
    
    /// Confirms the selection and completes the flow
    func confirmSelection() async -> Bool {
        guard canConfirmSelection else { return false }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Get selected accounts
        let selectedAccounts = availableAccounts.filter { selectedAccountIds.contains($0.id) }
        
        // Simulate API call to link accounts
        do {
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8s
            
            // In production, this would call the API to persist the linked accounts
            print("Linked \(selectedAccounts.count) accounts from \(selectedBank?.name ?? "Unknown")")

            // Persist to connected demo dataset so all screens update consistently.
            if let bank = selectedBank {
                let userKey = DemoDataStore.shared.currentUserKeyFromStoredUser() ?? "guest"
                DemoDataStore.shared.upsertLinkedAccounts(userKey: userKey, bank: bank, accounts: selectedAccounts)
            }
            
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Error Handling
    
    /// Retries the connection after an error
    func retryConnection() {
        error = nil
        connectionState = .idle
        
        if isReauthenticationFlow {
            initiateSecureConnection()
        }
    }
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Methods
    
    private func fetchAvailableAccounts() {
        guard let bank = selectedBank else { return }
        
        isLoadingAccounts = true
        
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
            
            // Get sample accounts (in production, this comes from the provider API)
            let accounts = BankAccount.sampleAccounts(for: bank)
            
            if accounts.isEmpty {
                connectionState = .failed(.noAccountsFound)
                error = .noAccountsFound
            } else {
                availableAccounts = accounts
                connectionState = .success(accounts: accounts)
                
                // Auto-select all accounts by default
                selectedAccountIds = Set(accounts.map { $0.id })
                
                // Transition to account selection step
                goToNextStep()
            }
            
            isLoadingAccounts = false
        }
    }
    
    private func startConnectionTimeout() {
        connectionTimeoutTask?.cancel()
        
        connectionTimeoutTask = Task {
            // 30 second timeout
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard !Task.isCancelled else { return }
            
            if connectionState == .connecting || connectionState == .awaitingCallback {
                connectionState = .failed(.networkTimeout)
                error = .networkTimeout
                showSafariController = false
            }
        }
    }
}
