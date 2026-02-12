import SwiftUI

/// Home dashboard (Pulse) - shows portfolio if accounts are linked, otherwise a first-account placeholder.
struct PulseDashboardView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: MainTabView.Tab
    
    @StateObject private var portfolioViewModel = PortfolioViewModel()
    @State private var showBankLinking: Bool = false
    @State private var showFullAnalysis: Bool = false
    @State private var showAccountsCards: Bool = false
    @State private var selectedPerformanceCard: RecentActivityCardModel? = nil
    @State private var showMoreProfitableAccounts: Bool = false
    @State private var showConnectedAccounts: Bool = false
    @State private var dismissedNotificationIds: Set<String> = []
    @State private var notificationDragOffset: CGFloat = 0
    
    @State private var isDailyCreditSheetPresented: Bool = false
    @State private var isDailyCreditSuccessPresented: Bool = false
    
    private let linkedAccountIdsKey = "linked_account_ids"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background + hero gradient (matches Figma)
                (Color(hex: "FBFBFB") ?? DesignSystem.Colors.backgroundPrimary)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    DesignSystem.Gradients.homeHero
                        .frame(height: 540)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                }
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        if isPortfolioLocked {
                            // Keep the empty/CTA state when there are no linked accounts.
                            VStack(alignment: .leading, spacing: 18) {
                                balanceHeader
                                firstAccountPlaceholder
                                Spacer(minLength: 24)
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 12)
                            .padding(.bottom, 24)
                        } else {
                            // Restored "old" home layout per screenshot.
                            heroArea
                            
                            if !displayedNotifications.isEmpty {
                                stackedNotificationsSection
                                    .padding(.horizontal, 18)
                            }
                            
                            statsRow
                                .padding(.horizontal, 18)

                            PrimaryButton(title: "Open Accounts") {
                                showAccountsCards = true
                            }
                            .padding(.horizontal, 18)
                            
                            profitableAccountsSection
                                .padding(.horizontal, 18)
                                .padding(.top, 6)
                            
                            Spacer(minLength: 24)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .flouzeOfferCardVisible(!isPortfolioLocked)
            .onAppear {
                // Hide-number/privacy mode is no longer needed on the homepage.
                // Ensure balances always render unmasked here.
                if portfolioViewModel.isPrivacyModeEnabled {
                    portfolioViewModel.isPrivacyModeEnabled = false
                }
            }
            .task {
                await portfolioViewModel.fetchPortfolio()
            }
            .refreshable {
                portfolioViewModel.isRefreshing = true
                await portfolioViewModel.fetchPortfolio(force: true)
                portfolioViewModel.isRefreshing = false
            }
            .sheet(isPresented: $showBankLinking) {
                BankLinkingContainerView(onComplete: { accountIds in
                    UserDefaults.standard.set(accountIds, forKey: linkedAccountIdsKey)
                    showBankLinking = false
                    Task { await portfolioViewModel.fetchPortfolio(force: true) }
                }, onCancel: {
                    showBankLinking = false
                })
            }
            .sheet(isPresented: $showFullAnalysis) {
                FullAnalysisSheet()
            }
            .sheet(isPresented: $showConnectedAccounts) {
                SyncedAccountsView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $isDailyCreditSheetPresented) {
                DailyCreditSheet(
                    onClaim: {
                        isDailyCreditSheetPresented = false
                        isDailyCreditSuccessPresented = true
                    }
                )
                .environmentObject(appState)
                .modifier(DailyCreditSheetPresentation())
            }
            .sheet(item: $selectedPerformanceCard) { card in
                PerformanceView(contextTitle: card.title)
                    .environmentObject(appState)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $isDailyCreditSuccessPresented) {
                DailyCreditSuccessView(
                    onContinue: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        isDailyCreditSuccessPresented = false
                        applyDailyCreditIfAvailable()
                    }
                )
            }
            .navigationDestination(isPresented: $showAccountsCards) {
                AccountsCardsView(portfolioViewModel: portfolioViewModel)
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $showMoreProfitableAccounts) {
                AccountRankingView()
                    .environmentObject(appState)
            }
        }
    }

    /// Match existing paywall sheet style (large detent, hidden drag indicator).
    private struct DailyCreditSheetPresentation: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            } else {
                content
            }
        }
    }
    
    private var isPortfolioLocked: Bool {
        portfolioViewModel.hasLoadedOnce && !portfolioViewModel.hasAccounts
    }
    
    /// Notifications stacked on the dashboard: disconnected account(s), account(s) requiring attention.
    /// Always returns 3 items when the user has accounts so the stack is visible by default.
    private var dashboardNotifications: [DashboardNotification] {
        var list: [DashboardNotification] = []
        let portfolio = portfolioViewModel.portfolio
        
        if portfolio.isStale && portfolioViewModel.hasAccounts {
            let days = daysSince(portfolio.lastSyncDate)
            let subtitle = days <= 1
                ? "Your data hasn't updated in 1 day"
                : "Your data hasn't updated in \(days) days"
            list.append(DashboardNotification(
                id: "disconnected-revolut",
                kind: .disconnectedAccount,
                title: "Reconnect your Revolut account",
                subtitle: subtitle
            ))
        }
        
        // Account(s) requiring attention (e.g. re-auth, consent, issue).
        if portfolioViewModel.hasAccounts {
            list.append(DashboardNotification(
                id: "attention-n26",
                kind: .accountRequiresAttention,
                title: "Your N26 account needs attention",
                subtitle: "Confirm your identity to keep syncing"
            ))
            list.append(DashboardNotification(
                id: "attention-review",
                kind: .accountRequiresAttention,
                title: "Review your connected accounts",
                subtitle: "One or more accounts may need re-authorization"
            ))
        }
        
        // Pad to 3 stacked notifications by default when we have at least one.
        while list.count < 3 && list.isEmpty == false {
            list.append(DashboardNotification(
                id: "placeholder-\(list.count)",
                kind: .accountRequiresAttention,
                title: "Keep your accounts in sync",
                subtitle: "Tap to open Connected Accounts"
            ))
        }
        
        return list
    }
    
    /// Notifications still visible (not dismissed by swipe).
    private var displayedNotifications: [DashboardNotification] {
        dashboardNotifications.filter { !dismissedNotificationIds.contains($0.id) }
    }
    
    private var balanceHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Total balance")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(alignment: .firstTextBaseline) {
                styledBalanceText(
                    isPortfolioLocked ? "—" : portfolioViewModel.formattedBalance,
                    amountFontSize: 34,
                    amountColor: .primary,
                    prefixColor: .secondary
                )
                
                Spacer()
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Restored hero (screenshot layout)
    
    private var heroArea: some View {
        VStack(spacing: 24) {
            homeTopChips
                .padding(.horizontal, 18)
                .padding(.top, 6)
            
            VStack(spacing: 12) {
                Text("Your total balance")
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: 14))
                    .foregroundColor(DesignSystem.Colors.ink.opacity(0.5))
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack(alignment: .center, spacing: 12) {
                    Spacer(minLength: 0)
                    
                    styledBalanceText(
                        portfolioViewModel.formattedBalance,
                        amountFontSize: 48,
                        amountColor: DesignSystem.Colors.ink,
                        prefixColor: DesignSystem.Colors.inkSecondary
                    )
                    
                    Spacer(minLength: 0)
                }
                
                Button {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    showFullAnalysis = true
                } label: {
                    Text("View Analysis")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.ink)
                        .frame(width: 148, height: 43)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.top, 2)
        }
    }
    
    private var homeTopChips: some View {
        HStack(spacing: 12) {
            Button {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                isDailyCreditSheetPresented = true
            } label: {
                HStack(spacing: 6) {
                    Text("Daily Credit")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Image("DailyCreditIcon")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 24)
                }
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
            }
            .buttonStyle(.plain)
            
            Spacer(minLength: 0)
            
            Button {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                NotificationCenter.default.post(name: .infinitePaywallRequested, object: nil)
            } label: {
                Text("JOIN INFINITE NOW")
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: 16))
                    .foregroundColor(Color(hex: "3E9FFF") ?? DesignSystem.Colors.accent)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var isStandardPlan: Bool {
        (appState.currentUser?.membershipLevel ?? .standard) == .standard
    }
    
    private var userEmailForCredits: String {
        appState.currentUser?.email ?? "guest"
    }
    
    private func applyDailyCreditIfAvailable() {
        guard isStandardPlan else { return }
        let email = userEmailForCredits
        guard !DailyCreditStore.hasClaimedToday(email: email) else { return }
        DailyCreditStore.markClaimedToday(email: email)
        PulseCreditsStore.add(email: email, delta: 1)
    }
    
    private var reconnectCard: some View {
        Button {
            // Could route to Connected Accounts later.
        } label: {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .opacity(0.30)
                    .frame(height: 51)
                    .frame(maxWidth: 268)
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY
                    )
                
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .opacity(0.70)
                    .frame(height: 63)
                    .frame(maxWidth: 326)
                    .padding(.top, 11)
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY
                    )
                
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.8))
                            .shadow(
                                color: DesignSystem.Shadow.softColor,
                                radius: DesignSystem.Shadow.softRadius,
                                x: DesignSystem.Shadow.softX,
                                y: DesignSystem.Shadow.softY
                            )
                        
                        Image(systemName: "paperclip")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.inkSecondary)
                    }
                    .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reconnect your Revolut account")
                            .font(DesignSystem.Typography.plusJakarta(.bold, size: 14))
                            .foregroundColor(DesignSystem.Colors.ink)
                            .lineLimit(1)
                        
                        Text(reconnectSubtitle)
                            .font(DesignSystem.Typography.plusJakarta(.regular, size: 14))
                            .foregroundColor(DesignSystem.Colors.ink.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.inkSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, minHeight: 88)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                        .shadow(
                            color: DesignSystem.Shadow.softColor,
                            radius: DesignSystem.Shadow.softRadius,
                            x: DesignSystem.Shadow.softX,
                            y: DesignSystem.Shadow.softY
                        )
                )
                .padding(.top, 24)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var reconnectSubtitle: String {
        let days = daysSince(portfolioViewModel.portfolio.lastSyncDate)
        if days <= 1 {
            return "Your data hasn’t updated in 1 day"
        }
        return "Your data hasn’t updated in \(days) days"
    }
    
    private func daysSince(_ date: Date) -> Int {
        max(1, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 1)
    }
    
    private var stackedNotificationsSection: some View {
        let count = displayedNotifications.count
        let stackOffsetX: CGFloat = 8
        let stackOffsetY: CGFloat = 6
        let swipeDismissThreshold: CGFloat = 80
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(displayedNotifications.enumerated()).reversed(), id: \.element.id) { index, notification in
                Group {
                    if index == 0 {
                        notificationCardContent(notification)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                showConnectedAccounts = true
                            }
                            .highPriorityGesture(
                                DragGesture(minimumDistance: 15)
                                    .onChanged { value in
                                        notificationDragOffset = min(0, value.translation.width)
                                    }
                                    .onEnded { value in
                                        if value.translation.width < -swipeDismissThreshold {
                                            withAnimation(.easeOut(duration: 0.22)) {
                                                dismissedNotificationIds.insert(notification.id)
                                                notificationDragOffset = 0
                                            }
                                            let generator = UINotificationFeedbackGenerator()
                                            generator.notificationOccurred(.success)
                                        } else {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                notificationDragOffset = 0
                                            }
                                        }
                                    }
                            )
                            .offset(x: notificationDragOffset)
                    } else {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .frame(minHeight: 88)
                            .frame(maxWidth: .infinity)
                            .shadow(
                                color: DesignSystem.Shadow.softColor,
                                radius: DesignSystem.Shadow.softRadius,
                                x: DesignSystem.Shadow.softX,
                                y: DesignSystem.Shadow.softY
                            )
                            .opacity(index == count - 1 ? 0.35 : 0.7)
                    }
                }
                .offset(
                    x: CGFloat(index) * stackOffsetX,
                    y: CGFloat(index) * stackOffsetY
                )
            }
        }
        .padding(.top, CGFloat(max(0, displayedNotifications.count - 1)) * 6)
    }
    
    private func notificationCardContent(_ notification: DashboardNotification) -> some View {
        HStack(spacing: 10) {
            // Figma: circular light gray background with subtle darker outline
            ZStack {
                Circle()
                    .fill(Color(hex: "E8E8E8") ?? Color(uiColor: .systemGray5))
                Circle()
                    .stroke(Color(hex: "D0D0D0") ?? Color(uiColor: .systemGray4), lineWidth: 1)
                Image(systemName: notification.kind == .disconnectedAccount ? "link" : notification.systemIconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.inkSecondary)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(DesignSystem.Typography.plusJakarta(.bold, size: 14))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .lineLimit(1)
                Text(notification.subtitle)
                    .font(DesignSystem.Typography.plusJakarta(.regular, size: 14))
                    .foregroundColor(DesignSystem.Colors.ink.opacity(0.85))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 88)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
        )
    }

    @ViewBuilder
    private func styledBalanceText(
        _ value: String,
        amountFontSize: CGFloat,
        amountColor: Color,
        prefixColor: Color
    ) -> some View {
        // Locale-specific currency formatting can render USD as "US$…".
        // We keep the amount dominant and make the "US" prefix more discreet.
        if value.hasPrefix("US$") {
            let suffix = String(value.dropFirst(2)) // "$…"
            
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("US")
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: max(12, amountFontSize * 0.38)))
                    .foregroundColor(prefixColor)
                    .baselineOffset(amountFontSize * 0.22)
                
                Text(suffix)
                    .font(DesignSystem.Typography.plusJakarta(.bold, size: amountFontSize))
                    .foregroundColor(amountColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        } else if value.hasSuffix("$US") {
            let main = String(value.dropLast(2)) // "...$"
            
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(main)
                    .font(DesignSystem.Typography.plusJakarta(.bold, size: amountFontSize))
                    .foregroundColor(amountColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                Text("US")
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: max(12, amountFontSize * 0.38)))
                    .foregroundColor(prefixColor)
                    .baselineOffset(amountFontSize * 0.22)
            }
        } else {
            Text(value)
                .font(DesignSystem.Typography.plusJakarta(.bold, size: amountFontSize))
                .foregroundColor(amountColor)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total gain",
                value: formatCurrency(portfolioViewModel.portfolio.balanceChange.amount),
                subtitle: "Since start",
                valueColor: DesignSystem.Colors.positive
            )
            
            StatCard(
                title: "Monthly return",
                value: formatPercent(portfolioViewModel.portfolio.balanceChange.percentage),
                subtitle: currentMonthLabel,
                valueColor: DesignSystem.Colors.positive
            )
        }
    }
    
    private var currentMonthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "+$0"
    }
    
    private func formatPercent(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        let asFraction = NSDecimalNumber(decimal: value / 100)
        return formatter.string(from: asFraction) ?? "+0.0%"
    }
    
    private var profitableAccountsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center) {
                Text("Your Most Profitable Accounts")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .foregroundColor(DesignSystem.Colors.inkSecondary)
                    .lineLimit(1)
                    .frame(width: 226, alignment: .leading)
                
                Spacer(minLength: 0)
                
                Button {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    showMoreProfitableAccounts = true
                } label: {
                    HStack(spacing: 2) {
                        Text("See More")
                            .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        // Use SF Symbol here to keep it crisp (avoids SVG scaling artifacts).
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.accent)
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("See more profitable accounts")
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 15) {
                ForEach(topProfitableAccounts.prefix(2)) { item in
                    Button {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        selectedPerformanceCard = RecentActivityCardModel(
                            title: item.identifier,
                            price: item.formattedGainAmount,
                            changeText: item.formattedGainPercent,
                            sparkline: item.sparkline
                        )
                    } label: {
                        ProfitableAccountCard(
                            title: item.identifier,
                            gainAmount: item.formattedGainAmount,
                            gainPercent: item.formattedGainPercent,
                            sparkline: item.sparkline
                        )
                        .frame(width: 354, height: 101)
                        // If the parent width is slightly different (e.g. 393pt screens),
                        // keep the card visually centered so left/right padding matches.
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private struct RecentActivityCardModel: Identifiable {
        let id = UUID()
        let title: String
        let price: String
        let changeText: String
        let sparkline: [Decimal]
    }
    
    private struct ProfitableAccountItem: Identifiable {
        let id: UUID
        let identifier: String
        let gainAmount: Decimal
        let gainPercent: Decimal
        let sparkline: [Decimal]
        
        var formattedGainAmount: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            // Match Figma: +$250.45 (stable, not locale-dependent)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.currencyCode = "USD"
            formatter.currencySymbol = "$"
            formatter.maximumFractionDigits = 2
            formatter.positivePrefix = "+"
            return formatter.string(from: NSDecimalNumber(decimal: gainAmount)) ?? "+$0.00"
        }
        
        var formattedGainPercent: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            // Match Figma: +3,3% (French comma, no space before %)
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.maximumFractionDigits = 1
            formatter.minimumFractionDigits = 1
            formatter.positivePrefix = "+"
            formatter.multiplier = 0.01
            let raw = formatter.string(from: NSDecimalNumber(decimal: gainPercent)) ?? "+0,0%"
            return raw
                .replacingOccurrences(of: "\u{00A0}%", with: "%") // NBSP
                .replacingOccurrences(of: " %", with: "%")
        }
    }
    
    private var topProfitableAccounts: [ProfitableAccountItem] {
        let accounts = portfolioViewModel.portfolio.accounts
        guard !accounts.isEmpty else {
            // Fallback to sample accounts when portfolio isn't ready yet.
            return PortfolioAccount.sampleAccounts.map(toProfitableItem)
                .sorted { $0.gainAmount > $1.gainAmount }
        }
        
        return accounts.map(toProfitableItem)
            .sorted { $0.gainAmount > $1.gainAmount }
    }
    
    private func toProfitableItem(_ account: PortfolioAccount) -> ProfitableAccountItem {
        // The demo portfolio model doesn't carry per-account performance yet.
        // Create deterministic “mock” gains per account to match the reference UI.
        let seed = abs(account.id.uuidString.hashValue)
        let cents = Decimal((seed % 35_000) + 8_500) / 100 // 85.00 ... 434.99
        let percentTenth = Decimal((seed % 60) + 5) / 10 // 0.5 ... 6.4
        
        // Sparkline: stable upward trend with subtle noise.
        let points: [Decimal] = (0..<20).map { idx in
            let t = Decimal(idx) / Decimal(19)
            let base = Decimal(10) + (t * 10)
            let wobble = Decimal(((seed + idx * 97) % 7)) / 10
            return base + wobble
        }
        
        let identifier = accountIdentifier(for: account)
        
        return ProfitableAccountItem(
            id: account.id,
            identifier: identifier,
            gainAmount: cents,
            gainPercent: percentTenth,
            sparkline: points
        )
    }
    
    private func accountIdentifier(for account: PortfolioAccount) -> String {
        // Prefer a pseudo-IBAN-like identifier to match the reference.
        // Keep it deterministic based on account id.
        let seed = abs(account.id.uuidString.hashValue)
        let suffix = String(format: "%04d", seed % 10_000)
        return "CTA-FR-1234-5678-\(suffix)"
    }

    private var firstAccountPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add your first account")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Link an account to see your portfolio, performance, and insights.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            PrimaryButton(title: "Open Accounts") {
                showAccountsCards = true
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let valueColor: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(DesignSystem.Typography.plusJakarta(.semibold, size: 16))
                .foregroundColor(DesignSystem.Colors.ink)
            
            Text(value)
                .font(DesignSystem.Typography.plusJakarta(.semibold, size: 24))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(subtitle)
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 17)
        .surfaceCard(radius: 18)
    }
}

