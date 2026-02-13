import Foundation
import SwiftUI

// MARK: - Portfolio Summary

/// Represents the user's complete financial portfolio state
/// UX Intent: Single source of truth for the Pulse dashboard
struct PortfolioSummary {
    let totalBalance: Decimal
    let investedCapital: Decimal
    let lastSyncDate: Date
    let balanceHistory: [BalanceDataPoint]
    let assetAllocation: AssetAllocation
    let accounts: [PortfolioAccount]
    let recentTransactions: [Transaction]
    
    /// Calculates the change in balance over a period
    var balanceChange: BalanceChange {
        guard balanceHistory.count >= 2,
              let oldest = balanceHistory.first,
              let newest = balanceHistory.last else {
            return BalanceChange(amount: 0, percentage: 0, period: .week)
        }
        
        let change = newest.value - oldest.value
        let percentage = oldest.value != 0 
            ? (change / oldest.value) * 100 
            : 0
        
        return BalanceChange(
            amount: change,
            percentage: percentage,
            period: .week
        )
    }
    
    /// Whether the data is considered stale (> 24 hours old)
    var isStale: Bool {
        Date().timeIntervalSince(lastSyncDate) > 24 * 60 * 60
    }
    
    /// Human-readable last sync description
    var lastSyncDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSyncDate, relativeTo: Date())
    }
    
    // MARK: - Sample Data
    
    static let sample = PortfolioSummary(
        totalBalance: 127450.32,
        investedCapital: 98200.00,
        lastSyncDate: Date().addingTimeInterval(-3600), // 1 hour ago
        balanceHistory: BalanceDataPoint.sampleWeekData,
        assetAllocation: .sample,
        accounts: PortfolioAccount.sampleAccounts,
        recentTransactions: Transaction.sampleTransactions
    )
    
    static let empty = PortfolioSummary(
        totalBalance: 0,
        investedCapital: 0,
        lastSyncDate: Date(),
        balanceHistory: [],
        assetAllocation: AssetAllocation(cash: 0, stocks: 0, crypto: 0, other: 0),
        accounts: [],
        recentTransactions: []
    )
    
    static let staleData = PortfolioSummary(
        totalBalance: 125000.00,
        investedCapital: 95000.00,
        lastSyncDate: Date().addingTimeInterval(-26 * 60 * 60), // 26 hours ago
        balanceHistory: BalanceDataPoint.sampleWeekData,
        assetAllocation: .sample,
        accounts: PortfolioAccount.sampleAccounts,
        recentTransactions: Transaction.sampleTransactions
    )
}

// MARK: - Balance Data Point

/// A single point in the balance history for sparkline visualization
struct BalanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Decimal
    
    /// Sample week data for sparkline demonstration
    static var sampleWeekData: [BalanceDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -6, to: today)!, value: 124500.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -5, to: today)!, value: 125200.50),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -4, to: today)!, value: 124800.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 126100.75),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -2, to: today)!, value: 125900.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 126800.25),
            BalanceDataPoint(date: today, value: 127450.32)
        ]
    }
}

// MARK: - Balance Change

/// Represents the change in balance over a time period
struct BalanceChange {
    let amount: Decimal
    let percentage: Decimal
    let period: TimePeriod
    
    var isPositive: Bool {
        amount >= 0
    }
    
    var isNegative: Bool {
        amount < 0
    }
    
    /// Formatted amount string with sign
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    /// Formatted percentage string
    var formattedPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.multiplier = 0.01
        
        return formatter.string(from: NSDecimalNumber(decimal: percentage)) ?? "0.0%"
    }
    
    /// Color for the change indicator
    var color: Color {
        if amount > 0 {
            return Color(red: 0.2, green: 0.7, blue: 0.4) // Soft green
        } else if amount < 0 {
            return Color(red: 0.95, green: 0.5, blue: 0.45) // Soft coral (non-alarmist)
        }
        return .secondary
    }
    
    enum TimePeriod: String {
        case day = "24h"
        case week = "7d"
        case month = "30d"
        case year = "1y"
    }
}

// MARK: - Asset Allocation

/// Breakdown of assets by category
struct AssetAllocation {
    let cash: Decimal      // Bank accounts, savings
    let stocks: Decimal    // Brokerage, investments
    let crypto: Decimal    // Cryptocurrency holdings
    let other: Decimal     // Other assets
    
