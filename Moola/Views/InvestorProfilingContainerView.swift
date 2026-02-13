import SwiftUI

/// Main container for the Investor Profiling flow
/// Runs after account creation, before access to portfolio
/// UX: Stepper-based, one question per screen, premium transitions
struct InvestorProfilingContainerView: View {
    @StateObject private var viewModel = InvestorProfilingViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.backgroundCanvas
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation bar
                navigationBar
                
                // Progress indicator
                StepProgressView(
                    currentStep: viewModel.currentStep.rawValue,
                    totalSteps: InvestorProfilingStep.allCases.count
                )
                .padding(.top, 9)
                
                // Step content with transitions
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(viewModel.currentStep)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            // Back button (only if allowed)
            if viewModel.currentStep.canGoBack {
                Button {
                    viewModel.goToPreviousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.ink)
                        .frame(width: 24, height: 24)
                }
            } else {
                Color.clear
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
            
            // Step indicator text
            Text("Step \(viewModel.currentStep.stepIndicator)")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .frame(height: 24)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .objective:
            InvestmentObjectiveStepView(viewModel: viewModel)
            
        case .riskAppetite:
            RiskAppetiteStepView(viewModel: viewModel)
            
        case .knowledgeLevel:
            KnowledgeLevelStepView(viewModel: viewModel)
                .environmentObject(appState)
        }
    }
}

// MARK: - Preview

#Preview {
    InvestorProfilingContainerView()
        .environmentObject(AppState())
}

#Preview("Step 2 - Risk") {
    let appState = AppState()
    let view = InvestorProfilingContainerView()
    // Note: Can't directly set step in preview without modifying view
    return view.environmentObject(appState)
}
