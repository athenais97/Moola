import SwiftUI
import CoreText

import RevenueCat

/// Ensures bundled custom fonts are registered at runtime.
///
/// Notes:
/// - iOS usually registers fonts automatically via `UIAppFonts` in Info.plist.
/// - This makes font activation resilient when file paths/folders change.
private enum FontRegistration {
    static func registerBundledFonts() {
        let extensions = ["ttf", "otf", "ttc"]
        var urls: [URL] = []
        
        for ext in extensions {
            urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? [])
            urls.append(contentsOf: Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Ressources/Fonts") ?? [])
        }
        
        guard !urls.isEmpty else { return }
        
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

@main
struct MoolaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptions = SubscriptionManager()
    
    init() {
        FontRegistration.registerBundledFonts()

        // IMPORTANT (App Store / TestFlight):
        // RevenueCat iOS SDK keys typically start with "appl_".
        // Avoid crashing on launch if an invalid/non-production key is present.
        let revenueCatAPIKey = "test_TidxjFbILwYCQojoLVyOOhqPKUe"
#if DEBUG
        Purchases.configure(withAPIKey: revenueCatAPIKey)
#else
        if revenueCatAPIKey.hasPrefix("appl_") {
            Purchases.configure(withAPIKey: revenueCatAPIKey)
        }
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(subscriptions)
                // Start after SwiftUI installs the StateObject.
                .task { subscriptions.start() }
        }
    }
}

/// Global app state to manage authentication and navigation
class AppState: ObservableObject {
    enum AuthFlow: Equatable {
        case landing
        case login
        case onboarding
    }
    
    /// Whether user has completed onboarding/login and should see main app
    @Published var isAuthenticated: Bool = false
    
    /// Current logged-in user
    @Published var currentUser: UserModel?
    
    /// Authentication service for login operations
    let authService = AuthenticationService()
    
    /// Which auth screen to show when unauthenticated
    @Published var authFlow: AuthFlow = .landing

    // MARK: - Offer / Paywall banner (sticky, appears once)
    
    /// 25 minutes countdown for the introductory offer.
    private let offerDurationSeconds: Int = 25 * 60
    
    @Published private(set) var isOfferDismissed: Bool = false
    @Published private(set) var offerStartedAt: Date? = nil
    
    /// Legacy property for backward compatibility
    var isOnboardingComplete: Bool {
        get { isAuthenticated }
        set { isAuthenticated = newValue }
    }
    
    init() {
        // Always start on the login/create landing screen.
        // (Login button is enabled only if a stored user exists.)
        authFlow = .landing
        
        // Hydrate offer state (per-user when possible).
        syncOfferStateFromStorage()
    }
    
    /// Called after successful onboarding to transition to main app
    func completeOnboarding(with user: UserModel) {
        currentUser = user
        authService.storeUser(user)
        syncOfferStateFromStorage()
        withAnimation(.easeInOut(duration: 0.5)) {
            isAuthenticated = true
        }
    }
    
    /// Called after successful PIN login to transition to main app
    func loginSuccessful(user: UserModel) {
        currentUser = user
        syncOfferStateFromStorage()
        
        // If the user already completed profiling previously, ensure demo data exists
        // so the app feels "alive" immediately on entry.
        if user.hasCompletedProfiling {
            DemoDataStore.shared.ensureSeededIfNeeded(for: user.email)
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isAuthenticated = true
        }
    }
    
    /// Returns user to auth entry screen (e.g., to switch accounts or logout)
    func returnToAuthEntry() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentUser = nil
            isAuthenticated = false
            // Always route back to landing so users can choose login vs create.
            authFlow = .landing
        }
    }
    
    /// Sign out of the current session (keeps stored user for PIN re-login).
    func logout() {
        authService.logout()
        returnToAuthEntry()
    }
    
    /// Remove the saved account from this device and start onboarding.
    func resetAccountAndStartOnboarding() {
        authService.resetAllLocalState()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentUser = nil
            isAuthenticated = false
            authFlow = .onboarding
        }
    }
    
    func showAuthLanding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAuthenticated = false
            currentUser = nil
            authFlow = .landing
        }
    }
    
    func showLogin() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAuthenticated = false
            currentUser = nil
            authFlow = .login
        }
    }
    
    func startOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAuthenticated = false
            currentUser = nil
            authFlow = .onboarding
        }
    }
    
    /// Called after investor profiling is completed
    func completeInvestorProfiling(with profile: InvestorProfile) {
        currentUser?.investorProfile = profile
        if let user = currentUser {
            authService.storeUser(user)
        }
        
        // Seed connected, realistic demo data now that onboarding + profiling are complete.
        if let email = currentUser?.email, !email.isEmpty {
            DemoDataStore.shared.ensureSeededIfNeeded(for: email)
        }
    }
}

// MARK: - Sticky offer state (persisted)

extension AppState {
    var shouldShowOfferForCurrentUser: Bool {
        // Show only for the free plan.
        let level = currentUser?.membershipLevel ?? .standard
        return level == .standard && offerRemainingSeconds > 0 && !isOfferDismissed
    }
    
    var offerRemainingSeconds: Int {
        guard let started = offerStartedAt else { return offerDurationSeconds }
        let elapsed = Int(Date().timeIntervalSince(started))
        return max(0, offerDurationSeconds - elapsed)
    }
    
    func ensureOfferStartedIfNeeded() {
        guard offerStartedAt == nil else { return }
        let started = Date()
        offerStartedAt = started
        UserDefaults.standard.set(started.timeIntervalSince1970, forKey: offerStartedAtKey())
    }
    
    func dismissOffer() {
        isOfferDismissed = true
        UserDefaults.standard.set(true, forKey: offerDismissedKey())
    }
    
    private func syncOfferStateFromStorage() {
        isOfferDismissed = UserDefaults.standard.bool(forKey: offerDismissedKey())
        if let ts = UserDefaults.standard.object(forKey: offerStartedAtKey()) as? TimeInterval {
            offerStartedAt = Date(timeIntervalSince1970: ts)
        } else {
            offerStartedAt = nil
        }
    }
    
    private func offerDismissedKey() -> String {
        let email = (currentUser?.email ?? "guest").lowercased()
        return "flouze_offer_dismissed_\(email)"
    }
    
    private func offerStartedAtKey() -> String {
        let email = (currentUser?.email ?? "guest").lowercased()
        return "flouze_offer_started_at_\(email)"
    }
}
