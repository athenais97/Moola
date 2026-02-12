import SwiftUI

/// Step 3: Account Selection
/// UI: Multi-select list with account details and masked identifiers
/// UX Intent: Clear overview of available accounts, easy selection
/// Foundation compliance: Scannable, one action (confirm selection), thumb-friendly CTA
struct AccountSelectionStepView: View {
    @ObservedObject var viewModel: BankLinkingViewModel
    let onComplete: (Set<String>) -> Void
    
    @State private var isConfirming: Bool = false
    @State private var showSuccessAnimation: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Content
                if viewModel.isLoadingAccounts {
                    loadingContent
                } else if viewModel.availableAccounts.isEmpty {
                    emptyStateContent
                } else {
                    accountsContent
                }
                
                Spacer(minLength: 0)
                
                // Sticky footer with confirm button
                stickyFooter
            }
            
            // Success overlay
            if showSuccessAnimation {
                successOverlay
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Success indicator from bank connection
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                Text("Connected to \(viewModel.selectedBank?.name ?? "Bank")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
            
            // Title
            Text("Select Accounts to Sync")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            // Subtitle
            Text("Choose which accounts you'd like to track in the app.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Loading Content
    
    private var loadingContent: some View {
        VStack(spacing: 0) {
            // Skeleton rows
            ForEach(0..<3, id: \.self) { index in
                AccountSkeletonRow()
                
                if index < 2 {
                    Divider()
                        .padding(.leading, 84)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty State Content
    
    private var emptyStateContent: some View {
        BankLinkingEmptyState(
            type: .noAccountsFound,
            retryAction: {
                // In production, this would retry fetching accounts
            }
        )
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
    
    // MARK: - Accounts Content
    
    private var accountsContent: some View {
        VStack(spacing: 16) {
            // Select all / Deselect all
            selectAllToggle
                .padding(.horizontal, 20)
            
            // Accounts list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.availableAccounts.enumerated()), id: \.element.id) { index, account in
                        BankAccountRow(
                            account: account,
                            isSelected: viewModel.isAccountSelected(account)
                        ) {
                            viewModel.toggleAccountSelection(account)
                        }
                        
                        if index < viewModel.availableAccounts.count - 1 {
                            Divider()
                                .padding(.leading, 84)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 120) // Space for sticky footer
            }
        }
    }
    
    // MARK: - Select All Toggle
    
    private var selectAllToggle: some View {
        HStack {
            // Account count
            Text("\(viewModel.availableAccounts.count) account\(viewModel.availableAccounts.count == 1 ? "" : "s") found")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Toggle button
            Button(action: {
                if viewModel.selectedAccountIds.count == viewModel.availableAccounts.count {
                    viewModel.deselectAllAccounts()
                } else {
                    viewModel.selectAllAccounts()
                }
            }) {
                Text(viewModel.selectedAccountIds.count == viewModel.availableAccounts.count
                     ? "Deselect All"
                     : "Select All")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    // MARK: - Sticky Footer
    
    private var stickyFooter: some View {
        VStack(spacing: 12) {
            // Security reminder
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("We only have read-access. Your credentials are never stored by us.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Confirm button
            PrimaryButton(
                title: viewModel.confirmButtonTitle,
                isEnabled: viewModel.canConfirmSelection,
                isLoading: isConfirming
            ) {
                confirmSelection()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 34)
        .background(
            Rectangle()
                .fill(Color(.systemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Checkmark animation
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(showSuccessAnimation ? 1 : 0.5)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccessAnimation)
                
                Text("Accounts Linked!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Actions
    
    private func confirmSelection() {
        guard viewModel.canConfirmSelection else { return }
        
        isConfirming = true
        
        Task {
            let success = await viewModel.confirmSelection()
            
            if success {
                // Show success animation
                withAnimation(.easeOut(duration: 0.3)) {
                    showSuccessAnimation = true
                }
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Delay before completing
                try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
                
                onComplete(viewModel.selectedAccountIds)
            }
            
            isConfirming = false
        }
    }
}

// MARK: - Preview

#Preview("Account Selection") {
    let viewModel = BankLinkingViewModel()
    return AccountSelectionStepView(
        viewModel: viewModel,
        onComplete: { _ in }
    )
    .task {
        // Simulate successful connection
        viewModel.selectBank(Bank.sampleBanks[0])
        viewModel.simulateSuccessfulConnection()
    }
}

#Preview("Loading State") {
    let viewModel = BankLinkingViewModel()
    return AccountSelectionStepView(
        viewModel: viewModel,
        onComplete: { _ in }
    )
}
