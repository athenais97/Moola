import SwiftUI
import UIKit

extension Notification.Name {
    static let flouzeOfferCTATapped = Notification.Name("flouze_offer_cta_tapped")
    static let infinitePaywallRequested = Notification.Name("infinite_paywall_requested")
}

// MARK: - UIImage helpers

private extension UIImage {
    /// Returns true when the image corners are transparent (a strong signal the asset is safe
    /// to use as a template mask). If corners are opaque, `.renderingMode(.template)` will tint
    /// the whole rectangle and icons appear as solid squares.
    func hasTransparentCorners(alphaThreshold: UInt8 = 8) -> Bool {
        guard let cgImage = self.cgImage else { return false }

        // Sample a small, fixed-size rendition to keep this cheap.
        let sampleWidth = 32
        let sampleHeight = 32
        let bytesPerPixel = 4
        let bytesPerRow = sampleWidth * bytesPerPixel

        var pixels = [UInt8](repeating: 0, count: sampleHeight * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: &pixels,
            width: sampleWidth,
            height: sampleHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }

        ctx.interpolationQuality = .none
        ctx.clear(CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))

        func alphaAt(x: Int, y: Int) -> UInt8 {
            let idx = (y * bytesPerRow) + (x * bytesPerPixel) + 3
            return pixels[idx]
        }

        let corners: [(Int, Int)] = [
            (0, 0),
            (sampleWidth - 1, 0),
            (0, sampleHeight - 1),
            (sampleWidth - 1, sampleHeight - 1)
        ]

        // If corners are transparent, this is likely a true glyph with transparency around it.
        // If corners are opaque, template rendering will tint a solid square.
        return corners.allSatisfy { (x, y) in alphaAt(x: x, y: y) <= alphaThreshold }
    }
}

/// Main tab-based navigation after authentication.
/// Current tabs: Home, Insights, Chat, Profile.
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Tab
    @State private var isTabBarHidden: Bool = false
    @State private var isOfferCardVisible: Bool = false
    @State private var lastNonChatTab: Tab = .home
    @State private var showInfinitePaywall: Bool = false
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case insights = "Insights"
        case chat = "Chat"
        case profile = "Profile"
        
        var systemIcon: String {
            switch self {
            case .home: return "house"
            case .insights: return "folder"
            case .chat: return "message"
            case .profile: return "person"
            }
        }
        
        var iconAssetName: String {
            switch self {
            case .home: return "TabIconHome"
            case .insights: return "TabIconInsights"
            case .chat: return "TabIconChat"
            case .profile: return "TabIconProfile"
            }
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            TabView(selection: $selectedTab) {
                PulseView(selectedTab: $selectedTab)
                    .environmentObject(appState)
                    .tabItem { EmptyView() }
                    .tag(Tab.home)
                
                InsightsView()
                    .environmentObject(appState)
                    .tabItem { EmptyView() }
                    .tag(Tab.insights)

                PulseAssistantView(
                    onBack: {
                        // When Chat is a root tab, the back arrow should return
                        // to wherever the user came from (previous tab).
                        selectedTab = lastNonChatTab
                    }
                )
                .tabItem { EmptyView() }
                .tag(Tab.chat)
                
                AccountTabView()
                    .environmentObject(appState)
                    .tabItem { EmptyView() }
                    .tag(Tab.profile)
            }
            .modifier(HideSystemTabBar())
            .onChange(of: selectedTab) { _, newValue in
                if newValue != .chat {
                    lastNonChatTab = newValue
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .infinitePaywallRequested)) { _ in
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                showInfinitePaywall = true
            }
            .sheet(isPresented: $showInfinitePaywall) {
                InfinitePaywallSheet(
                    onStartTrial: {
                        // Hook up to purchase flow when available.
                        showInfinitePaywall = false
                    },
                    onDismiss: {
                        showInfinitePaywall = false
                    }
                )
                .flouzePaywallPresentation()
            }
            .onPreferenceChange(FlouzeTabBarHiddenPreferenceKey.self) { newValue in
                isTabBarHidden = newValue
            }
            .onPreferenceChange(FlouzeOfferCardVisiblePreferenceKey.self) { newValue in
                isOfferCardVisible = newValue
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    if !isTabBarHidden, isOfferCardVisible, appState.shouldShowOfferForCurrentUser {
                        FlouzeStickyOfferCard(
                            remainingSeconds: appState.offerRemainingSeconds,
                            onClose: { appState.dismissOffer() },
                            onPrimaryAction: onTapOfferCTA
                        )
                        .padding(.horizontal, 18)
                        .padding(.bottom, 10)
                        .onAppear {
                            appState.ensureOfferStartedIfNeeded()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if !isTabBarHidden {
                        FlouzeTabBar(
                            selectedTab: $selectedTab,
                            safeAreaBottomInset: proxy.safeAreaInsets.bottom
                        )
                    }
                }
            }
        }
    }
    
    private func onTapOfferCTA() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        if selectedTab == .chat {
            NotificationCenter.default.post(name: .flouzeOfferCTATapped, object: nil)
        } else {
            selectedTab = .insights
        }
    }
}

