import SwiftUI

/// Step 1: Investment Objective Selection
/// UX: Large tactile surfaces, human copy, clear visual feedback
/// This is "The Why" — understanding what matters most to the investor
struct InvestmentObjectiveStepView: View {
    @ObservedObject var viewModel: InvestorProfilingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            // Header
            headerView
            
            Spacer()
                .frame(height: 32)
            
            // Options
            optionsView
            
            Spacer()
            
            // Info link (progressive disclosure)
            if viewModel.profile.objective != nil {
                infoLinkView
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Continue button
            PrimaryButton(
                title: viewModel.primaryButtonTitle,
                isEnabled: viewModel.isCurrentStepValid,
                isLoading: viewModel.isLoading
            ) {
                viewModel.goToNextStep()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $viewModel.showInfoSheet) {
            if let content = viewModel.infoSheetContent {
                InfoBottomSheet(content: content) {
                    viewModel.showInfoSheet = false
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text(InvestorProfilingStep.objective.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(InvestorProfilingStep.objective.subtitle)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Options
    
    private var optionsView: some View {
        VStack(spacing: 12) {
            ForEach(InvestmentObjective.allCases, id: \.self) { objective in
                SelectableCard(
                    isSelected: viewModel.profile.objective == objective,
                    isRecommended: objective.isRecommended,
                    action: {
                        viewModel.selectObjective(objective)
                    }
                ) {
                    ObjectiveCardContent(
                        objective: objective,
                        isSelected: viewModel.profile.objective == objective
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Info Link
    
    private var infoLinkView: some View {
        Button(action: {
            viewModel.showObjectiveInfo()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                Text("What does this mean?")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.accentColor)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview {
    InvestmentObjectiveStepView(viewModel: InvestorProfilingViewModel())
}

#Preview("Selected State") {
    let vm = InvestorProfilingViewModel()
    vm.profile.objective = .balanced
    return InvestmentObjectiveStepView(viewModel: vm)
}
