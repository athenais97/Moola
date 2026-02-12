import SwiftUI

/// Step 2: Risk Appetite Selection
/// UX: Emotional framing through slider, dynamic microcopy, subtle color shifts
/// This is "The Feel" — understanding the investor's comfort with volatility
struct RiskAppetiteStepView: View {
    @ObservedObject var viewModel: InvestorProfilingViewModel
    @State private var showVisualization: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            // Header
            headerView
            
            Spacer()
                .frame(height: 48)
            
            // Risk slider
            sliderSection
            
            Spacer()
                .frame(height: 32)
            
            // Optional visualization toggle
            visualizationSection
            
            Spacer()
            
            // Info link (progressive disclosure)
            infoLinkView
            
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
            Text(InvestorProfilingStep.riskAppetite.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(InvestorProfilingStep.riskAppetite.subtitle)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Slider Section
    
    private var sliderSection: some View {
        VStack(spacing: 16) {
            // Slider with dynamic feedback
            RiskSlider(
                value: Binding(
                    get: { viewModel.profile.riskTolerance },
                    set: { viewModel.updateRiskTolerance($0) }
                )
            )
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Visualization Section
    
    private var visualizationSection: some View {
        VStack(spacing: 16) {
            // Toggle to show/hide visualization
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showVisualization.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: showVisualization ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                    Text(showVisualization ? "Hide illustration" : "See what this means")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            
            // Visualization (optional, non-intrusive)
            if showVisualization {
                RiskVisualizationHint(riskValue: viewModel.profile.riskTolerance)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Info Link
    
    private var infoLinkView: some View {
        Button(action: {
            viewModel.showRiskInfo()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                Text("What is risk tolerance?")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.accentColor)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview {
    RiskAppetiteStepView(viewModel: InvestorProfilingViewModel())
}

#Preview("Low Risk") {
    let vm = InvestorProfilingViewModel()
    vm.profile.riskTolerance = 0.2
    return RiskAppetiteStepView(viewModel: vm)
}

#Preview("High Risk") {
    let vm = InvestorProfilingViewModel()
    vm.profile.riskTolerance = 0.85
    return RiskAppetiteStepView(viewModel: vm)
}