private struct HideSystemTabBar: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .toolbar(.hidden, for: .tabBar)
        } else {
            content
                .onAppear {
                    UITabBar.appearance().isHidden = true
                }
        }
    }
}

// MARK: - Custom tab bar (Figma)

private struct FlouzeTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let safeAreaBottomInset: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            tabItem(.home)
            Spacer(minLength: 0)
            tabItem(.insights)
            Spacer(minLength: 0)
            tabItem(.chat)
            Spacer(minLength: 0)
            tabItem(.profile)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, tabBarBottomPadding)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color(hex: "F8F8F8") ?? DesignSystem.Colors.separator, lineWidth: 1)
        )
        .shadow(
            color: (Color(hex: "F8F8F8") ?? DesignSystem.Colors.separator),
            radius: 5.7,
            x: 0,
            y: -1
        )
    }
    
    private var tabBarBottomPadding: CGFloat {
        // Design tweak: tab bar was sitting slightly too high.
        // Reduce bottom padding by ~20pt while keeping it non-negative.
        let adjustment: CGFloat = 20

        // Figma's bottom padding includes the home indicator space.
        // When used in SwiftUI via `safeAreaInset`, we must avoid double-counting
        // that space; instead, mirror the visual by basing it on safe-area.
        if safeAreaBottomInset > 0 {
            return max(0, (safeAreaBottomInset + 2) - adjustment)
        }
        return max(0, 16 - adjustment)
    }
    
    private func tabItem(_ tab: MainTabView.Tab) -> some View {
        let isSelected = selectedTab == tab
        // Spec: selected = black, unselected = grey.
        let selectedTint: Color = .black
        let unselectedTint: Color = DesignSystem.Colors.inkSecondary
        let tint = isSelected ? selectedTint : unselectedTint
        
        return Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            selectedTab = tab
        } label: {
            VStack(spacing: 5) {
                tabIcon(for: tab, tint: tint)
                
                Text(tab.rawValue)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(tint)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
    }

    private func tabIcon(for tab: MainTabView.Tab, tint: Color) -> some View {
        let image: Image = {
            // Prefer template rendering so selection tint updates reliably.
            if let uiImage = UIImage(named: tab.iconAssetName, in: .main, compatibleWith: nil),
               uiImage.hasTransparentCorners() {
                return Image(uiImage: uiImage.withRenderingMode(.alwaysTemplate))
            }

            // Fallback so tabs never appear "empty" if an asset is missing.
            return Image(systemName: tab.systemIcon)
        }()
        
        return image
            .resizable()
            .scaledToFit()
            .foregroundColor(tint)
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
    }
}

// MARK: - Tab bar visibility (custom tab bar)

private struct FlouzeTabBarHiddenPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        // If any child view requests hiding, hide it.
        value = value || nextValue()
    }
}

extension View {
    /// Hide Flouze custom tab bar for a sub-tree (e.g. full-screen flows).
    func flouzeTabBarHidden(_ hidden: Bool) -> some View {
        preference(key: FlouzeTabBarHiddenPreferenceKey.self, value: hidden)
    }
}

private struct FlouzeOfferCardVisiblePreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Request the global sticky offer card to be shown above the tab bar.
    func flouzeOfferCardVisible(_ visible: Bool) -> some View {
        preference(key: FlouzeOfferCardVisiblePreferenceKey.self, value: visible)
    }
}

/// Account tab content (different from the full-screen AccountView modal).
struct AccountTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var subscriptions: SubscriptionManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundCanvas
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    DesignSystem.Gradients.homeHero
                        .frame(height: 482)
                        .frame(maxWidth: .infinity)
                    
                    Spacer(minLength: 0)
                }
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hello, \(firstName)")
                                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                                .foregroundColor(Color(hex: "707D8B") ?? DesignSystem.Colors.inkSecondary)
                            
                            Text("Account")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.ink)
                        }
                        .padding(.top, 22)
                        
                        VStack(spacing: 8) {
                            profileIdentityCard
                            profileOfferCard
                        }
                        .padding(.top, 4)
                        
                        sectionHeader("Informations")
                            .padding(.top, 6)
                        
                        infoGroupCard
                        
                        signOutCard
                            .padding(.top, 2)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var firstName: String {
        let name = appState.currentUser?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = name?.split(separator: " ").first.map(String.init)
        return first?.isEmpty == false ? (first ?? "User") : "User"
    }
    
    private var initials: String {
        guard let name = appState.currentUser?.name else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private var profileIdentityCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DesignSystem.Gradients.chatAccentSoft)
                .frame(width: 53, height: 53)
                .overlay(
                    Text(initials)
                        .font(DesignSystem.Typography.plusJakarta(.bold, size: 16))
                        .foregroundColor(DesignSystem.Colors.ink)
                )
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(appState.currentUser?.name ?? "User")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(appState.currentUser?.email ?? "—")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.inkSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
    
    private var profileOfferCard: some View {
        Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            NotificationCenter.default.post(name: .infinitePaywallRequested, object: nil)
        } label: {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Try for free and get 40% off")
                        .font(DesignSystem.Typography.plusJakarta(.semibold, size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 0) {
                    Text("JOIN INFINITE NOW")
                        .font(DesignSystem.Typography.plusJakarta(.bold, size: 16))
                        .foregroundColor(DesignSystem.Colors.accent)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
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
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Gradients.chatAccent)
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
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
            .foregroundColor(DesignSystem.Colors.inkSecondary)
    }
    
    private var infoGroupCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                MoolaProView()
                    .environmentObject(subscriptions)
            } label: {
                ProfileRow(
                    iconSystemName: "crown",
                    title: "Moola Pro",
                    titleColor: DesignSystem.Colors.ink
                )
            }
            .buttonStyle(.plain)
            
            Divider().overlay(DesignSystem.Colors.separator)
            
            NavigationLink {
                PersonalInfoView()
                    .environmentObject(appState)
            } label: {
                ProfileRow(
                    iconSystemName: "person",
                    title: "Personal Info",
                    titleColor: DesignSystem.Colors.ink
                )
            }
            .buttonStyle(.plain)
            
            Divider().overlay(DesignSystem.Colors.separator)
            
            NavigationLink {
                SyncedAccountsView()
                    .environmentObject(appState)
            } label: {
                ProfileRow(
                    iconSystemName: "wallet.pass",
                    title: "Connected Accounts",
                    titleColor: DesignSystem.Colors.ink
                )
            }
            .buttonStyle(.plain)
            
            Divider().overlay(DesignSystem.Colors.separator)
            
            NavigationLink {
                NotificationsSettingsView()
            } label: {
                ProfileRow(
                    iconSystemName: "bell",
                    title: "Notifications",
                    titleColor: DesignSystem.Colors.ink
                )
            }
            .buttonStyle(.plain)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
    
    private var signOutCard: some View {
        Button {
            appState.returnToAuthEntry()
        } label: {
            ProfileRow(
                iconSystemName: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                titleColor: (Color(hex: "FF3E41") ?? DesignSystem.Colors.negative)
            )
        }
        .buttonStyle(.plain)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
}

