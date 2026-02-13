import SwiftUI

/// Primary CTA button for onboarding steps
/// Designed with accessibility and feedback in mind
struct PrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    init(
        title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            }
        }) {
            ZStack {
                // Button text
                Text(title)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                    .opacity(isLoading ? 0 : 1)
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 63)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous)
                    .fill(buttonFill)
            )
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
        .animation(.easeOut(duration: 0.2), value: isLoading)
    }
    
    private var buttonFill: Color {
        if !isEnabled {
            return DesignSystem.Colors.buttonDisabledFill
        }
        
        // DS: solid accent fill (#3E9FFF).
        return DesignSystem.Colors.accent
    }
}

/// Secondary/text button style for less prominent actions
struct SecondaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if isEnabled {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }
        }) {
            Text(title)
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(isEnabled ? DesignSystem.Colors.ink : DesignSystem.Colors.inkSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 63)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
                .opacity(isEnabled ? 1.0 : 0.65)
        }
        .disabled(!isEnabled)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

#Preview("Enabled") {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", isEnabled: true, isLoading: false) {
            print("Tapped")
        }
        
        PrimaryButton(title: "Continue", isEnabled: false, isLoading: false) {
            print("Tapped")
        }
        
        PrimaryButton(title: "Continue", isEnabled: true, isLoading: true) {
            print("Tapped")
        }
        
        SecondaryButton(title: "Resend Code", isEnabled: true) {
            print("Tapped")
        }
    }
    .padding()
}
