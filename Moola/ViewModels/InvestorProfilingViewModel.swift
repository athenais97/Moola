import Foundation
import SwiftUI
import Combine

/// ViewModel for the Investor Profiling flow
/// Manages state and navigation for capturing the user's "Investor DNA"
@MainActor
class InvestorProfilingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentStep: InvestorProfilingStep = .objective
    @Published var profile: InvestorProfile = InvestorProfile()
    @Published var isLoading: Bool = false
    @Published var showInfoSheet: Bool = false
    @Published var infoSheetContent: InfoSheetContent?
    
    // MARK: - Computed Properties
    
    /// Whether the current step has a valid selection
    var isCurrentStepValid: Bool {
        switch currentStep {
        case .objective:
            return profile.objective != nil
        case .riskAppetite:
            return true // Always valid - has default value
        case .knowledgeLevel:
            return profile.knowledgeLevel != nil
        }
    }
    
    /// Primary button title based on current step
    var primaryButtonTitle: String {
        switch currentStep {
        case .knowledgeLevel:
            return "Complete Profile"
        default:
            return "Continue"
        }
    }
    
    /// Whether this is the final step
    var isFinalStep: Bool {
        currentStep == .knowledgeLevel
    }
    
    /// Reassurance message for knowledge level selection
    var knowledgeReassuranceMessage: String? {
        profile.knowledgeLevel?.confirmationMessage
    }
    
    // MARK: - Navigation
    
    func goToNextStep() {
        guard isCurrentStepValid else { return }
        
        provideSelectionFeedback()
        
        if let nextStep = InvestorProfilingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = nextStep
            }
        }
    }
    
    func goToPreviousStep() {
        guard currentStep.canGoBack else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let previousStep = InvestorProfilingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = previousStep
            }
        }
    }
    
    // MARK: - Objective Selection
    
    func selectObjective(_ objective: InvestmentObjective) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            profile.objective = objective
        }
        provideSelectionFeedback()
    }
    
    // MARK: - Risk Appetite
    
    func updateRiskTolerance(_ value: Double) {
        profile.riskTolerance = value
    }
    
    // MARK: - Knowledge Level Selection
    
    func selectKnowledgeLevel(_ level: KnowledgeLevel) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            profile.knowledgeLevel = level
        }
        provideSelectionFeedback()
    }
    
    // MARK: - Info Sheet (Progressive Disclosure)
    
    func showObjectiveInfo() {
        guard let objective = profile.objective else { return }
        infoSheetContent = InfoSheetContent(
            title: objective.title,
            body: objective.detailedExplanation
        )
        showInfoSheet = true
    }
    
    func showRiskInfo() {
        infoSheetContent = InfoSheetContent(
            title: "What is risk tolerance?",
            body: "Risk tolerance reflects how comfortable you are with temporary losses in your portfolio value. Higher risk tolerance can mean higher potential returns over time, but also bigger short-term swings. There's no right or wrong answer—it's about what feels right for you."
        )
        showInfoSheet = true
    }
    
    func showKnowledgeInfo() {
        infoSheetContent = InfoSheetContent(
            title: "Why we ask this",
            body: "Your experience level helps us tailor explanations and guidance. Beginners get more context and educational hints. Experienced investors see streamlined interfaces. You can always change this later in settings."
        )
        showInfoSheet = true
    }
    
    // MARK: - Profile Completion
    
    /// Complete the profiling flow and return the finished profile
    func completeProfile() async -> InvestorProfile {
        isLoading = true
        
        // Simulate brief processing
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isLoading = false
        
        return profile
    }
    
    // MARK: - Haptics
    
    private func provideSelectionFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Info Sheet Content

struct InfoSheetContent: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

// MARK: - Info Sheet View

/// Bottom sheet for progressive disclosure of financial explanations
/// UX: Never blocks the flow, always optional
struct InfoBottomSheet: View {
    let content: InfoSheetContent
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Handle
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 4)
                Spacer()
            }
            .padding(.top, 8)
            
            // Title
            Text(content.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            // Body
            Text(content.body)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Spacer()
                .frame(height: 8)
            
            // Dismiss button
            Button(action: onDismiss) {
                Text("Got it")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
