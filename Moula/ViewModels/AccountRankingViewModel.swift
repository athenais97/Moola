import Foundation
import Combine
import SwiftUI

/// ViewModel for the Account Ranking (Top Performers) view
@MainActor
final class AccountRankingViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var rankedAccounts: [RankedAccount] = []
    @Published private(set) var insufficientDataAccounts: [RankedAccount] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var rankingState: RankingState = .loading
    @Published private(set) var hasLoadedOnce: Bool = false
    
    @Published var selectedMetric: PerformanceMetric = .percentage
    @Published var selectedTimeframe: PerformanceTimeframe = .week
    @Published var isPrivacyModeEnabled: Bool = false
    
    // MARK: - Computed Properties
    
    var hasData: Bool {
        !rankedAccounts.isEmpty
    }
    
    var topPerformer: RankedAccount? {
        rankedAccounts.first
    }
    
    /// Bar fill values (0...1) for each account
    var barFills: [String: CGFloat] {
        guard let maxValue = rankedAccounts.map({ abs(NSDecimalNumber(decimal: $0.percentageGain).doubleValue) }).max(),
              maxValue > 0 else {
            return [:]
        }
        
        var fills: [String: CGFloat] = [:]
        for account in rankedAccounts {
            let value = abs(NSDecimalNumber(decimal: account.percentageGain).doubleValue)
            fills[account.id] = CGFloat(value / maxValue)
        }
        return fills
    }
    
    /// Bar colors for each account based on performance
    var barColors: [String: Color] {
        var colors: [String: Color] = [:]
        for account in rankedAccounts {
            colors[account.id] = account.performanceColor
        }
        return colors
    }
    
    // MARK: - Data Loading
    
    func fetchRankingData() async {
        guard !isLoading else { return }
        
        isLoading = true
        rankingState = .loading
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 800_000_000)

            let linkedIds = UserDefaults.standard.stringArray(forKey: "linked_account_ids") ?? []
            guard !linkedIds.isEmpty else {
                rankedAccounts = []
                insufficientDataAccounts = []
                rankingState = .noAccounts
                hasLoadedOnce = true
                isLoading = false
                return
            }

            // Connected demo data (single source of truth).
            let userKey = DemoDataStore.shared.currentUserKeyFromStoredUser() ?? "guest"
            DemoDataStore.shared.ensureSeededIfNeeded(for: userKey)
            let accounts = DemoDataStore.shared.rankedAccounts(for: userKey, timeframe: selectedTimeframe)
            
            // Sort by percentage gain (descending)
            let sorted = accounts.sorted { $0.percentageGain > $1.percentageGain }
            
            // Separate insufficient data accounts
            let ranked = sorted.filter { !$0.hasInsufficientData }
            let insufficient = sorted.filter { $0.hasInsufficientData }
            
            // Determine state
            let state: RankingState
            if ranked.isEmpty && insufficient.isEmpty {
                state = .noAccounts
            } else if ranked.isEmpty {
                state = .insufficientData
            } else if ranked.allSatisfy({ $0.absoluteGain < 0 }) {
                state = .allNegative
            } else {
                state = .loaded
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                rankedAccounts = ranked
                insufficientDataAccounts = insufficient
                rankingState = state
                hasLoadedOnce = true
                isLoading = false
            }
            
        } catch {
            rankingState = .error("Unable to load rankings")
            isLoading = false
        }
    }
    
    func refresh() async {
        await fetchRankingData()
    }
    
    // MARK: - Privacy
    
    func togglePrivacyMode() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isPrivacyModeEnabled.toggle()
        }
    }
    
    // MARK: - Cleanup
    
    func clearSensitiveData() {
        rankedAccounts = []
        insufficientDataAccounts = []
    }
}
