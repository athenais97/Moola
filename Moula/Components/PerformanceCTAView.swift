import SwiftUI

/// Shared Performance CTA row/card used in sheets/panels.
struct PerformanceCTAView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            onTap()
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.80))
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY
                    )
                    .overlay(
                        Image(systemName: "tag")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.accent)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("How you got here over time")
                        .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 74)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Performance CTA") {
    PerformanceCTAView(onTap: {})
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

