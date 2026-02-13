import SwiftUI

#if canImport(RevenueCat)
import RevenueCat
#endif

#if canImport(RevenueCatUI)
import RevenueCatUI
#endif

/// Simple subscription screen:
/// - Shows current "Moola Pro" entitlement state
/// - Lets users open a RevenueCat paywall (hosted paywall if RevenueCatUI is available)
/// - Provides restore + customer center (when available)
struct MoolaProView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPaywall: Bool = false
    @State private var showCustomerCenter: Bool = false
    
    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Moola Pro")
                    Spacer()
                    Text(subscriptions.isPro ? "Active" : "Inactive")
                        .foregroundStyle(subscriptions.isPro ? .green : .secondary)
                }
            }
            
            Section("Actions") {
                Button(subscriptions.isPro ? "View plans" : "Upgrade") {
                    showPaywall = true
                }
                
                Button("Restore purchases") {
                    Task { await subscriptions.restorePurchases() }
                }
                
                #if canImport(RevenueCatUI)
                Button("Manage subscription") {
                    showCustomerCenter = true
                }
                #endif
            }
            
            #if canImport(RevenueCat)
            if let info = subscriptions.customerInfo {
                Section("Customer") {
                    LabeledContent("App User ID", value: info.originalAppUserId)
                }
            }
            #endif
        }
        .navigationTitle("Moola Pro")
        .navigationBarTitleDisplayMode(.inline)
        .task { await subscriptions.refresh() }
        .sheet(isPresented: $showPaywall, onDismiss: {
            Task { await subscriptions.refresh() }
        }) {
            MoolaProPaywallSheet()
                .environmentObject(subscriptions)
        }
        #if canImport(RevenueCatUI)
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
        #endif
        .alert("Subscription error", isPresented: .constant(subscriptions.lastErrorMessage != nil)) {
            Button("OK") { subscriptions.lastErrorMessage = nil }
        } message: {
            Text(subscriptions.lastErrorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

/// Paywall sheet.
///
/// Uses RevenueCatUI `PaywallView` when available, otherwise falls back to a basic package list.
struct MoolaProPaywallSheet: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                #if canImport(RevenueCatUI)
                PaywallView(displayCloseButton: true)
                #else
                fallbackPaywall
                #endif
            }
            .navigationTitle("Upgrade to Moola Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { await subscriptions.refresh() }
    }
    
    private var fallbackPaywall: some View {
        List {
            Section {
                Text("Paywall UI isn't available. Add the `RevenueCatUI` product to your Swift Package, or use the hosted paywall.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            #if canImport(RevenueCat)
            if let offering = subscriptions.offerings?.current {
                Section("Plans") {
                    ForEach(offering.availablePackages, id: \.identifier) { pkg in
                        Button {
                            Task { await subscriptions.purchase(package: pkg) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pkg.storeProduct.localizedTitle)
                                Text(pkg.storeProduct.localizedPriceString)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else {
                Section("Plans") {
                    Text("Loading…")
                }
            }
            #endif
            
            Section {
                Button("Restore purchases") {
                    Task { await subscriptions.restorePurchases() }
                }
            }
        }
    }
}

