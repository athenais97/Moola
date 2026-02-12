import SwiftUI
import UIKit

/// Accounts Cards screen
/// - Vertically swipeable card stack (paging)
/// - Bottom sheet with Net Worth + transactions + Performance CTA
struct AccountsCardsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var portfolioViewModel: PortfolioViewModel
    
    @State private var selectedIndex: Int = 0
    @State private var showDetailsSheet: Bool = false
    @State private var detailsDetent: PresentationDetent = .height(420)
    @State private var showPerformance: Bool = false
    @State private var showBankLinking: Bool = false
    
    private let linkedAccountIdsKey = "linked_account_ids"
    
    private var accounts: [PortfolioAccount] {
        portfolioViewModel.portfolio.accounts
    }
    
    private var selectedAccount: PortfolioAccount? {
        guard accounts.indices.contains(selectedIndex) else { return accounts.first }
        return accounts[selectedIndex]
    }
    
    var body: some View {
        ZStack {
            (Color(hex: "FBFBFB") ?? DesignSystem.Colors.backgroundPrimary)
                .ignoresSafeArea()
            
            // Decorative hero gradient (Figma-like)
            VStack(spacing: 0) {
                DesignSystem.Gradients.homeHero
                    .frame(height: 540)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                content
            }
        }
        .flouzeTabBarHidden(true)
        .modifier(HideSystemTabBarOnThisScreen())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: accounts.count) { newCount in
            if newCount > 0, selectedIndex >= newCount {
                selectedIndex = 0
            }
        }
        .sheet(isPresented: $showPerformance) {
            PerformanceView(
                contextTitle: selectedAccount.map { "\($0.institutionName) • \($0.accountName)" },
                accountId: selectedAccount?.id
            )
            .environmentObject(appState)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDetailsSheet) {
            if let account = selectedAccount {
                AccountDetailsSheetView(
                    detent: $detailsDetent,
                    account: account,
                    transactions: scopedTransactions(for: account),
                    isPrivacyMode: portfolioViewModel.isPrivacyModeEnabled,
                    balanceChange: portfolioViewModel.portfolio.balanceChange,
                    onTogglePrivacy: {
                        portfolioViewModel.togglePrivacyMode()
                    },
                    onPerformanceTap: { showPerformance = true }
                )
                .presentationDetents([.height(420), .large], selection: $detailsDetent)
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
                .presentationBackground(DesignSystem.Colors.backgroundCanvas)
            }
        }
        .sheet(isPresented: $showBankLinking) {
            BankLinkingContainerView(onComplete: { accountIds in
                UserDefaults.standard.set(accountIds, forKey: linkedAccountIdsKey)
                showBankLinking = false
                Task { @MainActor in
                    await portfolioViewModel.fetchPortfolio(force: true)
                }
            }, onCancel: {
                showBankLinking = false
            })
        }
        .task {
            // If we arrived before the dashboard loaded, ensure data exists.
            if !portfolioViewModel.hasLoadedOnce {
                await portfolioViewModel.fetchPortfolio()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let account = selectedAccount, !accounts.isEmpty {
                AccountsBottomSelectorSheet(
                    title: selectorTitle(for: account),
                    iconSystemName: account.accountType.iconName,
                    onPrev: selectPrevAccount,
                    onNext: selectNextAccount,
                    onOpenDetails: {
                        detailsDetent = .height(420)
                        showDetailsSheet = true
                    }
                )
                .padding(.bottom, 8)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            
            Spacer(minLength: 0)
            
            Text("Accounts")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer(minLength: 0)
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showBankLinking = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add bank")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .frame(height: 24)
    }
    
    @ViewBuilder
    private var content: some View {
        if let message = portfolioViewModel.errorMessage, accounts.isEmpty {
            errorState(message: message)
        } else if portfolioViewModel.isLoading && !portfolioViewModel.hasLoadedOnce {
            loadingState
        } else if portfolioViewModel.hasLoadedOnce && accounts.isEmpty {
            emptyState
        } else {
            accountsExperience
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.1)
            Text("Loading accounts…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Loading accounts")
    }
    
    private func errorState(message: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text("Couldn’t load accounts")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            
            PrimaryButton(title: "Retry") {
                Task { @MainActor in
                    await portfolioViewModel.fetchPortfolio(force: true)
                }
            }
            .padding(.horizontal, 18)
            
            SecondaryButton(title: "Link an account") {
                showBankLinking = true
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Accounts load error")
    }
    
    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.accent.opacity(0.10))
                    .frame(width: 110, height: 110)
                
                Image(systemName: "creditcard")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            
            VStack(spacing: 8) {
                Text("No accounts yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Connect an account to view your cards, net worth, and recent activity.")
                    .font(.system(size: 15))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            
            PrimaryButton(title: "Link an account") {
                showBankLinking = true
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var accountsExperience: some View {
        GeometryReader { proxy in
            // Give the carousel enough height so shadows never clip.
            let cardAreaHeight = min(proxy.size.height * 0.75, 660)
            
            VStack(spacing: 14) {
                // Slightly higher placement vs previous (reference-like).
                Spacer(minLength: 10)
                
                HorizontalAccountsPager(
                    accounts: accounts,
                    selectedIndex: $selectedIndex,
                    onCardTap: {
                        detailsDetent = .height(280)
                        showDetailsSheet = true
                    }
                )
                .frame(height: cardAreaHeight)
                .padding(.horizontal, 18)
                .accessibilityLabel("Accounts carousel")
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func selectorTitle(for account: PortfolioAccount) -> String {
        // Keep the existing "account name" information, but make it feel like an identifier chip.
        if account.lastFourDigits.isEmpty || account.lastFourDigits == "••••" {
            return account.accountName
        }
        return "\(account.accountName) ••••\(account.lastFourDigits)"
    }
    
    private func selectPrevAccount() {
        guard !accounts.isEmpty else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        selectedIndex = (selectedIndex - 1 + accounts.count) % accounts.count
    }
    
    private func selectNextAccount() {
        guard !accounts.isEmpty else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        selectedIndex = (selectedIndex + 1) % accounts.count
    }
    
    private func scopedTransactions(for account: PortfolioAccount) -> [Transaction] {
        // Current Transaction model stores an accountName string.
        // Scope by matching institution and/or account name.
        let institution = account.institutionName.lowercased()
        let name = account.accountName.lowercased()
        
        let filtered = portfolioViewModel.portfolio.recentTransactions.filter { tx in
            let txAccount = tx.accountName.lowercased()
            return txAccount.contains(institution) || txAccount.contains(name)
        }
        
        // Prefer most recent first if data isn't already sorted.
        return filtered.sorted { $0.date > $1.date }
    }
}

/// Some navigation flows can still reserve tab bar space even when hidden globally.
/// Hide it again at the destination level to avoid a "ghost tab bar" gap.
private struct HideSystemTabBarOnThisScreen: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .toolbar(.hidden, for: .tabBar)
        } else {
            content
                .onAppear { UITabBar.appearance().isHidden = true }
        }
    }
}

// MARK: - Horizontal pager (upright cards)

private struct HorizontalAccountsPager: View {
    let accounts: [PortfolioAccount]
    @Binding var selectedIndex: Int
    let onCardTap: () -> Void
    @State private var scrollPosition: Int? = 0
    
    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let cardWidth = min(availableWidth * 0.78, 360)
            // Taller, “longer” cards per reference.
            let cardHeight = min(proxy.size.height * 0.98, 560)
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(accounts.indices, id: \.self) { index in
                        AccountVirtualCardView(
                            account: accounts[index],
                            isSelected: selectedIndex == index,
                            displayMode: .cards
                        )
                        // Give shadow room within the scroll content so it won’t clip.
                        .padding(.vertical, 24)
                        .frame(width: cardWidth, height: cardHeight)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            // Modern, calm carousel feel (subtle)
                            content
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.94)
                                .opacity(phase.isIdentity ? 1.0 : 0.88)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred(intensity: 0.8)
                            selectedIndex = index
                            onCardTap()
                        }
                        .id(index)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Account \(index + 1) of \(accounts.count)")
                    }
                }
                .scrollTargetLayout()
                // Center the current card; allow slight "peek" of neighbors.
                .padding(.horizontal, max(0, (availableWidth - cardWidth) / 2))
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .contentMargins(.vertical, 32, for: .scrollContent)
            .scrollClipDisabled()
            .onAppear {
                scrollPosition = selectedIndex
            }
            .onChange(of: scrollPosition) { newValue in
                guard let newIndex = newValue else { return }
                if newIndex != selectedIndex {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    selectedIndex = newIndex
                }
            }
            .onChange(of: selectedIndex) { newValue in
                if scrollPosition != newValue {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        scrollPosition = newValue
                    }
                }
            }
        }
    }
}

