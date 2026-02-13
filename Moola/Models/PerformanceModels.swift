import Foundation
import SwiftUI

// MARK: - Performance Timeframe

/// Timeframe options for performance chart
/// UX: Matches the D/W/M/Y/ALL pattern from requirements
enum PerformanceTimeframe: String, CaseIterable, Identifiable {
    case day = "D"
    case week = "W"
    case month = "M"
    case year = "Y"
    case all = "ALL"
    
    var id: String { rawValue }
    
    /// Full label for accessibility
    var accessibilityLabel: String {
        switch self {
        case .day: return "1 Day"
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .year: return "1 Year"
        case .all: return "All Time"
        }
    }
    
    /// Human-readable label for use in insight sentences
    /// UX: Natural language phrasing that flows well in explanatory text
    var readableLabel: String {
        switch self {
        case .day: return "today"
        case .week: return "this week"
        case .month: return "this month"
        case .year: return "this year"
        case .all: return "overall"
        }
    }
    
    /// Number of data points appropriate for each timeframe
    var idealDataPointCount: Int {
        switch self {
        case .day: return 24      // Hourly for 1 day
        case .week: return 7      // Daily for 1 week
        case .month: return 30    // Daily for 1 month
        case .year: return 52     // Weekly for 1 year
        case .all: return 60      // Monthly for multi-year
        }
    }
    
    /// Date formatter pattern for tooltip display
    var dateFormat: String {
        switch self {
        case .day: return "h:mm a"           // 2:30 PM
        case .week: return "EEE, MMM d"       // Mon, Jan 15
        case .month: return "MMM d"           // Jan 15
        case .year: return "MMM yyyy"         // Jan 2026
        case .all: return "MMM yyyy"          // Jan 2026
        }
    }
}

// MARK: - Performance Data Point

/// A single point in the performance time series
/// Supports flagging data gaps (e.g., disconnected bank) for interpolation styling
struct PerformanceDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Decimal
    let isInterpolated: Bool  // True if this point was estimated (data gap)
    
    init(date: Date, value: Decimal, isInterpolated: Bool = false) {
        self.date = date
        self.value = value
        self.isInterpolated = isInterpolated
    }
    
    /// Double value for chart calculations
    var doubleValue: Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
    
    /// Formatted date based on timeframe
    func formattedDate(for timeframe: PerformanceTimeframe) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = timeframe.dateFormat
        return formatter.string(from: date)
    }
    
    static func == (lhs: PerformanceDataPoint, rhs: PerformanceDataPoint) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Performance Summary

/// Summary of performance for a given timeframe
/// UX: Shows the "Delta" as absolute + percentage
struct PerformanceSummary {
    let timeframe: PerformanceTimeframe
    let startValue: Decimal
    let endValue: Decimal
    let dataPoints: [PerformanceDataPoint]
    let keyMovers: [AccountPerformance]
    
    /// Absolute change in value
    var absoluteChange: Decimal {
        endValue - startValue
    }
    
    /// Percentage change
    var percentageChange: Decimal {
        guard startValue != 0 else { return 0 }
        return (absoluteChange / startValue) * 100
    }
    
    /// Whether performance is positive
    var isPositive: Bool {
        absoluteChange >= 0
    }
    
