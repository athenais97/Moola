import SwiftUI

/// Account Performance Ranking View — "The Leaderboard"
///
/// UX Intent:
/// - Answer "Which account is generating the highest return?"
/// - Visual comparison through relative performance bars
/// - Celebrate the winner with distinct podium styling
///
/// Foundation Compliance:
/// - One clear intent: Identify top-performing accounts
/// - Mobile-first with thumb-friendly controls
/// - Scannable in seconds with clear visual hierarchy
/// - Fast, fluid, and intentional with smooth reordering animations
/// - Privacy: Absolute values maskable while preserving relative comparison
///
/// Design Rationale:
/// Relative Bars vs Raw Numbers: A relative bar is more useful than just showing
/// raw numbers because it provides immediate visual context. Users can instantly
/// see how accounts compare without mental math. The bar length encodes the
/// comparison, making the "best" performer obvious at a glance. This is especially
/// important when comparing currency vs percentage gains—a $50 gain in a $500
/// account (10%) may be more impressive than a $200 gain in a $20,000 account (1%).
struct AccountRankingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AccountRankingViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    // Navigation state
    @State private var selectedAccount: RankedAccount?
    @State private var showingAccountDetail: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content
                mainContent
                
                // Loading overlay for initial load
                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    loadingOverlay
                }
                
                // Empty state
                if viewModel.hasLoadedOnce && !viewModel.hasData && viewModel.insufficientDataAccounts.isEmpty {
                    RankingEmptyState(state: viewModel.rankingState)
                }
            }
            .navigationTitle("Top Performers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    privacyButton
                }
            }
            .navigationDestination(isPresented: $showingAccountDetail) {
                if let account = selectedAccount {
                    AccountDetailDestination(account: account)
                }
            }
        }
        .task {
            await viewModel.fetchRankingData()
        }
        .onDisappear {
            // Privacy requirement: Clear data from memory
            viewModel.clearSensitiveData()
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with metric toggle and timeframe
                headerSection
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                
                // Defensive mode banner (if all negative)
                if viewModel.rankingState == .allNegative {
                    DefensiveModeBanner()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Podium card for #1
                if let topPerformer = viewModel.topPerformer {
                    podiumSection(account: topPerformer)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                }
                
                // Ranking list (positions 2+)
                rankingListSection
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                
                // Insufficient data accounts
                if !viewModel.insufficientDataAccounts.isEmpty {
                    insufficientDataSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                }
                
                // Bottom spacing
                Spacer(minLength: 40)
            }
            .padding(.bottom, 16)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Controls row
            HStack {
                // Metric toggle
                MetricToggle(selectedMetric: $viewModel.selectedMetric)
                
                Spacer()
                
                // Timeframe
                TimeframeSegmentedControl(selectedTimeframe: $viewModel.selectedTimeframe)
            }
        }
    }
    
    // MARK: - Podium Section
    
    private func podiumSection(account: RankedAccount) -> some View {
        Button(action: {
            triggerSelectionHaptic()
            selectedAccount = account
            showingAccountDetail = true
        }) {
            PodiumCard(
                account: account,
                metric: viewModel.selectedMetric,
                isPrivacyMode: viewModel.isPrivacyModeEnabled,
                isDefensiveMode: viewModel.rankingState.isDefensiveMode
            )
        }
        .buttonStyle(PodiumButtonStyle())
    }
    
    // MARK: - Ranking List Section
    
    private var rankingListSection: some View {
        VStack(spacing: 0) {
            // Section header
            if viewModel.rankedAccounts.count > 1 {
                HStack {
                    Text("ALL ACCOUNTS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(viewModel.rankedAccounts.count) ranked")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
            
            // Ranking rows (skip position 1 as it's in podium)
            VStack(spacing: 0) {
                ForEach(Array(viewModel.rankedAccounts.dropFirst().enumerated()), id: \.element.id) { index, account in
                    let rank = index + 2 // Position 2 onwards
                    
                    RankingRow(
                        account: account,
                        rank: rank,
                        metric: viewModel.selectedMetric,
                        barFill: viewModel.barFills[account.id] ?? 0.5,
                        barColor: viewModel.barColors[account.id] ?? .secondary,
                        isPrivacyMode: viewModel.isPrivacyModeEnabled,
                        isDefensiveMode: viewModel.rankingState.isDefensiveMode,
                        onTap: {
                            triggerSelectionHaptic()
                            selectedAccount = account
                            showingAccountDetail = true
                        }
                    )
                    .id(account.id) // For animation identity
                    
                    if index < viewModel.rankedAccounts.count - 2 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.rankedAccounts.map { $0.id })
        }
    }
    
    // MARK: - Insufficient Data Section
    
    private var insufficientDataSection: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("CALCULATING")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("< 24h of data")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
            
            // Insufficient data rows
            VStack(spacing: 0) {
                ForEach(viewModel.insufficientDataAccounts) { account in
                    InsufficientDataRow(account: account)
                    
                    if account.id != viewModel.insufficientDataAccounts.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.systemBackground).opacity(0.6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        RankingSkeleton()
            .transition(.opacity)
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Privacy Button
    
    private var privacyButton: some View {
        Button(action: {
            viewModel.togglePrivacyMode()
        }) {
            Image(systemName: viewModel.isPrivacyModeEnabled ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(viewModel.isPrivacyModeEnabled ? .accentColor : .secondary)
        }
        .accessibilityLabel(viewModel.isPrivacyModeEnabled ? "Show values" : "Hide values")
    }
    
    // MARK: - Haptics
    
    private func triggerSelectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Button Styles

private struct PodiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Account Detail Destination

/// Placeholder for account detail navigation
/// In production, this would navigate to the full account analytics view
private struct AccountDetailDestination: View {
    let account: RankedAccount
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(account.brandColor.opacity(0.15))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: account.institutionLogoName)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(account.brandColor)
                    }
                    
                    Text(account.accountName)
                        .font(.system(size: 22, weight: .bold))
                    
                    Text(account.institutionName)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Performance summary
                VStack(spacing: 16) {
                    performanceRow(label: "Absolute Gain", value: account.formattedAbsoluteGain)
                    performanceRow(label: "Percentage Gain", value: account.formattedPercentageGain)
                    performanceRow(label: "Current Balance", value: formatBalance(account.currentBalance))
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // Sparkline
                if !account.balanceHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PERFORMANCE TREND")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        SparklineView(
                            dataPoints: account.balanceHistory,
                            isPositive: account.isPositive,
                            height: 120
                        )
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Account Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performanceRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(account.performanceColor)
        }
    }
    
    private func formatBalance(_ balance: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "$0.00"
    }
}

// MARK: - Previews

#Preview("Account Ranking - Normal") {
    let appState = AppState()
    appState.currentUser = UserModel(
        name: "Sarah Johnson",
        age: 32,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: "",
        membershipLevel: .premium
    )
    
    return AccountRankingView()
        .environmentObject(appState)
}

#Preview("Account Ranking - Dark Mode") {
    let appState = AppState()
    appState.currentUser = UserModel(
        name: "Sarah Johnson",
        age: 32,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: "",
        membershipLevel: .premium
    )
    
    return AccountRankingView()
        .environmentObject(appState)
        .preferredColorScheme(.dark)
}

#Preview("Account Ranking - Loading") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        RankingSkeleton()
    }
}

#Preview("Account Ranking - Defensive Mode") {
    // This would show all negative accounts
    let appState = AppState()
    appState.currentUser = UserModel(
        name: "Sarah Johnson",
        age: 32,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: "",
        membershipLevel: .premium
    )
    
    return AccountRankingView()
        .environmentObject(appState)
}
