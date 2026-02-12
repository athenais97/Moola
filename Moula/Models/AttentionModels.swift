import Foundation
import SwiftUI

// MARK: - Attention Item

/// Represents an insight or alert requiring user attention
/// UX Intent: Glanceable, actionable items that surface problems or opportunities
/// Privacy-aware: Masks sensitive data when app is in Privacy Mode
struct AttentionItem: Identifiable, Equatable {
    let id: String
    let category: AttentionCategory
    let priority: AttentionPriority
    let title: String
    let description: String
    let impactDescription: String
    let institutionName: String?
    let institutionColor: Color?
    let accountMaskedNumber: String?
    let createdAt: Date
    let action: AttentionAction
    let isDismissible: Bool
    
    /// Privacy-safe title (masks account numbers when needed)
    func displayTitle(privacyMode: Bool) -> String {
        if privacyMode, let masked = accountMaskedNumber {
            return title.replacingOccurrences(of: masked, with: "••••")
        }
        return title
    }
    
    /// Privacy-safe description
    func displayDescription(privacyMode: Bool) -> String {
        if privacyMode {
            // Mask any currency amounts in description
            let pattern = #"\$[\d,]+(\.\d{2})?"#
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(description.startIndex..., in: description)
                return regex.stringByReplacingMatches(
                    in: description,
                    range: range,
                    withTemplate: "$•••••"
                )
            }
        }
        return description
    }
    
    /// Time since creation for relative display
    var timeSinceCreated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    static func == (lhs: AttentionItem, rhs: AttentionItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Attention Category

/// Categories of attention items ordered by severity
/// UX: Clear visual hierarchy - errors are unmissable, advisories are subtle
enum AttentionCategory: String, CaseIterable, Comparable {
    case syncFailure = "Sync Failure"
    case balanceAlert = "Balance Alert"
    case dataEnrichment = "Data Enrichment"
    
    /// Sort order for priority-based ranking
    var sortOrder: Int {
        switch self {
        case .syncFailure: return 0      // Highest priority
        case .balanceAlert: return 1
        case .dataEnrichment: return 2   // Lowest priority
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .syncFailure:
            return "link.badge.plus"
        case .balanceAlert:
            return "exclamationmark.triangle.fill"
        case .dataEnrichment:
            return "tag.fill"
        }
    }
    
    /// Whether this category represents a critical error
    var isCritical: Bool {
        switch self {
        case .syncFailure:
            return true
        case .balanceAlert, .dataEnrichment:
            return false
        }
    }
    
    /// Display color - Amber for warnings, Soft Red for errors
    /// UX: Visual urgency without panic
    var color: Color {
        switch self {
        case .syncFailure:
            return Color(red: 0.92, green: 0.45, blue: 0.42)  // Soft Red
        case .balanceAlert:
            return Color(red: 0.95, green: 0.75, blue: 0.25)  // Amber/Gold
        case .dataEnrichment:
            return Color(red: 0.6, green: 0.55, blue: 0.85)   // Soft Purple
        }
    }
    
    /// Background color for cards (subtle tint)
    var backgroundColor: Color {
        color.opacity(0.08)
    }
    
    static func < (lhs: AttentionCategory, rhs: AttentionCategory) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Attention Priority

/// Priority levels for attention items
enum AttentionPriority: Int, Comparable {
    case critical = 0    // Must resolve to continue (e.g., expired auth)
    case high = 1        // Should resolve soon (e.g., low balance)
    case medium = 2      // Can wait (e.g., uncategorized transaction)
    
    /// Whether this priority triggers haptic feedback when scrolled to
    var triggersHaptic: Bool {
        self == .critical
    }
    
    /// Animation style for the status icon
    var iconAnimation: IconAnimation {
        switch self {
        case .critical:
            return .pulse
        case .high:
            return .subtle
        case .medium:
            return .none
        }
    }
    
    static func < (lhs: AttentionPriority, rhs: AttentionPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    enum IconAnimation {
        case pulse      // Subtle pulsing to draw attention
        case subtle     // Very subtle glow
        case none       // No animation
    }
}

// MARK: - Attention Action

/// Action to resolve an attention item
/// UX: Every item must have a clear, one-tap solution
struct AttentionAction {
    let label: String
    let systemImage: String
    let actionType: ActionType
    
    enum ActionType: Equatable {
        case reconnectBank(institutionId: String)
        case viewAccount(accountId: String)
        case viewTransaction(transactionId: String)
        case categorizeTransaction(transactionId: String)
        case openSettings
        case custom(identifier: String)
    }
    
    /// Primary action button label
    static func reconnect(institutionId: String) -> AttentionAction {
        AttentionAction(
            label: "Reconnect",
            systemImage: "arrow.triangle.2.circlepath",
            actionType: .reconnectBank(institutionId: institutionId)
        )
    }
    
    static func viewAccount(accountId: String) -> AttentionAction {
        AttentionAction(
            label: "View Account",
            systemImage: "arrow.right.circle.fill",
            actionType: .viewAccount(accountId: accountId)
        )
    }
    
    static func viewTransaction(transactionId: String) -> AttentionAction {
        AttentionAction(
            label: "View",
            systemImage: "doc.text.magnifyingglass",
            actionType: .viewTransaction(transactionId: transactionId)
        )
    }
    
    static func categorize(transactionId: String) -> AttentionAction {
        AttentionAction(
            label: "Categorize",
            systemImage: "tag.fill",
            actionType: .categorizeTransaction(transactionId: transactionId)
        )
    }
}

// MARK: - Muted Insight Type

/// Types of insights that can be muted by user preference
/// UX: "Silent Mode" for repetitive advisory insights
enum MutedInsightType: String, CaseIterable, Codable {
    case lowBalanceAlerts = "Low Balance Alerts"
    case uncategorizedTransactions = "Uncategorized Transactions"
    case spendingSpikes = "Spending Spikes"
    
    var category: AttentionCategory {
        switch self {
        case .lowBalanceAlerts, .spendingSpikes:
            return .balanceAlert
        case .uncategorizedTransactions:
            return .dataEnrichment
        }
    }
}

// MARK: - Attention State

/// Current state of the attention center
/// UX: Tracks dismissed items, muted types, and resolution animations
struct AttentionState: Equatable {
    var items: [AttentionItem]
    var dismissedItemIds: Set<String>
    var mutedTypes: Set<MutedInsightType>
    var recentlyResolvedIds: Set<String>  // For collapse animation
    
    /// Active (visible) items after filtering dismissed and muted
    var activeItems: [AttentionItem] {
        items
            .filter { !dismissedItemIds.contains($0.id) }
            .filter { item in
                // Don't filter critical items regardless of mute settings
                if item.category.isCritical { return true }
                
                // Check if this item's type is muted
                let mutedCategories = mutedTypes.map { $0.category }
                return !mutedCategories.contains(item.category)
            }
            .sorted { (lhs, rhs) in
                // Primary sort: priority
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority
                }
                // Secondary sort: category
                if lhs.category != rhs.category {
                    return lhs.category < rhs.category
                }
                // Tertiary sort: creation date (newest first)
                return lhs.createdAt > rhs.createdAt
            }
    }
    
    /// Count of critical items (errors that must be resolved)
    var criticalCount: Int {
        activeItems.filter { $0.category.isCritical }.count
    }
    
    /// Count of advisory items
    var advisoryCount: Int {
        activeItems.filter { !$0.category.isCritical }.count
    }
    
    /// Total active count
    var totalCount: Int {
        activeItems.count
    }
    
    /// Whether all items have been addressed
    var isAllClear: Bool {
        activeItems.isEmpty
    }
    
    /// Header message for attention count
    var headerMessage: String {
        switch totalCount {
        case 0:
            return "You're all set"
        case 1:
            return "1 item needs your attention"
        default:
            return "\(totalCount) items need your attention"
        }
    }
    
    static let empty = AttentionState(
        items: [],
        dismissedItemIds: [],
        mutedTypes: [],
        recentlyResolvedIds: []
    )
}

// MARK: - Sample Data

extension AttentionItem {
    
    /// Sample attention items for development and previews
    static let sampleItems: [AttentionItem] = [
        // Critical: Sync Failure
        AttentionItem(
            id: "sync_revolut_001",
            category: .syncFailure,
            priority: .critical,
            title: "Connection Expired – Revolut",
            description: "Your Revolut account connection has expired and needs to be renewed.",
            impactDescription: "Your data hasn't updated in 3 days.",
            institutionName: "Revolut",
            institutionColor: Color(red: 0.0, green: 0.47, blue: 0.87),
            accountMaskedNumber: "••••4521",
            createdAt: Date().addingTimeInterval(-259200), // 3 days ago
            action: .reconnect(institutionId: "revolut_001"),
            isDismissible: false
        ),
        
        // High: Low Balance Alert
        AttentionItem(
            id: "balance_chase_001",
            category: .balanceAlert,
            priority: .high,
            title: "Low Balance – Chase Checking",
            description: "Your balance dropped below $500. Consider transferring funds.",
            impactDescription: "Balance: $342.50",
            institutionName: "Chase",
            institutionColor: Color(red: 0.07, green: 0.48, blue: 0.79),
            accountMaskedNumber: "••••7832",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            action: .viewAccount(accountId: "chase_checking_001"),
            isDismissible: true
        ),
        
        // Medium: Uncategorized Transaction
        AttentionItem(
            id: "categorize_tx_001",
            category: .dataEnrichment,
            priority: .medium,
            title: "Large Uncategorized Transaction",
            description: "A $2,450.00 transaction from 'WIRE TRANSFER' needs categorization.",
            impactDescription: "Affects your spending analysis accuracy.",
            institutionName: "Chase",
            institutionColor: Color(red: 0.07, green: 0.48, blue: 0.79),
            accountMaskedNumber: "••••7832",
            createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
            action: .categorize(transactionId: "tx_wire_001"),
            isDismissible: true
        ),
        
        // High: Unusual Spending
        AttentionItem(
            id: "spending_spike_001",
            category: .balanceAlert,
            priority: .high,
            title: "Unusual Spending Detected",
            description: "Your dining expenses this week are 180% higher than average.",
            impactDescription: "$847 spent vs. $302 typical",
            institutionName: nil,
            institutionColor: nil,
            accountMaskedNumber: nil,
            createdAt: Date().addingTimeInterval(-1800), // 30 min ago
            action: AttentionAction(
                label: "Review",
                systemImage: "chart.bar.fill",
                actionType: .custom(identifier: "spending_analysis")
            ),
            isDismissible: true
        )
    ]
    
    /// Sample with only critical items
    static let sampleCriticalOnly: [AttentionItem] = [
        sampleItems[0]
    ]
    
    /// Sample with all items dismissed (clear state)
    static let sampleEmpty: [AttentionItem] = []
}