// MARK: - Bottom selector bar

private struct AccountSelectorBar: View {
    let title: String
    let iconSystemName: String
    let onPrev: () -> Void
    let onNext: () -> Void
    let onOpenDetails: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 63, height: 63)
                    .background(DesignSystem.Colors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY
                    )
            }
            .accessibilityLabel("Previous account")
            
            Button(action: onOpenDetails) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(
                            color: DesignSystem.Shadow.softColor,
                            radius: DesignSystem.Shadow.softRadius,
                            x: DesignSystem.Shadow.softX,
                            y: DesignSystem.Shadow.softY
                        )
                        .overlay(
                            Image(systemName: iconSystemName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.85))
                        )
                    
                    Text(title)
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .frame(height: 63)
                .background(DesignSystem.Colors.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open details for \(title)")
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 63, height: 63)
                    .background(DesignSystem.Colors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY
                    )
            }
            .accessibilityLabel("Next account")
        }
        .buttonStyle(.plain)
    }
}

private struct AccountsBottomSelectorSheet: View {
    let title: String
    let iconSystemName: String
    let onPrev: () -> Void
    let onNext: () -> Void
    let onOpenDetails: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            AccountSelectorBar(
                title: title,
                iconSystemName: iconSystemName,
                onPrev: onPrev,
                onNext: onNext,
                onOpenDetails: onOpenDetails
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary)
        .clipShape(TopRoundedRectangle(radius: 38))
        .shadow(
            color: DesignSystem.Shadow.softColor.opacity(0.55),
            radius: 12,
            x: 0,
            y: -2
        )
    }
}