    var total: Decimal {
        cash + stocks + crypto + other
    }
    
    /// Percentage of cash in portfolio
    var cashPercentage: Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: cash / total).doubleValue
    }
    
    /// Percentage of stocks in portfolio
    var stocksPercentage: Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: stocks / total).doubleValue
    }
    
    /// Percentage of crypto in portfolio
    var cryptoPercentage: Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: crypto / total).doubleValue
    }
    
    /// Percentage of other assets in portfolio
    var otherPercentage: Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: other / total).doubleValue
    }
    
    /// Only categories with non-zero allocation
    var activeCategories: [(category: AssetCategory, percentage: Double, amount: Decimal)] {
        var result: [(AssetCategory, Double, Decimal)] = []
        
        if cash > 0 { result.append((.cash, cashPercentage, cash)) }
        if stocks > 0 { result.append((.stocks, stocksPercentage, stocks)) }
        if crypto > 0 { result.append((.crypto, cryptoPercentage, crypto)) }
        if other > 0 { result.append((.other, otherPercentage, other)) }
        
        return result
    }
    
    static let sample = AssetAllocation(
        cash: 51200.00,
        stocks: 64000.00,
        crypto: 12250.32,
        other: 0
    )
}

/// Categories of assets for allocation display
enum AssetCategory: String, CaseIterable {
    case cash = "Cash"
    case stocks = "Stocks"
    case crypto = "Crypto"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .cash:
            return Color(red: 0.3, green: 0.6, blue: 0.9)    // Blue
        case .stocks:
            return Color(red: 0.4, green: 0.75, blue: 0.5)   // Green
        case .crypto:
            return Color(red: 0.95, green: 0.65, blue: 0.3)  // Orange
        case .other:
            return Color(red: 0.6, green: 0.5, blue: 0.8)    // Purple
        }
    }
    
    var iconName: String {
        switch self {
        case .cash:
            return "banknote.fill"
        case .stocks:
            return "chart.line.uptrend.xyaxis"
        case .crypto:
            return "bitcoinsign.circle.fill"
        case .other:
            return "square.stack.3d.up.fill"
        }
    }
}

// MARK: - Portfolio Account

/// Represents a linked financial account in the portfolio
struct PortfolioAccount: Identifiable {
    let id: UUID
    let institutionName: String
    let accountName: String
    let accountType: PortfolioAccountType
    let balance: Decimal
    let lastFourDigits: String
    let lastSyncDate: Date
    let isActive: Bool
    let hasError: Bool
    
    /// Whether this account has a negative balance (overdraft/debt)
    var isNegative: Bool {
        balance < 0
    }
    
    /// Formatted balance string
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "$0.00"
    }
    
    static let sampleAccounts: [PortfolioAccount] = [
        PortfolioAccount(
            id: UUID(),
            institutionName: "Chase",
            accountName: "Primary Checking",
            accountType: .checking,
            balance: 12450.32,
            lastFourDigits: "4521",
            lastSyncDate: Date().addingTimeInterval(-1800),
            isActive: true,
            hasError: false
        ),
        PortfolioAccount(
            id: UUID(),
            institutionName: "Chase",
            accountName: "Savings",
            accountType: .savings,
            balance: 38749.68,
            lastFourDigits: "7832",
            lastSyncDate: Date().addingTimeInterval(-1800),
            isActive: true,
            hasError: false
        ),
        PortfolioAccount(
            id: UUID(),
            institutionName: "Fidelity",
            accountName: "Investment Portfolio",
            accountType: .investment,
            balance: 64000.00,
            lastFourDigits: "9104",
            lastSyncDate: Date().addingTimeInterval(-7200),
            isActive: true,
            hasError: false
        ),
        PortfolioAccount(
            id: UUID(),
            institutionName: "Coinbase",
            accountName: "Crypto Wallet",
            accountType: .crypto,
            balance: 12250.32,
            lastFourDigits: "••••",
            lastSyncDate: Date().addingTimeInterval(-3600),
            isActive: true,
            hasError: false
        )
    ]
}

