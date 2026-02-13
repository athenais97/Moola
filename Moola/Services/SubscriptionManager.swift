import Foundation

#if canImport(RevenueCat)
import RevenueCat

/// Central subscription state for the app (RevenueCat-enabled).
///
/// - Exposes `isPro` based on a RevenueCat entitlement.
/// - Fetches Offerings for paywall UIs.
/// - Listens to customer info updates so the UI stays in sync after purchases/restores.
@MainActor
final class SubscriptionManager: ObservableObject {
    /// RevenueCat entitlement identifier for "Moola Pro".
    /// This MUST match the entitlement identifier in the RevenueCat dashboard.
    static let proEntitlementId = "moola_pro"
    
    /// Offering identifier to use when displaying paywalls.
    /// In most cases you can leave this empty and use `offerings.current`.
    static let defaultOfferingId: String? = nil
    
    @Published private(set) var isPro: Bool = false
    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?
    @Published var lastErrorMessage: String?
    
    private var started = false
    private var customerInfoTask: Task<Void, Never>?
    
    func start() {
        guard !started else { return }
        started = true
        
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        
        // Keep the app in sync after purchases, restores, and background refreshes.
        customerInfoTask = Task {
            // `customerInfoStream` is the most reliable way to keep UI updated.
            // If unavailable in your SDK version, remove this and rely on manual refresh + delegates.
            for await info in Purchases.shared.customerInfoStream {
                apply(customerInfo: info)
            }
        }
        
        Task { await refresh() }
    }
    
    func refresh() async {
        do {
            async let info = Purchases.shared.customerInfo()
            async let offs = Purchases.shared.offerings()
            let (customerInfo, offerings) = try await (info, offs)
            
            apply(customerInfo: customerInfo)
            self.offerings = offerings
            self.lastErrorMessage = nil
        } catch {
            self.lastErrorMessage = readable(error)
        }
    }
    
    func restorePurchases() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(customerInfo: info)
            self.lastErrorMessage = nil
        } catch {
            self.lastErrorMessage = readable(error)
        }
    }
    
    func purchase(package: Package) async {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            apply(customerInfo: result.customerInfo)
            self.lastErrorMessage = nil
        } catch {
            self.lastErrorMessage = readable(error)
        }
    }
    
    private func apply(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        self.isPro = customerInfo.entitlements[Self.proEntitlementId]?.isActive == true
    }
    
    private func readable(_ error: Error) -> String {
        return error.localizedDescription
    }
    
    deinit {
        customerInfoTask?.cancel()
    }
}
#else

/// Central subscription state for the app (no RevenueCat linked).
///
/// This stub keeps the app compiling/running in builds where the RevenueCat package
/// is not added to the target. Paywalls will show a fallback UI and purchase actions
/// will be unavailable.
@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var isPro: Bool = false
    @Published var lastErrorMessage: String?
    
    func start() {
        // No-op: RevenueCat not linked.
    }
    
    func refresh() async {
        // No-op: RevenueCat not linked.
    }
    
    func restorePurchases() async {
        // No-op: RevenueCat not linked.
    }
}

#endif

