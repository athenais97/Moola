import SwiftUI

/// Progress indicator showing current step in the onboarding flow
/// Uses subtle visual hierarchy to show progress without overwhelming
struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        // Figma: 6 segments, 4px height, 4px gaps,
        // current segment is wider (21), others are 14.
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { index in
                ProgressDot(
                    state: dotState(for: index),
                    index: index
                )
            }
        }
    }
    
    private func dotState(for index: Int) -> ProgressDotState {
        if index < currentStep {
            return .completed
        } else if index == currentStep {
            return .current
        } else {
            return .upcoming
        }
    }
}

enum ProgressDotState {
    case completed
    case current
    case upcoming
}

struct ProgressDot: View {
    let state: ProgressDotState
    let index: Int
    
    var body: some View {
        Capsule(style: .continuous)
            .fill(dotFill)
            .frame(width: dotWidth, height: 4)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: state)
    }
    
    private var dotFill: AnyShapeStyle {
        switch state {
        case .completed:
            return AnyShapeStyle(DesignSystem.Gradients.chatAccent)
        case .current:
            return AnyShapeStyle(DesignSystem.Gradients.chatAccent)
        case .upcoming:
            return AnyShapeStyle(DesignSystem.Colors.inkSecondary.opacity(0.5))
        }
    }
    
    private var dotWidth: CGFloat {
        switch state {
        case .current:
            return 21
        default:
            return 14
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        StepProgressView(currentStep: 0, totalSteps: 6)
        StepProgressView(currentStep: 2, totalSteps: 6)
        StepProgressView(currentStep: 5, totalSteps: 6)
    }
    .padding()
}
