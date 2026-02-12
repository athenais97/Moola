import SwiftUI

// MARK: - Bank Search Bar

/// Search bar for finding banks
struct BankSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Search banks...", text: $text)
                .font(.system(size: 16))
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Security Badge

/// Badge showing security status
struct SecurityBadge: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Popular Bank Card

/// Card for displaying a popular bank in a horizontal scroll
struct PopularBankCard: View {
    let bank: Bank
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: bank.primaryColor)?.opacity(0.1) ?? Color.blue.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: bank.logoName)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: bank.primaryColor) ?? .blue)
                }
                
                Text(bank.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(width: 90)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Bank List Row

/// Row for displaying a bank in a list
struct BankListRow: View {
    let bank: Bank
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: bank.primaryColor)?.opacity(0.1) ?? Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: bank.logoName)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: bank.primaryColor) ?? .blue)
                }
                
                Text(bank.name)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bank Account Row

/// Row for displaying a bank account with selection state
struct BankAccountRow: View {
    let account: BankAccount
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 16, height: 16)
                    }
                }
                
                // Account icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: account.accountType.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                }
                
                // Account details
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("\(account.accountType.displayName) \(account.maskedNumber)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Balance (if available)
                if let balance = account.availableBalance {
                    Text(formatCurrency(balance))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = account.currencyCode
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Account Skeleton Row

/// Skeleton loading row for accounts
struct AccountSkeletonRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 24, height: 24)
            
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 70, height: 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Bank Linking Empty State

/// Empty state view for various bank linking scenarios
struct BankLinkingEmptyState: View {
    enum EmptyStateType {
        case noSearchResults
        case noAccountsFound
        case connectionError
    }
    
    let type: EmptyStateType
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
    }
    
    private var iconName: String {
        switch type {
        case .noSearchResults: return "magnifyingglass"
        case .noAccountsFound: return "folder.badge.questionmark"
        case .connectionError: return "wifi.exclamationmark"
        }
    }
    
    private var title: String {
        switch type {
        case .noSearchResults: return "No Banks Found"
        case .noAccountsFound: return "No Accounts Found"
        case .connectionError: return "Connection Failed"
        }
    }
    
    private var message: String {
        switch type {
        case .noSearchResults: return "Try a different search term or browse all banks below."
        case .noAccountsFound: return "We couldn't find any eligible accounts with this bank."
        case .connectionError: return "Please check your connection and try again."
        }
    }
}

// MARK: - Previews

#Preview("Bank Search Bar") {
    VStack {
        BankSearchBar(text: .constant(""))
        BankSearchBar(text: .constant("Chase"))
    }
    .padding()
}

#Preview("Popular Bank Card") {
    HStack {
        PopularBankCard(bank: Bank.sampleBanks[0]) {}
        PopularBankCard(bank: Bank.sampleBanks[1]) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Bank List Row") {
    VStack(spacing: 0) {
        BankListRow(bank: Bank.sampleBanks[0]) {}
        Divider().padding(.leading, 74)
        BankListRow(bank: Bank.sampleBanks[1]) {}
    }
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .padding()
}

#Preview("Bank Account Row") {
    VStack(spacing: 0) {
        BankAccountRow(
            account: BankAccount(name: "Checking", accountType: .checking, maskedNumber: "••••4521", availableBalance: 12450.32),
            isSelected: true
        ) {}
        Divider().padding(.leading, 84)
        BankAccountRow(
            account: BankAccount(name: "Savings", accountType: .savings, maskedNumber: "••••7832", availableBalance: 45230.00),
            isSelected: false
        ) {}
    }
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .padding()
}