private struct ProfileRow: View {
    let iconSystemName: String
    let title: String
    let titleColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.80))
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
                        .foregroundColor(DesignSystem.Colors.inkSecondary.opacity(0.85))
                )
            
            Text(title)
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(titleColor)
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.inkSecondary.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 19)
    }
}

// MARK: - Sticky offer card (Home + Chat)

private struct FlouzeStickyOfferCard: View {
    let remainingSeconds: Int
    let onClose: () -> Void
    let onPrimaryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Text("Offer will be out in \(remainingText)")
                    .font(DesignSystem.Typography.plusJakarta(.bold, size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
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
                    Text("Don’t sleep on it.")
                        .font(DesignSystem.Typography.plusJakarta(.semibold, size: 18))
                        .foregroundColor(DesignSystem.Colors.ink)
                    
                    Text("Unlock exclusive news, account restrictions, and unlimited chat to maximise your invests.")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.ink.opacity(0.7))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                
                Button(action: onPrimaryAction) {
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
    
    private var remainingText: String {
        let seconds = max(0, remainingSeconds)
        let minutes = seconds / 60
        let remaining = seconds % 60
        return "\(minutes)m\(String(format: "%02d", remaining))"
    }
}

#Preview("Main Tab View") {
    MainTabView(selectedTab: .constant(.home))
        .environmentObject({
            let state = AppState()
            state.currentUser = UserModel(
                name: "Jean Dupont",
                email: "jean@example.com",
                membershipLevel: .premium
            )
            return state
        }())
}

// MARK: - Infinite upgrade paywall (shared entry point)

/// Unified "Infinite" upgrade paywall.
/// Shows the main benefits of upgrading: real-time chatbot advice + market insights.
private struct InfinitePaywallSheet: View {
    let onStartTrial: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            let designWidth: CGFloat = 390
            let designHeight: CGFloat = 844
            let scale = min(1, proxy.size.width / designWidth)
            let scaledHeight = designHeight * scale
            
            ZStack(alignment: .top) {
                // Fill the full sheet width so we don't get white side gutters.
                LinearGradient(
                    colors: [
                        Color(hex: "94CCFF") ?? DesignSystem.Colors.accent.opacity(0.35),
                        Color(hex: "BDA0FF") ?? DesignSystem.Colors.focusBorder
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    InfinitePaywallCanvas(
                        onJoinYear: onStartTrial,
                        onJoinMonth: onStartTrial,
                        onTryFree: onStartTrial
                    )
                        .frame(width: designWidth, height: designHeight)
                        .scaleEffect(scale, anchor: .top)
                        .frame(maxWidth: .infinity, minHeight: scaledHeight, alignment: .top)
                }
                
                // Bottom-sheet handle bar.
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct InfinitePaywallCanvas: View {
    let onJoinYear: () -> Void
    let onJoinMonth: () -> Void
    let onTryFree: () -> Void
    
    private let size = CGSize(width: 390, height: 844)
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("InfinitePaywallBottomSheet")
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .accessibilityHidden(true)
            
            // Transparent tappable overlays for each CTA zone in the PNG.
            // Note: positions are in the 390x844 design coordinate space.
            Button(action: onJoinYear) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.001))
                    .frame(width: 346, height: 64)
            }
            .buttonStyle(.plain)
            .position(x: 195, y: 552)
            .accessibilityLabel("Join Infinite yearly")
            
            Button(action: onJoinMonth) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.001))
                    .frame(width: 346, height: 64)
            }
            .buttonStyle(.plain)
            .position(x: 195, y: 635)
            .accessibilityLabel("Join Infinite monthly")
            
            Button(action: onTryFree) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.001))
                    .frame(width: 360, height: 64)
            }
            .buttonStyle(.plain)
            .position(x: 195, y: 752)
            .accessibilityLabel("Try Infinite for free")
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .ignoresSafeArea()
    }
}

