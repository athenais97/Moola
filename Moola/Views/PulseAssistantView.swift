import SwiftUI

/// Pulse — AI market assistant (new tab)
/// UX intent: fast, guided answers to complex investment questions (no free-text chaos).
struct PulseAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var portfolioViewModel = PortfolioViewModel()
    @StateObject private var marketInsightsViewModel = MarketInsightsViewModel()
    
    @State private var messages: [PulseChatMessage] = []
    @State private var isGenerating: Bool = false
    @State private var isBootstrapping: Bool = true
    
    @State private var suggestedQuestions: [PulseQuestion] = PulseQuestion.initialQuestions
    @State private var creditsRemaining: Int = 0
    @State private var hasAskedFirstQuestion: Bool = false
    
    @State private var isPaywallSheetPresented: Bool = false
    @State private var isPaywallBannerDismissed: Bool = false
    @State private var hasAttemptedLockedQuestion: Bool = false
    
    @State private var isDailyCreditSheetPresented: Bool = false
    @State private var isDailyCreditSuccessPresented: Bool = false
    
    /// Optional context to tailor prompts (e.g. a specific holding/portfolio name).
    let context: String?

    /// Optional back action for when this view is used as a root tab.
    /// If provided, we call this instead of `dismiss()`.
    let onBack: (() -> Void)?
    
    init(context: String? = nil, onBack: (() -> Void)? = nil) {
        self.context = context
        self.onBack = onBack
    }
    
    private let questionCost: Int = 5
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundCanvas
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                chrome
                chatArea
            }
        }
        .flouzeOfferCardVisible(shouldShowPaywallBanner)
        .task {
            await MainActor.run {
                isBootstrapping = true
                // Seed immediately so the screen never appears empty.
                seedWelcomeMessageIfNeeded()
                hydrateCreditsIfNeeded()
            }
            
            // Prefetch light context so answers can reference the user's portfolio.
            async let portfolioTask: Void = portfolioViewModel.fetchPortfolio()
            async let insightsTask: Void = marketInsightsViewModel.fetchInsights()
            _ = await (portfolioTask, insightsTask)
            
            await MainActor.run {
                isBootstrapping = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .flouzeOfferCTATapped)) { _ in
            // Only handle CTA when we're actually in a paywalled state.
            guard shouldShowPaywallBanner else { return }
            isPaywallSheetPresented = true
        }
        .sheet(isPresented: $isPaywallSheetPresented) {
            PulseCreditsPaywallSheet(
                onStartTrial: {
                    // Hook point for subscription flow.
                    isPaywallSheetPresented = false
                },
                onDismiss: {
                    isPaywallSheetPresented = false
                }
            )
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
        .fullScreenCover(isPresented: $isDailyCreditSuccessPresented) {
            DailyCreditSuccessView(
                onContinue: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    isDailyCreditSuccessPresented = false
                    applyDailyCreditIfAvailable()
                    hydrateCreditsIfNeeded()
                }
            )
        }
    }
    
    // MARK: - Views
    
    private var chrome: some View {
        HStack(spacing: 0) {
            Button {
                if let onBack {
                    onBack()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .frame(width: 42, height: 43)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            
            Spacer(minLength: 0)
            
            creditsPill
            
            Spacer(minLength: 0)
            
            Button { demoReloadCredits() } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .frame(width: 42, height: 43)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reload credits")
        }
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .padding(.top, 4)
        .padding(.bottom, 16)
    }
    
    private var creditsPill: some View {
        Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            isDailyCreditSheetPresented = true
        } label: {
            HStack(spacing: 4) {
                Image("DailyCreditIcon")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 22, height: 24)
                
                Text(creditsPillTitle)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9.5)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Credits")
    }
    
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(displayMessages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                    
                    if isGenerating {
                        typingBubble
                            .id("typing")
                    }
                    
                    // Related questions appear directly under the assistant bubble,
                    // matching the reference flow (and avoiding a detached bottom area).
                    if !isGenerating, shouldShowSuggestedQuestions {
                        relatedQuestionsInline
                    }

                    // Stable bottom anchor for scrollToBottom.
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .padding(.top, 6)
                .padding(.bottom, chatBottomInset)
            }
            .overlay(alignment: .top) {
                if isBootstrapping {
                    ProgressView()
                        .controlSize(.small)
                        .tint(DesignSystem.Colors.inkSecondary)
                        .padding(.top, 10)
                }
            }
            .onChange(of: messages) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isGenerating) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.18)) {
            if isGenerating {
                proxy.scrollTo("typing", anchor: .bottom)
            } else {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    private var typingBubble: some View {
        HStack(alignment: .bottom, spacing: 12) {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(DesignSystem.Gradients.chatAccent)
                .overlay(
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .stroke(Color(hex: "F2F2F2") ?? DesignSystem.Colors.separator, lineWidth: 1)
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
                .accessibilityHidden(true)
            
            Text("Reflecting...")
                .font(DesignSystem.Typography.plusJakarta(.regular, size: 16))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
                .lineSpacing(2)
                .padding(22)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: 296, alignment: .leading)
            
            Spacer(minLength: 0)
        }
    }
    
    private var relatedQuestionsInline: some View {
        VStack(spacing: 11) {
            ForEach(suggestedQuestions.prefix(3)) { question in
                QuestionPill(
                    text: question.title,
                    cost: questionCost,
                    isDisabled: isGenerating,
                    showsLockedState: shouldGateQuestionTap,
                    onTap: {
                        onTapQuestion(question)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // Align suggestion cards under the assistant bubble (Figma indent).
        .padding(.leading, 44)
        .padding(.trailing, 26)
    }
    
    private var displayMessages: [PulseChatMessage] {
        messages
    }
    
    // MARK: - Actions
    
    private func resetConversation() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            messages = []
            isGenerating = false
            suggestedQuestions = PulseQuestion.initialQuestions
            hasAskedFirstQuestion = false
            hasAttemptedLockedQuestion = false
            isPaywallBannerDismissed = false
        }
        
        seedWelcomeMessageIfNeeded()
    }
    
    private func demoReloadCredits() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        guard isStandardPlan else {
            // Premium is unlimited in this demo; keep behavior simple.
            return
        }
        
        let email = appState.currentUser?.email ?? "guest"
        creditsRemaining = PulseCreditsStore.add(email: email, delta: 5)
    }
    
    private func onTapQuestion(_ question: PulseQuestion) {
        guard !isGenerating else { return }
        
        if shouldGateQuestionTap {
            // Requirement:
            // - The premium card appears only after selecting a locked (second) question.
            // - The paywall sheet opens only when tapping the CTA on that card.
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
            withAnimation(.easeInOut(duration: 0.18)) {
                hasAttemptedLockedQuestion = true
                isPaywallBannerDismissed = false
            }
            return
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
        
        consumeCreditsIfNeeded(cost: questionCost)
        
        withAnimation(.easeInOut(duration: 0.15)) {
            messages.append(PulseChatMessage(role: .user, text: question.title))
            isGenerating = true
        }
        
        Task { @MainActor in
            // Tiny delay so the UI feels responsive but intentional.
            try? await Task.sleep(nanoseconds: 250_000_000)
            
            let result = PulseAnswerBuilder(
                question: question.kind,
                portfolio: portfolioViewModel.portfolio,
                insights: marketInsightsViewModel.allInsights,
                climate: marketInsightsViewModel.climate,
                creditsRemaining: creditsRemaining,
                questionCost: questionCost
            ).build()
            
            withAnimation(.easeInOut(duration: 0.15)) {
                messages.append(PulseChatMessage(role: .assistant, text: result.text))
                isGenerating = false
            }
            
            if !hasAskedFirstQuestion {
                hasAskedFirstQuestion = true
            }
            
            // After the first question, update the next two suggestions based on the assistant’s answer.
            if hasAskedFirstQuestion {
                suggestedQuestions = result.followUpQuestions
            }
        }
    }
}

// MARK: - Pulse Chat Models

private struct PulseChatMessage: Identifiable, Equatable {
    enum Role {
        case user
        case assistant
    }
    
    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date = Date()
    
    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
    
}

private struct QuestionPill: View {
    let text: String
    let cost: Int
    let isDisabled: Bool
    let showsLockedState: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(text)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .foregroundColor(DesignSystem.Colors.chatQuestionAccent)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 4) {
                    Text("Cost : \(cost)")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                        .foregroundColor(DesignSystem.Colors.ink)
                    
                    if showsLockedState {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.inkSecondary)
                    } else {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9.5)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.pill, style: .continuous))
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceCard(radius: 16)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

private struct ChatBubble: View {
    let message: PulseChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.role == .assistant {
                assistantAvatar
                bubble
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                bubble
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .assistant ? .leading : .trailing)
    }
    
    private var bubble: some View {
        Text(message.text)
            .font(DesignSystem.Typography.plusJakarta(message.role == .user ? .medium : .regular, size: 16))
            .foregroundColor(message.role == .user ? .white : DesignSystem.Colors.ink)
            .lineSpacing(2)
            .padding(22)
            .background(bubbleBackground)
            .frame(maxWidth: 296, alignment: message.role == .user ? .trailing : .leading)
    }
    
    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            DesignSystem.Gradients.chatAccent
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            Color.white
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var assistantAvatar: some View {
        RoundedRectangle(cornerRadius: 21, style: .continuous)
            .fill(DesignSystem.Gradients.chatAccent)
            .overlay(
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(Color(hex: "F2F2F2") ?? DesignSystem.Colors.separator, lineWidth: 1)
            )
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Answer Builder

private struct PulseAnswerBuilder {
    let question: PulseQuestion.Kind
    let portfolio: PortfolioSummary
    let insights: [MarketInsight]
    let climate: PortfolioClimate
    let creditsRemaining: Int
    let questionCost: Int
    
    func build() -> PulseAnswerResult {
        switch question {
        case .preset(let preset):
            switch preset {
            case .popularMarket:
                return popularMarketAnswer()
            case .biggestHoldingDown:
                return biggestHoldingDownAnswer()
            case .trajectory6m:
                return trajectoryAnswer()
            case .diversification:
                return diversificationAnswer()
            case .whatAreCredits:
                return creditsAnswer()
            }
        case .followUp(let followUp):
            return followUpAnswer(followUp)
        }
    }
    
    private func popularMarketAnswer() -> PulseAnswerResult {
        let topCategory = mostCommonCategory(from: insights)
        let focus = topCategory?.rawValue ?? "the market"
        let topCategoryLine: String = {
            guard let topCategory else { return "Right now, I’m not seeing enough fresh signals to pick a clear “most popular” theme." }
            return "Right now, the busiest theme is \(topCategory.rawValue) — it’s showing up the most in today’s headlines."
        }()
        
        let text = [
            topCategoryLine,
            "For your portfolio: \(allocationSummaryLine())"
        ].joined(separator: "\n")
        
        return PulseAnswerResult(
            text: text,
            followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: focus)
        )
    }
    
    private func trajectoryAnswer() -> PulseAnswerResult {
        guard portfolio.balanceHistory.count >= 2,
              let first = portfolio.balanceHistory.first,
              let last = portfolio.balanceHistory.last else {
            return PulseAnswerResult(
                text: "I don’t have enough history yet to estimate a 6‑month trajectory. Once you’ve got a few data points, I can show a simple trend and what might move it.",
                followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: "your trajectory")
            )
        }
        
        let days = max(1, Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 6)
        let delta = last.value - first.value
        let daily = delta / Decimal(days)
        
        // 6 months ≈ 182 days. Keep this plain: “if the recent pace continued”.
        let projected = portfolio.totalBalance + (daily * 182)
        
        let weeklyChange = portfolio.balanceChange
        
        let text = [
            "Over the last week, your total balance moved \(weeklyChange.formattedAmount) (\(weeklyChange.formattedPercentage)).",
            "If that recent pace continued (big “if”), 6 months could land around \(formatCurrency(projected)).",
            "What could change it: deposits/withdrawals, and market swings (how much prices move day‑to‑day)."
        ]
        .joined(separator: "\n")
        
        return PulseAnswerResult(
            text: text,
            followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: "your trajectory")
        )
    }
    
    private func driversTodayAnswer() -> PulseAnswerResult {
        let topTwo = insights
            .sorted { $0.relevanceScore > $1.relevanceScore }
            .prefix(2)
        
        let driverLines: [String] = topTwo.enumerated().map { idx, insight in
            "\(idx + 1)) \(insight.headline)"
        }
        
        let driversBlock: String = {
            if driverLines.isEmpty {
                return "Today’s drivers: I don’t have a strong news signal loaded yet."
            }
            return "Today’s likely drivers:\n" + driverLines.joined(separator: "\n")
        }()
        
        let text = [
            driversBlock,
            "Portfolio context: \(allocationSummaryLine())",
            "Overall climate: \(climate.rawValue) (a simple mood check based on current headlines)."
        ]
        .joined(separator: "\n")
        
        return PulseAnswerResult(
            text: text,
            followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: "today’s drivers")
        )
    }
    
    private func diversificationAnswer() -> PulseAnswerResult {
        let allocation = portfolio.assetAllocation
        let total = max(0, NSDecimalNumber(decimal: allocation.total).doubleValue)
        guard total > 0 else {
            return PulseAnswerResult(
                text: "I can’t assess diversification yet because your portfolio looks empty. Once accounts are connected, I’ll summarize how your money is split across cash, stocks, and crypto.",
                followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: "diversification")
            )
        }
        
        let categories = allocation.activeCategories
        let largest = categories.max(by: { $0.percentage < $1.percentage })
        
        let splitLine = categories
            .sorted(by: { $0.percentage > $1.percentage })
            .map { "\($0.category.rawValue) \(formatPercent($0.percentage))" }
            .joined(separator: " · ")
        
        var guidance: String = "A simple rule of thumb: diversification means you’re not relying on just one basket."
        if let largest, largest.percentage >= 0.70 {
            guidance = "You’re quite concentrated in \(largest.category.rawValue). That can boost gains, but it can also make drops feel bigger if that area has a rough patch."
        } else if categories.count >= 3 {
            guidance = "You’re spread across multiple buckets, which generally reduces “single‑theme” risk."
        }
        
        let text = [
            "Your split: \(splitLine)",
            guidance
        ]
        .joined(separator: "\n")
        
        return PulseAnswerResult(
            text: text,
            followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: "diversification")
        )
    }
    
    private func biggestHoldingDownAnswer() -> PulseAnswerResult {
        // We don’t have per-asset holdings in this demo model, so we explain using buckets + accounts.
        let allocation = portfolio.assetAllocation
        let topBucket = allocation.activeCategories.max(by: { $0.percentage < $1.percentage })
        
        let bucketLine: String = {
            guard let topBucket else {
                return "I don’t see any linked holdings yet. Once accounts are connected, I can explain what’s driving your biggest position."
            }
            return "Your biggest bucket is \(topBucket.category.rawValue) (\(formatPercent(topBucket.percentage))). If it’s down, that bucket usually explains most of the move."
        }()
        
        let accountLine: String = {
            let topAccount = portfolio.accounts.max(by: { $0.balance < $1.balance })
            guard let topAccount, topAccount.balance > 0 else { return "I don’t have enough detail to pinpoint a single account driver yet." }
            return "Your largest account by balance is \(topAccount.accountName) (\(topAccount.formattedBalance))."
        }()
        
        let text = [
            bucketLine,
            accountLine,
            "If you want, I can break this into: (1) market movement, (2) deposits/withdrawals, and (3) concentration (how much is tied to one bucket)."
        ].joined(separator: "\n")
        
        return PulseAnswerResult(
            text: text,
            followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: "your biggest holding")
        )
    }
    
    private func creditsAnswer() -> PulseAnswerResult {
        let text = [
            "Credits are a simple way to limit how many assistant questions you can ask on the free plan.",
            "Each question costs \(questionCost) credits. When you’re out, you’ll see a paywall to unlock more."
        ].joined(separator: "\n")
        
        return PulseAnswerResult(
            text: text,
            followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: "credits")
        )
    }
    
    private func followUpAnswer(_ followUp: PulseFollowUp) -> PulseAnswerResult {
        switch followUp {
        case .exposureBreakdown(let focus):
            let line = "Here’s your current split: \(allocationSummaryLine())"
            return PulseAnswerResult(
                text: [
                    "Exposure is about how much of your portfolio is tied to a theme or bucket (so moves don’t surprise you).",
                    line,
                    "If you meant exposure to \(focus): I can estimate it once holdings are available per asset, not just by bucket."
                ].joined(separator: "\n"),
                followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: focus)
            )
        case .whatToWatch(let focus):
            return PulseAnswerResult(
                text: [
                    "A calm way to “watch” \(focus) is to track 1–2 signals, not everything.",
                    "Suggested signals: major headlines tied to your biggest buckets, and unusual volatility days (big swings).",
                    "I’ll keep this neutral: it’s about awareness, not telling you what to buy."
                ].joined(separator: "\n"),
                followUpQuestions: PulseQuestion.followUps(afterAnswerAbout: focus)
            )
        case .resetSuggestions:
            return PulseAnswerResult(
                text: "Sure — pick another topic and I’ll guide you from there.",
                followUpQuestions: PulseQuestion.initialQuestions
            )
        }
    }
    
    // MARK: - Helpers
    
    private func mostCommonCategory(from insights: [MarketInsight]) -> InsightCategory? {
        guard !insights.isEmpty else { return nil }
        var counts: [InsightCategory: Int] = [:]
        for insight in insights {
            counts[insight.category, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    private func allocationSummaryLine() -> String {
        let allocation = portfolio.assetAllocation
        let total = allocation.total
        guard total > 0 else {
            return "I don’t see linked holdings yet."
        }
        
        let top = allocation.activeCategories
            .sorted(by: { $0.percentage > $1.percentage })
            .prefix(2)
        
        if top.isEmpty {
            return "I don’t see linked holdings yet."
        }
        
        let parts = top.map { "\($0.category.rawValue) \(formatPercent($0.percentage))" }
        return "your biggest buckets are " + parts.joined(separator: " and ") + "."
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0"
    }
    
    private func formatPercent(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
}

#Preview("Pulse Assistant") {
    PulseAssistantView()
        .environmentObject({
            let state = AppState()
            state.currentUser = UserModel(name: "Demo", email: "demo@example.com", membershipLevel: .standard)
            state.isAuthenticated = true
            return state
        }())
}

// MARK: - Pulse Assistant State + Paywall

private extension PulseAssistantView {
    var isStandardPlan: Bool {
        (appState.currentUser?.membershipLevel ?? .standard) == .standard
    }
    
    var creditsPillTitle: String {
        if isStandardPlan {
            return "You have \(max(0, creditsRemaining)) credits left"
        }
        return "You have 230 credits left"
    }
    
    var shouldGateQuestionTap: Bool {
        isStandardPlan && creditsRemaining < questionCost
    }
    
    var shouldShowPaywallBanner: Bool {
        // Show only after the user attempts to ask a second question with no credits.
        isStandardPlan && creditsRemaining <= 0 && hasAttemptedLockedQuestion && !isPaywallBannerDismissed
    }
    
    var shouldShowSuggestedQuestions: Bool {
        // Requirement: pre-generated questions appear only after the assistant has
        // sent its first message (prevents UI flashing before seeding).
        messages.contains(where: { $0.role == .assistant })
    }
    
    func hydrateCreditsIfNeeded() {
        guard isStandardPlan else { return }
        let email = appState.currentUser?.email ?? "guest"
        creditsRemaining = PulseCreditsStore.hydrateIfNeeded(email: email)
    }
    
    func consumeCreditsIfNeeded(cost: Int) {
        guard isStandardPlan else { return }
        creditsRemaining = max(0, creditsRemaining - cost)
        let email = appState.currentUser?.email ?? "guest"
        PulseCreditsStore.set(email: email, credits: creditsRemaining)
    }
    
    func applyDailyCreditIfAvailable() {
        guard isStandardPlan else { return }
        let email = appState.currentUser?.email ?? "guest"
        guard !DailyCreditStore.hasClaimedToday(email: email) else { return }
        DailyCreditStore.markClaimedToday(email: email)
        PulseCreditsStore.add(email: email, delta: 1)
    }
    
    func seedWelcomeMessageIfNeeded() {
        guard messages.isEmpty else { return }
        messages = [
            PulseChatMessage(
                role: .assistant,
                text: "Hi, I’m your market assistant. I’m here to help you understand your portfolio. Ask a question and get a simple explanation in seconds."
            )
        ]
    }
    
    var paywallBanner: some View {
        PulseCreditsPaywallBanner(
            onClose: {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isPaywallBannerDismissed = true
                }
            },
            onTapCTA: {
                isPaywallSheetPresented = true
            }
        )
    }
    
    var chatBottomInset: CGFloat {
        // The custom tab bar + paywall banner are added via safe-area insets,
        // so chat content only needs a small breathing space at the bottom.
        18
    }
}

/// Match existing daily credit sheet style (large detent, hidden drag indicator).
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

private struct PulseCreditsPaywallBanner: View {
    let onClose: () -> Void
    let onTapCTA: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Text("Try for free and get 40% off")
                    .font(DesignSystem.Typography.plusJakarta(.bold, size: 16))
                    .foregroundColor(.white)
                
                Spacer(minLength: 0)
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close offer")
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Don’t let preset limit your gains.")
                        .font(DesignSystem.Typography.plusJakarta(.semibold, size: 18))
                        .foregroundColor(DesignSystem.Colors.ink)
                    
                    Text("Upgrade now for unlimited credits and personalized chat. Growth your skills and join our community of 1% best investors.")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                
                Button(action: onTapCTA) {
                    Text("JOIN INFINITE NOW")
                        .font(DesignSystem.Typography.plusJakarta(.bold, size: 16))
                        .foregroundColor(DesignSystem.Colors.accent)
                        .textCase(.uppercase)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .frame(height: 64)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
                .padding(8)
            }
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
            .padding(.horizontal, 4)
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
        .padding(.horizontal, 4)
        .background(DesignSystem.Gradients.chatAccent)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
}

private struct PulseCreditsPaywallSheet: View {
    let onStartTrial: () -> Void
    let onDismiss: () -> Void
    @State private var showMoolaProPaywall: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pulse credits")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Unlock more questions")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 6)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What you get")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        VStack(spacing: 10) {
                            PulsePaywallBenefitRow(
                                icon: "sparkles",
                                title: "More assistant questions",
                                subtitle: "Ask follow-ups when something changes in your portfolio"
                            )
                            
                            PulsePaywallBenefitRow(
                                icon: "person.crop.circle",
                                title: "Personalized context",
                                subtitle: "Answers stay grounded in your linked accounts and allocation"
                            )
                            
                            PulsePaywallBenefitRow(
                                icon: "hand.raised",
                                title: "Neutral guidance",
                                subtitle: "No pushing specific stocks — focused on clarity and what to monitor"
                            )
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    
                    VStack(spacing: 10) {
                        PrimaryButton(title: "Start free trial") {
                            // Keep existing dismissal behavior, but also present RevenueCat paywall.
                            showMoolaProPaywall = true
                            onStartTrial()
                        }
                        
                        SecondaryButton(title: "Not now") {
                            onDismiss()
                        }
                    }
                    .padding(.top, 4)
                    
                    LegalDisclaimer(style: .inline)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showMoolaProPaywall) {
            MoolaProPaywallSheet()
        }
    }
}

