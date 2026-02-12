import SwiftUI

/// Step 1: Bank Selection
/// UI: Prominent search bar + grid of popular banks with high-fidelity logos
/// UX Intent: Make discovery easy, prioritize popular choices
/// Foundation compliance: Scannable in seconds, one clear action per screen
struct BankSelectionStepView: View {
    @ObservedObject var viewModel: BankLinkingViewModel
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with security badge
            headerSection
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            // Search bar
            BankSearchBar(text: $viewModel.searchQuery)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            // Content area
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isSearchActive {
                        // Search results
                        searchResultsSection
                    } else {
                        // Popular banks grid
                        popularBanksSection
                        
                        // All banks list
                        allBanksSection
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title
            VStack(spacing: 8) {
                Text("Link Your Bank")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Select your financial institution to sync your accounts securely.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Security badge
            SecurityBadge(text: "Bank-grade encryption")
        }
    }
    
    // MARK: - Popular Banks Section
    
    private var popularBanksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            Text("Popular Banks")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            // Horizontal scrolling grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.popularBanks) { bank in
                        PopularBankCard(bank: bank) {
                            viewModel.selectBank(bank)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - All Banks Section
    
    private var allBanksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            Text("All Banks")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            // Bank list
            VStack(spacing: 0) {
                ForEach(Array(viewModel.allBanks.enumerated()), id: \.element.id) { index, bank in
                    BankListRow(bank: bank) {
                        viewModel.selectBank(bank)
                    }
                    
                    if index < viewModel.allBanks.count - 1 {
                        Divider()
                            .padding(.leading, 74)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Search Results Section
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.filteredBanks.isEmpty {
                // Empty state
                BankLinkingEmptyState(type: .noSearchResults, retryAction: nil)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                // Results header
                Text("\(viewModel.filteredBanks.count) Result\(viewModel.filteredBanks.count == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                // Results list
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.filteredBanks.enumerated()), id: \.element.id) { index, bank in
                        BankListRow(bank: bank) {
                            viewModel.selectBank(bank)
                        }
                        
                        if index < viewModel.filteredBanks.count - 1 {
                            Divider()
                                .padding(.leading, 74)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BankSelectionStepView(viewModel: BankLinkingViewModel())
}