private struct ActivityInstrumentCard: View {
    let title: String
    let price: String
    let changeText: String
    let sparkline: [Decimal]
    
    var body: some View {
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
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.inkSecondary.opacity(0.75))
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: 10) {
                    Text(price)
                        .font(DesignSystem.Typography.plusJakarta(.semibold, size: 24))
                        .foregroundColor(DesignSystem.Colors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .allowsTightening(true)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text(changeText)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "2DBC84") ?? DesignSystem.Colors.positive)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "E0FAF0") ?? DesignSystem.Colors.positiveBackground.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .allowsTightening(true)
                }
                // Extra vertical breathing room to avoid glyph clipping with custom fonts.
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            
            Spacer(minLength: 0)
            
            SparklineView(
                dataPoints: sparkline,
                isPositive: true,
                height: 44,
                showsEndPoint: false
            )
            .frame(width: 88)
        }
        .padding(12)
        .surfaceCard(radius: 18)
    }
}

private struct ProfitableAccountCard: View {
    let title: String
    let gainAmount: String
    let gainPercent: String
    let sparkline: [Decimal]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Icon tile (36x36, radius 13, shadow 0/1/10 @ 5%)
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
                .overlay(iconContent)
                .offset(x: 12, y: 12)
            
            // Title (centered over the left content area, per Figma)
            Text(title)
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(.black)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(width: 260)
                .position(x: 151.5, y: 36)
            