    /// Formatted absolute change with sign
    var formattedAbsoluteChange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        return formatter.string(from: NSDecimalNumber(decimal: absoluteChange)) ?? "$0.00"
    }
    
    /// Formatted percentage change with sign
    var formattedPercentageChange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "+"
        formatter.negativePrefix = ""
        let percentString = formatter.string(from: NSDecimalNumber(decimal: percentageChange)) ?? "0.0"
        return "\(percentString)%"
    }
    
    /// Color based on performance direction
    var trendColor: Color {
        if absoluteChange > 0 {
            return Color(red: 0.2, green: 0.7, blue: 0.4)  // Growth Green
        } else if absoluteChange < 0 {
            return Color(red: 0.95, green: 0.5, blue: 0.45) // Soft Coral
        }
        return .secondary
    }
    
    // MARK: - Contextual Insight Generation
    // UX Intent: Help users understand "what changed" and "why" through plain language
    // These computed properties provide interpretability without adding complex analytics
    
    /// Contextual label describing the magnitude of change (e.g., "Solid growth", "Minor dip")
    /// Helps users quickly assess whether performance is noteworthy or routine
    var contextLabel: String {
        let percent = abs(NSDecimalNumber(decimal: percentageChange).doubleValue)
        
        if absoluteChange > 0 {
            if percent >= 5 { return "Strong growth" }
            if percent >= 2 { return "Solid growth" }
            if percent >= 0.5 { return "Steady gains" }
            return "Slight uptick"
        } else if absoluteChange < 0 {
            if percent >= 5 { return "Significant decline" }
            if percent >= 2 { return "Notable dip" }
            if percent >= 0.5 { return "Minor pullback" }
            return "Slight dip"
        }
        return "No change"
    }
    
    /// Human-readable summary explaining what happened during this timeframe
    /// Answers the question: "What changed?"
    var insightSummary: String {
        let percentValue = abs(NSDecimalNumber(decimal: percentageChange).doubleValue)
        let timeframeLabel = timeframe.readableLabel
        
        if absoluteChange == 0 {
            return "Your portfolio value stayed flat \(timeframeLabel)."
        }
        
        let direction = absoluteChange > 0 ? "grew" : "declined"
        let magnitude: String
        
        if percentValue >= 5 {
            magnitude = "significantly"
        } else if percentValue >= 2 {
            magnitude = "noticeably"
        } else if percentValue >= 0.5 {
            magnitude = "modestly"
        } else {
            magnitude = "slightly"
        }
        
        return "Your portfolio \(direction) \(magnitude) \(timeframeLabel)."
    }
    
    /// Explanation of the primary driver behind the change
    /// Answers the question: "Why did it change?"
    var driverExplanation: String? {
        guard let topMover = keyMovers.first else { return nil }
        
        let percentOfTotal = NSDecimalNumber(decimal: topMover.percentageOfTotal).intValue
        let accountName = topMover.accountName
        
        // Only highlight if this account was a significant contributor (>40%)
        guard percentOfTotal >= 40 else {
            if keyMovers.count > 1 {
                return "Changes were spread across multiple accounts."
            }
            return nil
        }
        
        let verb = topMover.isPositive ? "drove most of the gains" : "accounted for most of the decline"
        return "Your \(accountName) \(verb)."
    }
    
    /// Formatted current balance
    var formattedCurrentBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: endValue)) ?? "$0.00"
    }
    
    // MARK: - Sample Data
    
    static func sample(for timeframe: PerformanceTimeframe, accountId: UUID? = nil) -> PerformanceSummary {
        let dataPoints = generateSampleData(for: timeframe, accountId: accountId)
        let startValue = dataPoints.first?.value ?? 0
        let endValue = dataPoints.last?.value ?? 0
        
        return PerformanceSummary(
            timeframe: timeframe,
            startValue: startValue,
            endValue: endValue,
            dataPoints: dataPoints,
            keyMovers: accountId == nil ? AccountPerformance.sampleMovers : []
        )
    }
    
    /// Generates realistic sample data for demo purposes
    private static func generateSampleData(for timeframe: PerformanceTimeframe, accountId: UUID?) -> [PerformanceDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var points: [PerformanceDataPoint] = []
        var rng = SeededRandomNumberGenerator(seed: seedValue(for: timeframe, accountId: accountId))
        
        let baseValue: Double = {
            if accountId != nil {
                // Account-scoped views should feel like a single account, not the full portfolio.
                // Generate a stable base between ~8k and ~70k.
                return 8_000.0 + rng.nextDouble(in: 0...62_000.0)
            }
            return 127_450.32
        }()
        
        var currentValue = baseValue
        
        // Determine date components based on timeframe
        let (component, count): (Calendar.Component, Int) = {
            switch timeframe {
            case .day: return (.hour, 24)
            case .week: return (.day, 7)
            case .month: return (.day, 30)
            case .year: return (.weekOfYear, 52)
            case .all: return (.month, 36)
            }
        }()
        
        // Generate points working backwards from now
        for i in (0..<count).reversed() {
            let date = calendar.date(byAdding: component, value: -i, to: now) ?? now
            
            // Add some realistic variation
            let volatility: Double = {
                switch timeframe {
                case .day: return 0.002    // 0.2% hourly
                case .week: return 0.008   // 0.8% daily
                case .month: return 0.01   // 1% daily
                case .year: return 0.02    // 2% weekly
                case .all: return 0.03     // 3% monthly
                }
            }()
            
            let change = currentValue * volatility * rng.nextDouble(in: -1.0...1.1)
            currentValue += change
            
            // Simulate a data gap (bank disconnected) for demonstration
            let isInterpolated = timeframe == .month && (i == 12 || i == 13 || i == 14)
            
            points.append(PerformanceDataPoint(
                date: date,
                value: Decimal(currentValue),
                isInterpolated: isInterpolated
            ))
        }
        
        return points
    }
    
    private static func seedValue(for timeframe: PerformanceTimeframe, accountId: UUID?) -> UInt64 {
        // FNV-1a 64-bit
        var hash: UInt64 = 1469598103934665603
        func mix(_ bytes: [UInt8]) {
            for b in bytes {
                hash ^= UInt64(b)
                hash = hash &* 1099511628211
            }
        }
        
        mix(Array(timeframe.rawValue.utf8))
        if let accountId {
            mix(Array(accountId.uuidString.utf8))
        } else {
            mix(Array("portfolio".utf8))
        }
        
        return hash
    }
    
    /// Sample for single data point scenario (new account)
    static var singlePoint: PerformanceSummary {
        let now = Date()
        let value: Decimal = 10000.00
        
        return PerformanceSummary(
            timeframe: .day,
            startValue: value,
            endValue: value,
            dataPoints: [
                PerformanceDataPoint(date: now, value: value)
            ],
            keyMovers: []
        )
    }
    
    /// Empty state
    static var empty: PerformanceSummary {
        PerformanceSummary(
            timeframe: .week,
            startValue: 0,
            endValue: 0,
            dataPoints: [],
            keyMovers: []
        )
    }
}

