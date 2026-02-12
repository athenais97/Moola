import SwiftUI

/// Main container for the onboarding flow
/// Handles navigation, transitions, and step display
struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
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
                    totalSteps: OnboardingStep.allCases.count
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
        .alert("Something went wrong", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            // Back button
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
            
            // Step indicator text (optional, subtle)
            Text("Step \(viewModel.currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
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
        case .name:
            NameStepView(viewModel: viewModel)
            
        case .age:
            AgeStepView(viewModel: viewModel)
            
        case .email:
            EmailStepView(viewModel: viewModel)
            
        case .verification:
            VerificationStepView(viewModel: viewModel)
            
        case .pinCreation:
            PINCreationView(viewModel: viewModel)
            
        case .pinConfirmation:
            PINConfirmationView(viewModel: viewModel)
                .environmentObject(appState)
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppState())
}
