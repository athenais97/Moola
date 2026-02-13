import SwiftUI

/// Step 3: Knowledge Level Selection
/// UX: Clean list, no judgment, reassuring confirmation messages
/// This is "The How" — understanding how to tailor guidance
struct KnowledgeLevelStepView: View {
    @ObservedObject var viewModel: InvestorProfilingViewModel
    @EnvironmentObject var appState: AppState
    
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
            
            // Reassurance message
            if let message = viewModel.knowledgeReassuranceMessage {
                reassuranceMessage(message)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Spacer()
            
            // Info link (progressive disclosure)
            infoLinkView
            
            // Complete button
            PrimaryButton(
                title: viewModel.primaryButtonTitle,
                isEnabled: viewModel.isCurrentStepValid,
                isLoading: viewModel.isLoading
            ) {
                completeProfileFlow()
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
            Text(InvestorProfilingStep.knowledgeLevel.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(InvestorProfilingStep.knowledgeLevel.subtitle)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Options
    
    private var optionsView: some View {
        VStack(spacing: 12) {
            ForEach(KnowledgeLevel.allCases, id: \.self) { level in
                SelectableCard(
                    isSelected: viewModel.profile.knowledgeLevel == level,
                    action: {
                        viewModel.selectKnowledgeLevel(level)
                    }
                ) {
                    KnowledgeLevelCardContent(
                        level: level,
                        isSelected: viewModel.profile.knowledgeLevel == level
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Reassurance Message
    
    private func reassuranceMessage(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.08))
        .cornerRadius(12)
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Info Link
    
    private var infoLinkView: some View {
        Button(action: {
            viewModel.showKnowledgeInfo()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                Text("Why do we ask this?")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.accentColor)
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Actions
    
    private func completeProfileFlow() {
        Task {
            let profile = await viewModel.completeProfile()
            appState.completeInvestorProfiling(with: profile)
        }
    }
}

// MARK: - Preview

#Preview {
    KnowledgeLevelStepView(viewModel: InvestorProfilingViewModel())
        .environmentObject(AppState())
}

#Preview("Beginner Selected") {
    let vm = InvestorProfilingViewModel()
    vm.profile.knowledgeLevel = .beginner
    return KnowledgeLevelStepView(viewModel: vm)
        .environmentObject(AppState())
}

#Preview("Expert Selected") {
    let vm = InvestorProfilingViewModel()
    vm.profile.knowledgeLevel = .expert
    return KnowledgeLevelStepView(viewModel: vm)
        .environmentObject(AppState())
}
