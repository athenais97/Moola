import SwiftUI

/// A large, tactile selectable surface for option selection
/// Designed to feel premium and provide clear visual feedback
/// UX: Replaces radio buttons/dropdowns with touch-friendly surfaces
struct SelectableCard<Content: View>: View {
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var isPressed: Bool = false
    
    init(
        isSelected: Bool,
        isRecommended: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isSelected = isSelected
        self.isRecommended = isRecommended
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(cardBackground)
                    .overlay(cardBorder)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Recommended badge
                if isRecommended && !isSelected {
                    recommendedBadge
                        .padding(12)
                }
                
                // Selected checkmark
                if isSelected {
                    selectedIndicator
                        .padding(12)
                }
            }
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Subviews
    
    private var cardBackground: some View {
        Group {
            if isSelected {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.08),
                        Color.accentColor.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(.systemGray6)
            }
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                isSelected ? Color.accentColor : Color.clear,
                lineWidth: 2
            )
    }
    
    private var recommendedBadge: some View {
        Text("Recommended")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.12))
            )
    }
    
    private var selectedIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 24, height: 24)
            
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

/// Custom button style for card interaction feedback
struct CardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Objective Card Content

/// Pre-built content for investment objective cards
struct ObjectiveCardContent: View {
    let objective: InvestmentObjective
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 52, height: 52)
                
                Image(systemName: objective.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(objective.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(objective.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private var iconBackgroundColor: Color {
        isSelected
            ? Color.accentColor.opacity(0.15)
            : Color(.systemGray5)
    }
    
    private var iconColor: Color {
        isSelected ? Color.accentColor : Color(.systemGray)
    }
}

// MARK: - Knowledge Level Card Content

/// Pre-built content for knowledge level cards
struct KnowledgeLevelCardContent: View {
    let level: KnowledgeLevel
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 48, height: 48)
                
                Image(systemName: level.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(level.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(level.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private var iconBackgroundColor: Color {
        isSelected
            ? Color.accentColor.opacity(0.15)
            : Color(.systemGray5)
    }
    
    private var iconColor: Color {
        isSelected ? Color.accentColor : Color(.systemGray)
    }
}

// MARK: - Previews

#Preview("Objective Cards") {
    VStack(spacing: 16) {
        SelectableCard(
            isSelected: false,
            isRecommended: false,
            action: {}
        ) {
            ObjectiveCardContent(
                objective: .security,
                isSelected: false
            )
        }
        
        SelectableCard(
            isSelected: false,
            isRecommended: true,
            action: {}
        ) {
            ObjectiveCardContent(
                objective: .balanced,
                isSelected: false
            )
        }
        
        SelectableCard(
            isSelected: true,
            isRecommended: false,
            action: {}
        ) {
            ObjectiveCardContent(
                objective: .growth,
                isSelected: true
            )
        }
    }
    .padding()
}

#Preview("Knowledge Level Cards") {
    VStack(spacing: 12) {
        ForEach(KnowledgeLevel.allCases, id: \.self) { level in
            SelectableCard(
                isSelected: level == .intermediate,
                action: {}
            ) {
                KnowledgeLevelCardContent(
                    level: level,
                    isSelected: level == .intermediate
                )
            }
        }
    }
    .padding()
}
