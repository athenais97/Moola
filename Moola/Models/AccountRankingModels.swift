import Foundation
import SwiftUI

// MARK: - Performance Metric

/// Toggle between absolute ($) and percentage (%) display
enum PerformanceMetric: String, CaseIterable, Identifiable {
    case currency = "Currency"
    case percentage = "Percentage"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .currency: return "$"
        case .percentage: return "%"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .currency: return "Show currency values"
        case .percentage: return "Show percentage values"
        }
    }
}

// MARK: - Ranking State

/// State of the ranking calculation
enum RankingState: Equatable {
    case loading
    case loaded
    case insufficientData
    case allNegative
    case noAccounts
    case error(String)
    
    var isDefensiveMode: Bool {
        self == .allNegative
    }
    
    var emptyStateMessage: String {
        switch self {
        case .insufficientData:
            return "Connect accounts and wait 24 hours\nfor performance data to accumulate."
        case .noAccounts:
            return "Link your financial accounts to see\nwhich ones are performing best."
        case .error(let message):
            return message
        default:
            return "No ranking data available."
        }
    }
}

// MARK: - Ranked Account

/// An account with calculated performance metrics for ranking
struct RankedAccount: Identifiable, Equatable {
    let id: String
    let accountName: String
    let institutionName: String
    let institutionLogoName: String
    let brandColor: Color
    let currentBalance: Decimal
    let previousBalance: Decimal
    let absoluteGain: Decimal
    let percentageGain: Decimal
    let balanceHistory: [Decimal]
    let hasInsufficientData: Bool
    
    /// Whether the account has positive performance
    var isPositive: Bool {
        absoluteGain >= 0
    }
    
    /// Color based on performance
    var performanceColor: Color {
        if absoluteGain > 0 {
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        } else if absoluteGain < 0 {
            return Color(red: 0.95, green: 0.5, blue: 0.45)
        }
        return .secondary
    }
    
    /// Formatted absolute gain with sign
    var formattedAbsoluteGain: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        return formatter.string(from: NSDecimalNumber(decimal: absoluteGain)) ?? "$0.00"
    }
    
    /// Formatted percentage gain with sign
    var formattedPercentageGain: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "+"
        formatter.negativePrefix = ""
        let percentString = formatter.string(from: NSDecimalNumber(decimal: percentageGain)) ?? "0.0"
        return "\(percentString)%"
    }
    
    /// Display value based on selected metric
    func displayValue(for metric: PerformanceMetric, masked: Bool) -> String {
        if masked {
            return "••••••"
        }
        
        switch metric {
        case .currency:
            return formattedAbsoluteGain
        case .percentage:
            return formattedPercentageGain
        }
    }
    
    static func == (lhs: RankedAccount, rhs: RankedAccount) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Sample Data
    
    static let sampleAccounts: [RankedAccount] = [
        RankedAccount(
            id: "fidelity_investment",
            accountName: "Investment Portfolio",
            institutionName: "Fidelity",
            institutionLogoName: "chart.line.uptrend.xyaxis",
            brandColor: Color(red: 0.3, green: 0.5, blue: 0.3),
            currentBalance: 156789.45,
            previousBalance: 145000.00,
            absoluteGain: 11789.45,
            percentageGain: 8.13,
            balanceHistory: [145000, 147500, 149200, 152100, 154800, 155900, 156789.45].map { Decimal($0) },
            hasInsufficientData: false
        ),
        RankedAccount(
            id: "chase_checking",
            accountName: "Primary Checking",
            institutionName: "Chase",
            institutionLogoName: "building.columns.fill",
            brandColor: Color(red: 0.07, green: 0.48, blue: 0.79),
            currentBalance: 12450.32,
            previousBalance: 11500.00,
            absoluteGain: 950.32,
            percentageGain: 8.26,
            balanceHistory: [11500, 11650, 11800, 12100, 12300, 12400, 12450.32].map { Decimal($0) },
            hasInsufficientData: false
        ),
        RankedAccount(
            id: "coinbase_crypto",
            accountName: "Crypto Wallet",
            institutionName: "Coinbase",
            institutionLogoName: "bitcoinsign.circle.fill",
            brandColor: Color(red: 0.0, green: 0.5, blue: 0.88),
            currentBalance: 8750.00,
            previousBalance: 8200.00,
            absoluteGain: 550.00,
            percentageGain: 6.71,
            balanceHistory: [8200, 8100, 8400, 8600, 8500, 8700, 8750].map { Decimal($0) },
            hasInsufficientData: false
        ),
        RankedAccount(
            id: "bofa_savings",
            accountName: "High Yield Savings",
            institutionName: "Bank of America",
            institutionLogoName: "banknote.fill",
            brandColor: Color(red: 0.89, green: 0.1, blue: 0.21),
            currentBalance: 25000.00,
            previousBalance: 24800.00,
            absoluteGain: 200.00,
            percentageGain: 0.81,
            balanceHistory: [24800, 24850, 24900, 24920, 24950, 24980, 25000].map { Decimal($0) },
            hasInsufficientData: false
        )
    ]
    
    static let sampleNegativeAccounts: [RankedAccount] = [
        RankedAccount(
            id: "crypto_negative",
            accountName: "Crypto Portfolio",
            institutionName: "Coinbase",
            institutionLogoName: "bitcoinsign.circle.fill",
            brandColor: Color(red: 0.0, green: 0.5, blue: 0.88),
            currentBalance: 7500.00,
            previousBalance: 10000.00,
            absoluteGain: -2500.00,
            percentageGain: -25.0,
            balanceHistory: [10000, 9500, 9000, 8500, 8000, 7800, 7500].map { Decimal($0) },
            hasInsufficientData: false
        )
    ]
}
