import SwiftUI

// MARK: - Synchronized Accounts View

/// Full-screen "Financial Engine Room" for managing linked financial accounts
/// UX Intent: Aggregated view emphasizing connection health, real-time status, and total value
/// Foundation compliance:
/// - One clear intent: Manage and monitor all financial connections
/// - Mobile-first: Thumb-friendly actions, swipe gestures, native patterns
/// - Progressive disclosure: Summary first, expand for details
/// - Premium aesthetic: Clean groupings, not a cluttered list
struct SyncedAccountsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SynchronizedAccountsViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content based on state
                Group {
                    if viewModel.loadingState.isLoading && !viewModel.hasLoadedOnce {
                        // Initial loading state with skeleton
                        SyncedAccountsSkeletonView()
                            .transition(.opacity)
                    } else if viewModel.hasInstitutions {
                        // Main content with institutions
                        accountsContent
                            .transition(.opacity)
                    } else if viewModel.hasLoadedOnce {
                        // Empty state
                        NoAccountsEmptyState(onAddAccount: viewModel.initiateAddAccount)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.loadingState)
            }
            .navigationTitle("Connected Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.hasInstitutions {
                        toolbarMenu
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.fetchInstitutions()
        }
        .fullScreenCover(isPresented: $viewModel.showAddAccount) {
            BankLinkingContainerView(
                onComplete: viewModel.handleAddAccountCompletion,
                onCancel: viewModel.handleAddAccountCancellation
            )
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("Try Again") {
                Task { await viewModel.retry() }
            }
            Button("Dismiss", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Main Content
    
    private var accountsContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Aggregated balance header
                    AggregatedBalanceHeader(
                        portfolio: viewModel.portfolio,
                        isPrivacyMode: viewModel.isPrivacyModeEnabled,
                        onTogglePrivacy: viewModel.togglePrivacyMode
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Institutions list
                    institutionsList
                        .padding(.horizontal, 16)
                    
                    // Bottom spacing for button
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 16)
            }
            
            // Floating add account button
            addAccountButton
        }
    }
    
    // MARK: - Institutions List
    
    private var institutionsList: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text("Your Institutions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                // Expand/collapse all
                Button(action: {
                    if viewModel.expandedInstitutionIds.count == viewModel.institutions.count {
                        viewModel.collapseAll()
                    } else {
                        viewModel.expandAll()
                    }
                }) {
                    Text(viewModel.expandedInstitutionIds.count == viewModel.institutions.count ? "Collapse All" : "Expand All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            // Institution groups with swipe actions
            ForEach(viewModel.institutions) { institution in
                institutionRow(institution)
            }
        }
    }
    
    /// Individual institution row with swipe-to-unlink
    private func institutionRow(_ institution: SynchronizedInstitution) -> some View {
        InstitutionGroupView(
            institution: institution,
            isPrivacyMode: viewModel.isPrivacyModeEnabled,
            isExpanded: viewModel.isExpanded(institution),
            onToggleExpand: {
                viewModel.toggleExpansion(for: institution)
            },
            onReconnect: {
                viewModel.initiateReconnection(for: institution)
            },
            onUnlink: {
                Task {
                    await viewModel.unlinkInstitution(institution)
                }
            },
            onAccountTap: { account in
                viewModel.handleAccountTap(account, in: institution)
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task {
                    await viewModel.unlinkInstitution(institution)
                }
            } label: {
                Label("Unlink", systemImage: "link.badge.minus")
            }
            
            if institution.requiresReauthentication {
                Button {
                    viewModel.initiateReconnection(for: institution)
                } label: {
                    Label("Reconnect", systemImage: "arrow.triangle.2.circlepath")
                }
                .tint(.orange)
            }
        }
    }
    
    // MARK: - Add Account Button
    
    private var addAccountButton: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground).opacity(0),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            
            // Button container
            VStack {
                Button(action: viewModel.initiateAddAccount) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Add an Account")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(AddAccountButtonStyle())
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Toolbar Menu
    
    private var toolbarMenu: some View {
        Menu {
            // Privacy toggle
            Button {
                viewModel.togglePrivacyMode()
            } label: {
                Label(
                    viewModel.isPrivacyModeEnabled ? "Show Balances" : "Hide Balances",
                    systemImage: viewModel.isPrivacyModeEnabled ? "eye.fill" : "eye.slash.fill"
                )
            }
            
            Divider()
            
            // Expand/Collapse
            Button {
                viewModel.expandAll()
            } label: {
                Label("Expand All", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            
            Button {
                viewModel.collapseAll()
            } label: {
                Label("Collapse All", systemImage: "arrow.down.right.and.arrow.up.left")
            }
            
            Divider()
            
            // Sync
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.accentColor)
        }
    }
}

// MARK: - Add Account Button Style

/// Custom button style for the primary add account action
private struct AddAccountButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Synced Accounts - With Data") {
    SyncedAccountsView()
}

#Preview("Synced Accounts - Empty") {
    let view = SyncedAccountsView()
    return view
}

#Preview("Synced Accounts - Dark Mode") {
    SyncedAccountsView()
        .preferredColorScheme(.dark)
}