            // Sparkline (Figma vectors: fill + stroke)
            Image("ProfitableSparklineStroke")
                .resizable()
                .scaledToFill()
                .frame(width: 83, height: 30)
                .offset(x: 254.5, y: 42.75)
                .accessibilityHidden(true)
            
            Image("ProfitableSparklineFill")
                .resizable()
                .scaledToFill()
                .frame(width: 83, height: 46)
                .offset(x: 254.5, y: 43.75)
                .accessibilityHidden(true)
            
            // Bottom row: amount + performance pill
            HStack(spacing: 12) {
                Text(gainAmount)
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: 24))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .lineLimit(1)
                
                HStack(spacing: 5) {
                    Image("ProfitableTrendIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .accessibilityHidden(true)
                    
                    Text(gainPercent)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "2DBC84") ?? DesignSystem.Colors.livePillInk)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(hex: "E0FAF0") ?? DesignSystem.Colors.livePillFill)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .offset(x: 12, y: 62)
        }
        .frame(width: 354, height: 101)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
    
    @ViewBuilder
    private var iconContent: some View {
        // Use the Figma icons when the identifier matches; otherwise fall back to initials.
        if title.hasPrefix("PEA") {
            Image("ProfitableIconPEA")
                .resizable()
                .scaledToFit()
                .frame(width: 23, height: 16)
        } else if title.hasPrefix("CTO") {
            Image("ProfitableIconCTO")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        } else {
            Text(monogram)
                .font(DesignSystem.Typography.plusJakarta(.bold, size: 14))
                .foregroundColor(DesignSystem.Colors.ink)
        }
    }
    
    private var monogram: String {
        // Keep it minimal and brand-like.
        let letters = title.split(separator: "-").prefix(1).joined()
        return String(letters.prefix(2)).uppercased()
    }
}

#Preview {
    PulseDashboardView(selectedTab: .constant(.home))
        .environmentObject(AppState())
}