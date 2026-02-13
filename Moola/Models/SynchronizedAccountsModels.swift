import Foundation
import SwiftUI

// MARK: - Synchronized Institution

/// Represents a financial institution (bank/brokerage) with all its linked accounts
/// UX Intent: Group accounts by institution for visual hierarchy and easy scanning
struct SynchronizedInstitution: Identifiable {
    let id: String
    let name: String
    let logoName: String
    let primaryColor: String
    let accounts: [SynchronizedAccount]
    let connectionStatus: ConnectionStatus
    let lastSyncDate: Date
    let requiresReauthentication: Bool
    
    /// Total balance across all accounts at this institution
    var totalBalance: Decimal {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    /// Formatted total balance string
    var formattedTotalBalance: String {
        CurrencyFormatter.format(totalBalance, currencyCode: primaryCurrencyCode)
    }
    
    /// Primary currency (most common among accounts)
    var primaryCurrencyCode: String {
        let currencies = accounts.map { $0.currencyCode }
        let counts = Dictionary(grouping: currencies, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "USD"
    }
    
    /// Whether any account needs attention
    var needsAttention: Bool {
        connectionStatus != .active || requiresReauthentication
    }
    
    /// Human-readable last sync description
    var lastSyncDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: lastSyncDate, relativeTo: Date()))"
    }
    
    /// Minutes since last sync
    var minutesSinceSync: Int {
        Int(Date().timeIntervalSince(lastSyncDate) / 60)
    }
    
    /// Brand color for the institution
    var brandColor: Color {
        Color(hex: primaryColor) ?? .blue
    }
    
    // MARK: - Sample Data
    
    static let sampleInstitutions: [SynchronizedInstitution] = [
        SynchronizedInstitution(
            id: "chase_001",
            name: "Chase",
            logoName: "building.columns.fill",
            primaryColor: "#117ACA",
            accounts: [
                SynchronizedAccount(
                    id: "chase_checking",
                    name: "Primary Checking",
                    accountType: .checking,
                    maskedNumber: "••••4521",
                    balance: 12450.32,
                    currencyCode: "USD",
                    isActive: true
                ),
                SynchronizedAccount(
                    id: "chase_savings",
                    name: "High-Yield Savings",
                    accountType: .savings,
                    maskedNumber: "••••7832",
                    balance: 45230.00,
                    currencyCode: "USD",
                    isActive: true
                )
            ],
            connectionStatus: .active,
            lastSyncDate: Date().addingTimeInterval(-1800), // 30 min ago
            requiresReauthentication: false
        ),
        SynchronizedInstitution(
            id: "fidelity_001",
            name: "Fidelity",
            logoName: "chart.line.uptrend.xyaxis",
            primaryColor: "#4E8542",
            accounts: [
                SynchronizedAccount(
                    id: "fidelity_investment",
                    name: "Investment Portfolio",
                    accountType: .investment,
                    maskedNumber: "••••9104",
                    balance: 156789.45,
                    currencyCode: "USD",
                    isActive: true
                ),
                SynchronizedAccount(
                    id: "fidelity_retirement",
                    name: "401(k) Retirement",
                    accountType: .retirement,
                    maskedNumber: "••••3388",
                    balance: 89432.10,
                    currencyCode: "USD",
                    isActive: true
                )
            ],
            connectionStatus: .active,
            lastSyncDate: Date().addingTimeInterval(-3600), // 1 hour ago
            requiresReauthentication: false
        ),
        SynchronizedInstitution(
            id: "bofa_001",
            name: "Bank of America",
            logoName: "building.columns.fill",
            primaryColor: "#E31837",
            accounts: [
                SynchronizedAccount(
                    id: "bofa_checking",
                    name: "Advantage Checking",
                    accountType: .checking,
                    maskedNumber: "••••2847",
                    balance: 3250.75,
                    currencyCode: "USD",
                    isActive: true
                )
            ],
            connectionStatus: .needsAttention,
            lastSyncDate: Date().addingTimeInterval(-86400), // 24 hours ago
            requiresReauthentication: true
        )
    ]
    
    static let sampleWithExpired: [SynchronizedInstitution] = [
        sampleInstitutions[0],
        SynchronizedInstitution(
            id: "wells_expired",
            name: "Wells Fargo",
            logoName: "building.columns.fill",
            primaryColor: "#D71E28",
            accounts: [
                SynchronizedAccount(
                    id: "wells_checking",
                    name: "Everyday Checking",
                    accountType: .checking,
                    maskedNumber: "••••6612",
                    balance: 0, // Unknown due to expired connection
                    currencyCode: "USD",
                    isActive: false
                )
            ],
            connectionStatus: .expired,
            lastSyncDate: Date().addingTimeInterval(-604800), // 7 days ago
            requiresReauthentication: true
        )
    ]
}

// MARK: - Synchronized Account

/// Represents an individual account within an institution
/// UX Intent: Clear display of account type, identifier, and balance
struct SynchronizedAccount: Identifiable {
    let id: String
    let name: String
    let accountType: SyncedAccountType
    let maskedNumber: String
    let balance: Decimal
    let currencyCode: String
    let isActive: Bool
    