/// Types of accounts in the portfolio
enum PortfolioAccountType: String {
    case checking = "Checking"
    case savings = "Savings"
    case investment = "Investment"
    case crypto = "Crypto"
    case creditCard = "Credit Card"
    case loan = "Loan"
    
    var assetCategory: AssetCategory {
        switch self {
        case .checking, .savings:
            return .cash
        case .investment:
            return .stocks
        case .crypto:
            return .crypto
        case .creditCard, .loan:
            return .other
        }
    }
    
    var iconName: String {
        switch self {
        case .checking:
            return "creditcard.fill"
        case .savings:
            return "banknote.fill"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        case .crypto:
            return "bitcoinsign.circle.fill"
        case .creditCard:
            return "creditcard.fill"
        case .loan:
            return "building.columns.fill"
        }
    }
}

// MARK: - Transaction

/// Represents a recent financial transaction
struct Transaction: Identifiable {
    let id: UUID
    let title: String
    let category: TransactionCategory
    let amount: Decimal
    let date: Date
    let accountName: String
    let isPending: Bool
    
    var isDebit: Bool {
        amount < 0
    }
    
    /// Formatted amount string
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        
        if amount > 0 {
            formatter.positivePrefix = "+"
        }
        
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    /// Color for transaction amount
    var amountColor: Color {
        if amount > 0 {
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        } else {
            return .primary
        }
    }
    
    static let sampleTransactions: [Transaction] = [
        Transaction(
            id: UUID(),
            title: "Apple Inc.",
            category: .investment,
            amount: 1240.50,
            date: Date(),
            accountName: "Fidelity",
            isPending: false
        ),
        Transaction(
            id: UUID(),
            title: "Whole Foods Market",
            category: .groceries,
            amount: -87.32,
            date: Date().addingTimeInterval(-86400),
            accountName: "Chase Checking",
            isPending: false
        ),
        Transaction(
            id: UUID(),
            title: "Monthly Salary",
            category: .income,
            amount: 5200.00,
            date: Date().addingTimeInterval(-172800),
            accountName: "Chase Checking",
            isPending: false
        )
    ]
}

/// Categories for transactions
enum TransactionCategory: String {
    case income = "Income"
    case groceries = "Groceries"
    case dining = "Dining"
    case shopping = "Shopping"
    case transport = "Transport"
    case utilities = "Utilities"
    case investment = "Investment"
    case transfer = "Transfer"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .income:
            return "arrow.down.circle.fill"
        case .groceries:
            return "cart.fill"
        case .dining:
            return "fork.knife"
        case .shopping:
            return "bag.fill"
        case .transport:
            return "car.fill"
        case .utilities:
            return "bolt.fill"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        case .transfer:
            return "arrow.left.arrow.right"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .income:
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .groceries:
            return Color(red: 0.4, green: 0.75, blue: 0.5)
        case .dining:
            return Color(red: 0.95, green: 0.65, blue: 0.3)
        case .shopping:
            return Color(red: 0.9, green: 0.5, blue: 0.6)
        case .transport:
            return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .utilities:
            return Color(red: 0.95, green: 0.8, blue: 0.3)
        case .investment:
            return Color(red: 0.6, green: 0.5, blue: 0.8)
        case .transfer:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .other:
            return .secondary
        }
    }
}

// MARK: - Quick Action

/// Actions available on the Pulse dashboard
enum QuickAction: String, CaseIterable, Identifiable {
    case addBank = "Add Bank"
    case transfer = "Transfer"
    case analysis = "Analysis"
    case budget = "Budget"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .addBank:
            return "plus.circle.fill"
        case .transfer:
            return "arrow.left.arrow.right.circle.fill"
        case .analysis:
            return "chart.pie.fill"
        case .budget:
            return "chart.bar.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .addBank:
            return .blue
        case .transfer:
            return .green
        case .analysis:
            return .purple
        case .budget:
            return .orange
        }
    }
}

// MARK: - Display Mode

/// Toggle between different balance display modes
enum BalanceDisplayMode: String, CaseIterable {
    case totalNetWorth = "Total Net Worth"
    case investedCapital = "Invested Capital"
    
    var next: BalanceDisplayMode {
        switch self {
        case .totalNetWorth:
            return .investedCapital
        case .investedCapital:
            return .totalNetWorth
        }
    }
}