// MARK: - Balance + details CTA (reference-style)

private struct BalanceAndDetailsCTA: View {
    let balanceText: String
    let onOpenDetails: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Current Balance")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)
            
            Text(balanceText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Button {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                onOpenDetails()
            } label: {
                Text("See account details")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, 18)
                    .frame(height: 42)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("See account details")
        }
        .padding(.top, 4)
    }
}

// MARK: - Details sheet content

private struct AccountDetailsSheetView: View {
    @Binding var detent: PresentationDetent
    let account: PortfolioAccount
    let transactions: [Transaction]
    let isPrivacyMode: Bool
    let balanceChange: BalanceChange
    let onTogglePrivacy: () -> Void
    let onPerformanceTap: () -> Void
    
    var body: some View {
        let isExpanded = detent == .large
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                // Handle
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(DesignSystem.Colors.textSecondary)
                    .frame(width: 40, height: 4)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                
                // Account chip
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(
                            color: DesignSystem.Shadow.softColor,
                            radius: DesignSystem.Shadow.softRadius,
                            x: DesignSystem.Shadow.softX,
                            y: DesignSystem.Shadow.softY
                        )
                        .overlay(
                            Image(systemName: account.accountType.iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.85))
                        )
                    
                    Text(accountIdentifierText)
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                .frame(height: 63)
                .background(DesignSystem.Colors.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
                
                // Net worth
                VStack(alignment: .leading, spacing: 15) {
                    Text("Net Worth")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack(alignment: .center) {
                        Text(isPrivacyMode ? "••••••" : account.formattedBalance)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        
                        Spacer(minLength: 0)
                        
                        Button {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            onTogglePrivacy()
                        } label: {
                            Image(systemName: isPrivacyMode ? "eye.slash" : "eye")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .frame(width: 42, height: 42)
                                .background(DesignSystem.Colors.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(
                                    color: DesignSystem.Shadow.softColor,
                                    radius: DesignSystem.Shadow.softRadius,
                                    x: DesignSystem.Shadow.softX,
                                    y: DesignSystem.Shadow.softY
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPrivacyMode ? "Show balance" : "Hide balance")
                    }
                    
                    balanceChangeRow
                }
                
                PerformanceCTAView(onTap: onPerformanceTap)
                    .accessibilityLabel("Open performance for this account")
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Recent Activity")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    VStack(spacing: 12) {
                        if transactions.isEmpty {
                            emptyRecentActivityCard
                        } else {
                            ForEach(isExpanded ? transactions : Array(transactions.prefix(3))) { tx in
                                TransactionActivityCard(transaction: tx, isPrivacyMode: isPrivacyMode)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollDisabled(!isExpanded)
        .background(DesignSystem.Colors.backgroundPrimary.opacity(0.0001))
    }
    
    private var accountIdentifierText: String {
        if account.lastFourDigits.isEmpty || account.lastFourDigits == "••••" {
            return account.accountName
        }
        return "\(account.institutionName) ••••\(account.lastFourDigits)"
    }
    
    @ViewBuilder
    private var balanceChangeRow: some View {
        // Keep it calm and only show when there's a meaningful change.
        if balanceChange.amount != 0 {
            let isPositive = balanceChange.isPositive
            let amountColor = (isPositive ? (Color(hex: "2DBC84") ?? DesignSystem.Colors.positive) : DesignSystem.Colors.negative)
            let pillBg = (isPositive ? (Color(hex: "E0FAF0") ?? DesignSystem.Colors.positiveBackground) : DesignSystem.Colors.negative.opacity(0.10))
            
            HStack(spacing: 12) {
                Text(isPrivacyMode ? "••••" : balanceChange.formattedAmount)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isPrivacyMode ? DesignSystem.Colors.textSecondary : amountColor)
                    .monospacedDigit()
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isPrivacyMode ? "••" : balanceChange.formattedPercentage)
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .foregroundColor(isPrivacyMode ? DesignSystem.Colors.textSecondary : amountColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(pillBg.opacity(isPrivacyMode ? 0.40 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                Spacer(minLength: 0)
            }
        }
    }
    
    private var emptyRecentActivityCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
                .overlay(
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("No recent activity")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text("Your transactions will appear here.")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
}

private struct TransactionActivityCard: View {
    let transaction: Transaction
    let isPrivacyMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY
                    )
                    .overlay(
                        Image(systemName: transaction.category.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.85))
                    )
                
                Text(transaction.title)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .padding(.leading, 12)
                
                Spacer(minLength: 0)
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
            
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(isPrivacyMode ? "••••" : transaction.formattedAmount)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                
                Text(transaction.isPending ? "Processing..." : "Buy on \(transaction.formattedDate)")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .padding(.top, 10)
        }
        .frame(height: 101)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
}

private struct TopRoundedRectangle: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview("Accounts Cards") {
    NavigationStack {
        AccountsCardsView(portfolioViewModel: .preview)
            .environmentObject(AppState())
    }
}
