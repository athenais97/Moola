import SwiftUI

/// Recent transactions preview for the Pulse dashboard
/// UX Intent: Provide immediate context without leaving the summary screen
/// Shows last 3 transactions with option to see all
struct RecentActivityView: View {
    let transactions: [Transaction]
    let isPrivacyMode: Bool
    let onSeeAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    onSeeAll()
                }) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 14, weight: .medium))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 20)
            
            // Transactions list
            if transactions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transactions.prefix(3).enumerated()), id: \.element.id) { index, transaction in
                        TransactionRow(
                            transaction: transaction,
                            isPrivacyMode: isPrivacyMode
                        )
                        
                        if index < min(transactions.count, 3) - 1 {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No recent activity")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
}

// MARK: - Transaction Row

/// Individual transaction row
struct TransactionRow: View {
    let transaction: Transaction
    let isPrivacyMode: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(transaction.category.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.category.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(transaction.category.color)
            }
            
            // Title and details
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(transaction.formattedDate)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    if transaction.isPending {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Pending")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            Text(isPrivacyMode ? "••••" : transaction.formattedAmount)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isPrivacyMode ? .secondary : transaction.amountColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Recent Activity") {
    VStack {
        RecentActivityView(
            transactions: Transaction.sampleTransactions,
            isPrivacyMode: false,
            onSeeAll: {}
        )
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}

#Preview("Recent Activity - Privacy Mode") {
    VStack {
        RecentActivityView(
            transactions: Transaction.sampleTransactions,
            isPrivacyMode: true,
            onSeeAll: {}
        )
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}

#Preview("Recent Activity - Empty") {
    VStack {
        RecentActivityView(
            transactions: [],
            isPrivacyMode: false,
            onSeeAll: {}
        )
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Transaction Row") {
    VStack(spacing: 0) {
        TransactionRow(
            transaction: Transaction.sampleTransactions[0],
            isPrivacyMode: false
        )
        Divider().padding(.leading, 68)
        TransactionRow(
            transaction: Transaction.sampleTransactions[1],
            isPrivacyMode: false
        )
        Divider().padding(.leading, 68)
        TransactionRow(
            transaction: Transaction.sampleTransactions[2],
            isPrivacyMode: false
        )
    }
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .padding()
    .background(Color(.systemGroupedBackground))
}
