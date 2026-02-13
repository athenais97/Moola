import SwiftUI

/// Full-screen success screen shown after tapping "CLAIM IT".
struct DailyCreditSuccessView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 132, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "BDA0FF") ?? DesignSystem.Colors.focusBorder,
                                Color(hex: "94CCFF") ?? DesignSystem.Colors.accent.opacity(0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.top, 18)
                    .accessibilityHidden(true)
                
                HStack(spacing: 10) {
                    Text("1")
                        .font(DesignSystem.Typography.ibmPlexSansHebrew(.bold, size: 48))
                        .foregroundColor(DesignSystem.Colors.ink)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "BDA0FF") ?? DesignSystem.Colors.focusBorder,
                                    Color(hex: "94CCFF") ?? DesignSystem.Colors.accent.opacity(0.35)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .accessibilityHidden(true)
                }
                .padding(.top, 22)
                
                (Text("people who reach a 5-day credit score are\n")
                    .foregroundColor(DesignSystem.Colors.inkSecondary)
                 + Text("12x")
                    .foregroundColor(DesignSystem.Colors.ink)
                 + Text(" more likely to upgrade\ntheir portfolio.")
                    .foregroundColor(DesignSystem.Colors.inkSecondary)
                )
                .font(DesignSystem.Typography.ibmPlexSansHebrew(.semibold, size: 18.477))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 90)
                
                Spacer(minLength: 0)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(DesignSystem.Typography.ibmPlexSansHebrew(.medium, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 68)
                        .background(Color(hex: "3E9FFF") ?? DesignSystem.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 15)
                .padding(.bottom, 24)
            }
        }
    }
}