private struct InfinitePaywallComparisonCard: View {
    let title: String
    let bodyText: String
    let baseImageName: String
    let overlayImageName: String
    let baseImageSize: CGSize
    let overlayImageSize: CGSize
    /// Origin (top-left) inside the 337x69 content rect.
    let imageOrigin: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(title)
                            .font(DesignSystem.Typography.ibmPlexSansHebrew(.semibold, size: 16))
                            .foregroundColor(DesignSystem.Colors.ink)
                        
                        Text(bodyText)
                            .font(DesignSystem.Typography.ibmPlexSansHebrew(.regular, size: 14))
                            .foregroundColor(DesignSystem.Colors.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: 209.654, alignment: .leading)
                    
                    Image(baseImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: baseImageSize.width, height: baseImageSize.height)
                        .position(
                            x: imageOrigin.x + (baseImageSize.width / 2),
                            y: imageOrigin.y + (baseImageSize.height / 2)
                        )
                        .accessibilityHidden(true)
                    
                    Image(overlayImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: overlayImageSize.width, height: overlayImageSize.height)
                        .position(
                            x: imageOrigin.x + (overlayImageSize.width / 2),
                            y: imageOrigin.y + (overlayImageSize.height / 2)
                        )
                        .accessibilityHidden(true)
                }
                .frame(width: 337, height: 69, alignment: .topLeading)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
    }
}

private struct InfinitePaywallPlansCard: View {
    let onJoinYear: () -> Void
    let onJoinMonth: () -> Void
    
    private var planGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "BDA0FF") ?? DesignSystem.Colors.focusBorder,
                Color(hex: "94CCFF") ?? DesignSystem.Colors.accent.opacity(0.35),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "FBFBFB") ?? DesignSystem.Colors.backgroundCanvas
            
            VStack(alignment: .leading, spacing: 12) {
                // Best value
                VStack(spacing: 0) {
                    VStack(alignment: .center, spacing: 0) {
                        Text("Best value")
                            .font(DesignSystem.Typography.ibmPlexSansHebrew(.semibold, size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    Button(action: onJoinYear) {
                        Text("JOIN FOR $109,99 a year ($9.99/m)")
                            .font(DesignSystem.Typography.ibmPlexSansHebrew(.bold, size: 16))
                            .foregroundColor(DesignSystem.Colors.accent)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 346)
                .background(planGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                // Monthly
                Button(action: onJoinMonth) {
                    HStack(spacing: 0) {
                        Text("JOIN FOR ")
                        Text("$25,99")
                            .strikethrough(true)
                        Text(" $15,99 per month")
                    }
                    .font(DesignSystem.Typography.ibmPlexSansHebrew(.bold, size: 16))
                    .foregroundColor(DesignSystem.Colors.accent)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
                    .padding(4)
                }
                .buttonStyle(.plain)
                .frame(width: 346)
                .background(planGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(12)
            
            // Decorative stickers (positioned in the 370x219 coordinate space).
            Image("PaywallCalqueLeft")
                .resizable()
                .scaledToFit()
                .frame(width: 52.36, height: 56.191)
                .rotationEffect(.degrees(-6))
                .frame(width: 57.947, height: 61.356)
                .offset(x: 15, y: -28)
                .accessibilityHidden(true)
            
            Image("PaywallCalqueRight")
                .resizable()
                .scaledToFit()
                .frame(width: 29.719, height: 31.893)
                .rotationEffect(.degrees(8))
                .frame(width: 33.868, height: 35.719)
                .offset(x: 286, y: -6)
                .accessibilityHidden(true)
            
            Image("PaywallTicketDiscount")
                .resizable()
                .scaledToFit()
                .frame(width: 39.799, height: 38.986)
                .rotationEffect(.degrees(165))
                .frame(width: 48.533, height: 47.959)
                .offset(x: 318.69, y: 184.99)
                .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private extension View {
    /// Keep paywall as a bottom sheet when available (iOS 16+).
    @ViewBuilder
    func flouzePaywallPresentation() -> some View {
        if #available(iOS 16.0, *) {
            self
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        } else {
            self
        }
    }
}