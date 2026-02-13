import SwiftUI

/// Custom haptic slider for risk tolerance selection
/// Provides emotional framing through dynamic microcopy and subtle color shifts
/// UX: Risk feels personal and emotional, not mathematical
struct RiskSlider: View {
    @Binding var value: Double
    let onChanged: ((Double) -> Void)?
    
    @State private var isDragging: Bool = false
    @State private var lastHapticValue: Double = 0.5
    
    init(value: Binding<Double>, onChanged: ((Double) -> Void)? = nil) {
        self._value = value
        self.onChanged = onChanged
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Dynamic microcopy
            microcopyView
            
            // Custom slider track and thumb
            sliderView
            
            // Labels at ends
            labelsView
        }
    }
    
    // MARK: - Microcopy
    
    private var microcopyView: some View {
        Text(microcopyText)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .animation(.easeOut(duration: 0.2), value: microcopyText)
    }
    
    private var microcopyText: String {
        switch value {
        case 0..<0.2:
            return "I sleep well knowing my investments are safe"
        case 0.2..<0.4:
            return "I prefer stability, with some room for growth"
        case 0.4..<0.6:
            return "I'm okay with ups and downs for better returns"
        case 0.6..<0.8:
            return "I can handle volatility for higher potential"
        case 0.8...1.0:
            return "I'm comfortable with significant swings"
        default:
            return "I'm okay with ups and downs for better returns"
        }
    }
    
    // MARK: - Slider
    
    private var sliderView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                trackBackground(width: geometry.size.width)
                
                // Filled track
                filledTrack(width: geometry.size.width)
                
                // Thumb
                thumbView
                    .offset(x: thumbOffset(for: geometry.size.width))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        handleDrag(gesture: gesture, width: geometry.size.width)
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
        }
        .frame(height: 44)
    }
    
    private func trackBackground(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.3),
                        Color.yellow.opacity(0.3),
                        Color.orange.opacity(0.3),
                        Color.red.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 8)
            .frame(maxHeight: .infinity)
    }
    
    private func filledTrack(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(trackGradient)
            .frame(width: max(0, value * (width - 44) + 22), height: 8)
            .frame(maxHeight: .infinity, alignment: .leading)
    }
    
    private var trackGradient: LinearGradient {
        LinearGradient(
            colors: trackColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var trackColors: [Color] {
        switch value {
        case 0..<0.25:
            return [Color.green, Color.green]
        case 0.25..<0.5:
            return [Color.green, Color.yellow]
        case 0.5..<0.75:
            return [Color.green, Color.yellow, Color.orange]
        default:
            return [Color.green, Color.yellow, Color.orange, Color.red]
        }
    }
    
    private var thumbView: some View {
        ZStack {
            // Outer glow when dragging
            Circle()
                .fill(thumbColor.opacity(0.2))
                .frame(width: 52, height: 52)
                .opacity(isDragging ? 1 : 0)
                .scaleEffect(isDragging ? 1.1 : 0.8)
            
            // Main thumb
            Circle()
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(thumbColor, lineWidth: 3)
                )
                .scaleEffect(isDragging ? 1.1 : 1.0)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
    }
    
    private var thumbColor: Color {
        switch value {
        case 0..<0.25:
            return .green
        case 0.25..<0.5:
            return .yellow
        case 0.5..<0.75:
            return .orange
        default:
            return .red
        }
    }
    
    private func thumbOffset(for width: CGFloat) -> CGFloat {
        let trackWidth = width - 44 // Account for thumb width
        return value * trackWidth
    }
    
    // MARK: - Labels
    
    private var labelsView: some View {
        HStack {
            Text("Conservative")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(value < 0.3 ? .primary : .secondary)
            
            Spacer()
            
            Text("Adventurous")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(value > 0.7 ? .primary : .secondary)
        }
    }
    
    // MARK: - Gesture Handling
    
    private func handleDrag(gesture: DragGesture.Value, width: CGFloat) {
        if !isDragging {
            isDragging = true
        }
        
        let trackWidth = width - 44
        let newValue = min(max(0, gesture.location.x / trackWidth), 1.0)
        
        // Provide haptic feedback at thresholds
        provideHapticFeedback(for: newValue)
        
        value = newValue
        onChanged?(newValue)
    }
    
    private func handleDragEnd() {
        isDragging = false
        
        // Final haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func provideHapticFeedback(for newValue: Double) {
        // Haptic at every 0.1 increment
        let oldStep = Int(lastHapticValue * 10)
        let newStep = Int(newValue * 10)
        
        if oldStep != newStep {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            lastHapticValue = newValue
        }
        
        // Stronger haptic at major thresholds (0.25, 0.5, 0.75)
        let majorThresholds = [0.25, 0.5, 0.75]
        for threshold in majorThresholds {
            let wasBelow = lastHapticValue < threshold
            let wasAbove = lastHapticValue > threshold
            let isNear = abs(newValue - threshold) < 0.02
            
            if isNear && (wasBelow || wasAbove) && abs(lastHapticValue - threshold) >= 0.02 {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - Risk Visualization

/// Optional visual hint showing risk/return relationship
/// Non-intrusive illustration to inform, not persuade
struct RiskVisualizationHint: View {
    let riskValue: Double
    
    var body: some View {
        VStack(spacing: 8) {
            // Simple curve illustration
            curveView
                .frame(height: 60)
            
            // Label
            Text("Potential range of outcomes")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var curveView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Draw a simple volatility illustration
            ZStack {
                // Base line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height / 2))
                    path.addLine(to: CGPoint(x: width, y: height / 2))
                }
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                
                // Volatility envelope
                volatilityPath(width: width, height: height)
                    .fill(Color.accentColor.opacity(0.15))
                
                // Growth trend line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height * 0.7))
                    path.addLine(to: CGPoint(x: width, y: height * (0.4 - riskValue * 0.2)))
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
    }
    
    private func volatilityPath(width: CGFloat, height: CGFloat) -> Path {
        let amplitude = height * 0.15 * (0.5 + riskValue)
        
        return Path { path in
            // Upper bound
            path.move(to: CGPoint(x: 0, y: height * 0.7 - amplitude * 0.5))
            path.addLine(to: CGPoint(x: width, y: height * (0.4 - riskValue * 0.2) - amplitude))
            
            // Lower bound (going back)
            path.addLine(to: CGPoint(x: width, y: height * (0.4 - riskValue * 0.2) + amplitude))
            path.addLine(to: CGPoint(x: 0, y: height * 0.7 + amplitude * 0.5))
            path.closeSubpath()
        }
    }
}

// MARK: - Previews

#Preview("Risk Slider") {
    struct PreviewWrapper: View {
        @State private var value: Double = 0.5
        
        var body: some View {
            VStack(spacing: 40) {
                RiskSlider(value: $value)
                
                Text("Value: \(String(format: "%.2f", value))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                RiskVisualizationHint(riskValue: value)
            }
            .padding(24)
        }
    }
    
    return PreviewWrapper()
}

#Preview("Risk Slider States") {
    VStack(spacing: 40) {
        RiskSlider(value: .constant(0.1))
        RiskSlider(value: .constant(0.5))
        RiskSlider(value: .constant(0.9))
    }
    .padding(24)
}