    /// Formatted balance string
    var formattedBalance: String {
        CurrencyFormatter.format(balance, currencyCode: currencyCode)
    }
    
    /// Privacy-masked balance
    var maskedBalance: String {
        "••••••"
    }
    
    /// Display identifier combining type and masked number
    var displayIdentifier: String {
        "\(accountType.displayName) \(maskedNumber)"
    }
}

// MARK: - Account Type

/// Types of synchronized accounts with appropriate icons and colors
enum SyncedAccountType: String, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case investment = "Investment"
    case retirement = "Retirement"
    case creditCard = "Credit Card"
    case loan = "Loan"
    case crypto = "Crypto"
    
    var displayName: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .checking:
            return "creditcard.fill"
        case .savings:
            return "banknote.fill"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        case .retirement:
            return "leaf.fill"
        case .creditCard:
            return "creditcard.fill"
        case .loan:
            return "building.columns.fill"
        case .crypto:
            return "bitcoinsign.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .checking:
            return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .savings:
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .investment:
            return Color(red: 0.6, green: 0.5, blue: 0.8)
        case .retirement:
            return Color(red: 0.4, green: 0.75, blue: 0.65)
        case .creditCard:
            return Color(red: 0.95, green: 0.65, blue: 0.3)
        case .loan:
            return Color(red: 0.9, green: 0.5, blue: 0.5)
        case .crypto:
            return Color(red: 0.95, green: 0.7, blue: 0.2)
        }
    }
}

// MARK: - Connection Status

/// Health status of a bank connection
/// UX Intent: Clear visual hierarchy for connection states
enum ConnectionStatus: String, CaseIterable {
    case active = "Active"
    case needsAttention = "Needs Attention"
    case expired = "Expired"
    case syncing = "Syncing"
    
    var color: Color {
        switch self {
        case .active:
            return Color(red: 0.2, green: 0.75, blue: 0.4)
        case .needsAttention:
            return Color(red: 0.95, green: 0.7, blue: 0.2)
        case .expired:
            return Color(red: 0.95, green: 0.4, blue: 0.4)
        case .syncing:
            return Color(red: 0.3, green: 0.6, blue: 0.9)
        }
    }
    
    var iconName: String {
        switch self {
        case .active:
            return "checkmark.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        case .expired:
            return "xmark.circle.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .active:
            return "Connected"
        case .needsAttention:
            return "Action Required"
        case .expired:
            return "Reconnect Needed"
        case .syncing:
            return "Updating..."
        }
    }
}

// MARK: - Currency Formatter

/// Centralized currency formatting with conversion support
struct CurrencyFormatter {
    
    /// Formats a decimal amount with currency symbol
    static func format(_ amount: Decimal, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    /// Formats amount with privacy masking option
    static func format(_ amount: Decimal, currencyCode: String = "USD", masked: Bool) -> String {
        if masked {
            return "••••••"
        }
        return format(amount, currencyCode: currencyCode)
    }
    
    /// Formats aggregated balance with optional conversion note
    static func formatAggregated(
        _ amount: Decimal,
        baseCurrency: String = "USD",
        hasMultipleCurrencies: Bool
    ) -> (balance: String, note: String?) {
        let formatted = format(amount, currencyCode: baseCurrency)
        let note: String? = hasMultipleCurrencies 
            ? "Converted to \(baseCurrency) at current rates" 
            : nil
        return (formatted, note)
    }
}

// MARK: - Aggregated Portfolio

/// Computed aggregation across all synchronized institutions
/// UX Intent: Provide at-a-glance total financial picture
struct AggregatedPortfolio {
    let institutions: [SynchronizedInstitution]
    let baseCurrencyCode: String
    
    /// Total balance across all institutions
    var totalBalance: Decimal {
        institutions.reduce(0) { $0 + $1.totalBalance }
    }
    
    /// Formatted total balance
    var formattedTotalBalance: String {
        CurrencyFormatter.format(totalBalance, currencyCode: baseCurrencyCode)
    }
    
    /// Total number of accounts
    var totalAccountCount: Int {
        institutions.reduce(0) { $0 + $1.accounts.count }
    }
    
    /// Whether multiple currencies are present
    var hasMultipleCurrencies: Bool {
        let currencies = Set(institutions.flatMap { $0.accounts.map { $0.currencyCode } })
        return currencies.count > 1
    }
    
    /// Number of institutions needing attention
    var institutionsNeedingAttention: Int {
        institutions.filter { $0.needsAttention }.count
    }
    
    /// Most recent sync date across all institutions
    var mostRecentSyncDate: Date? {
        institutions.map { $0.lastSyncDate }.max()
    }
    
    /// Human-readable last sync description
    var lastSyncDescription: String {
        guard let date = mostRecentSyncDate else {
            return "Never synced"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
    
    /// Whether data is considered stale (> 24 hours)
    var isStale: Bool {
        guard let date = mostRecentSyncDate else { return true }
        return Date().timeIntervalSince(date) > 24 * 60 * 60
    }
    
    static let sample = AggregatedPortfolio(
        institutions: SynchronizedInstitution.sampleInstitutions,
        baseCurrencyCode: "USD"
    )
    
    static let empty = AggregatedPortfolio(
        institutions: [],
        baseCurrencyCode: "USD"
    )
}
