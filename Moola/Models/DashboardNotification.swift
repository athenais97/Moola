import Foundation
import SwiftUI

/// A single dashboard notification shown in the stacked notifications area.
/// Types: disconnected account, account requires attention.
struct DashboardNotification: Identifiable, Equatable {
    let id: String
    let kind: Kind
    let title: String
    let subtitle: String

    enum Kind: Equatable {
        /// Account has been disconnected / data is stale.
        case disconnectedAccount
        /// Account needs user action (e.g. re-auth, consent, issue).
        case accountRequiresAttention
    }

    /// SF Symbol name for the notification card (matches Figma: paperclip for disconnect).
    var systemIconName: String {
        switch kind {
        case .disconnectedAccount: return "link"
        case .accountRequiresAttention: return "exclamationmark.triangle.fill"
        }
    }
}