// MARK: - Deterministic RNG (stable mock data)

private struct SeededRandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }
    
    mutating func nextUInt64() -> UInt64 {
        // LCG constants from Numerical Recipes
        state = state &* 6364136223846793005 &+ 1
        return state
    }
    
    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        let unit = Double(nextUInt64()) / Double(UInt64.max)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Account Performance

/// Performance contribution from a specific account
/// UX: Powers the "Key Movers" insight cards
struct AccountPerformance: Identifiable {
    let id = UUID()
    let accountName: String
    let institutionName: String
    let accountType: PortfolioAccountType
    let contribution: Decimal      // Absolute contribution to total
    let percentageOfTotal: Decimal // How much of the total change this account represents
    let isPositive: Bool
    
    /// Formatted contribution with sign
    var formattedContribution: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        return formatter.string(from: NSDecimalNumber(decimal: contribution)) ?? "$0.00"
    }
    
    /// Formatted percentage of total
    var formattedPercentageOfTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.multiplier = 1
        let value = NSDecimalNumber(decimal: percentageOfTotal / 100).doubleValue
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
    
    /// Color based on contribution direction
    var color: Color {
        if isPositive {
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        } else {
            return Color(red: 0.95, green: 0.5, blue: 0.45)
        }
    }
    
    // MARK: - Sample Data
    
    static var sampleMovers: [AccountPerformance] {
        [
            AccountPerformance(
                accountName: "Investment Portfolio",
                institutionName: "Fidelity",
                accountType: .investment,
                contribution: 1850.00,
                percentageOfTotal: 65,
                isPositive: true
            ),
            AccountPerformance(
                accountName: "Crypto Wallet",
                institutionName: "Coinbase",
                accountType: .crypto,
                contribution: 620.50,
                percentageOfTotal: 22,
                isPositive: true
            ),
            AccountPerformance(
                accountName: "Primary Checking",
                institutionName: "Chase",
                accountType: .checking,
                contribution: 380.00,
                percentageOfTotal: 13,
                isPositive: true
            )
        ]
    }
}

// MARK: - Scrub State

/// State for chart scrubbing/tooltip interaction
struct ChartScrubState: Equatable {
    let dataPoint: PerformanceDataPoint
    let normalizedX: CGFloat  // 0...1 position on chart
    let normalizedY: CGFloat  // 0...1 position on chart
    
    /// Formatted value for tooltip
    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: dataPoint.value)) ?? "$0.00"
    }
}

// MARK: - Chart Bounds

/// Calculated bounds for chart rendering
/// Handles extreme volatility padding per requirements
struct ChartBounds {
    let minValue: Double
    let maxValue: Double
    let paddingPercentage: Double = 0.1  // 10% padding to avoid edge collisions
    
    init(dataPoints: [PerformanceDataPoint]) {
        let values = dataPoints.map { $0.doubleValue }
        let rawMin = values.min() ?? 0
        let rawMax = values.max() ?? 0
        
        // Add padding to handle volatility
        let range = rawMax - rawMin
        let padding = range * paddingPercentage
        
        // Ensure minimum visible range for flat data
        let minRange = rawMax * 0.02  // At least 2% of max value as range
        let effectiveRange = max(range, minRange)
        let effectivePadding = effectiveRange * paddingPercentage
        
        self.minValue = rawMin - effectivePadding
        self.maxValue = rawMax + effectivePadding
    }
    
    /// Normalizes a value to 0...1 within bounds (inverted for screen Y)
    func normalizedY(for value: Double) -> CGFloat {
        let range = maxValue - minValue
        guard range > 0 else { return 0.5 }
        return CGFloat(1 - (value - minValue) / range)
    }
    
    /// Denormalizes screen Y (0...1) back to value
    func value(for normalizedY: CGFloat) -> Double {
        let range = maxValue - minValue
        return maxValue - (Double(normalizedY) * range)
    }
}