private struct PulsePaywallBenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
    }
}

private struct PulseAnswerResult: Equatable {
    let text: String
    let followUpQuestions: [PulseQuestion]
}

private struct PulseQuestion: Identifiable, Equatable {
    enum Kind: Equatable {
        case preset(PulsePreset)
        case followUp(PulseFollowUp)
    }
    
    let id: UUID
    let title: String
    let kind: Kind
    
    init(id: UUID = UUID(), title: String, kind: Kind) {
        self.id = id
        self.title = title
        self.kind = kind
    }
    
    static let initialQuestions: [PulseQuestion] = [
        PulseQuestion(title: "Which market is the most popular right now?", kind: .preset(.popularMarket)),
        PulseQuestion(title: "Can you explain why my biggest holding is down today?", kind: .preset(.biggestHoldingDown)),
        PulseQuestion(title: "What are credits?", kind: .preset(.whatAreCredits))
    ]
    
    static func followUps(afterAnswerAbout focus: String) -> [PulseQuestion] {
        // Requirement: after the first question, the next 2 questions must be based on what the chatbot answered.
        return [
            PulseQuestion(
                title: "How exposed am I to \(focus)?",
                kind: .followUp(.exposureBreakdown(focus: focus))
            ),
            PulseQuestion(
                title: "What should I watch next about \(focus)?",
                kind: .followUp(.whatToWatch(focus: focus))
            ),
            PulseQuestion(title: "What are credits?", kind: .preset(.whatAreCredits))
        ]
    }
}

private enum PulsePreset: String {
    case popularMarket
    case biggestHoldingDown
    case trajectory6m
    case diversification
    case whatAreCredits
}

private enum PulseFollowUp: Equatable {
    case exposureBreakdown(focus: String)
    case whatToWatch(focus: String)
    case resetSuggestions
}

