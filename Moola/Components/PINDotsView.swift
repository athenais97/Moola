import SwiftUI

/// Animated PIN dots display (● ● ● ●)
/// Shows visual feedback as digits are entered
struct PINDotsView: View {
    let filledCount: Int
    let totalCount: Int
    let hasError: Bool
    
    @State private var shakeOffset: CGFloat = 0
    
    init(filledCount: Int, totalCount: Int = 4, hasError: Bool = false) {
        self.filledCount = filledCount
        self.totalCount = totalCount
        self.hasError = hasError
    }
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<totalCount, id: \.self) { index in
                PINDot(
                    isFilled: index < filledCount,
                    hasError: hasError,
                    animationDelay: Double(index) * 0.05
                )
            }
        }
        .offset(x: shakeOffset)
        .onChange(of: hasError) { _, newValue in
            if newValue {
                shake()
            }
        }
    }
    
    private func shake() {
        withAnimation(.easeInOut(duration: 0.05)) {
            shakeOffset = 10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.05)) {
                shakeOffset = -10
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.05)) {
                shakeOffset = 8
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.05)) {
                shakeOffset = -8
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                shakeOffset = 0
            }
        }
    }
}

/// Individual PIN dot with fill animation
struct PINDot: View {
    let isFilled: Bool
    let hasError: Bool
    let animationDelay: Double
    
    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(strokeColor, lineWidth: 2)
            )
            .scaleEffect(isFilled ? 1.1 : 1.0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6)
                .delay(animationDelay),
                value: isFilled
            )
    }
    
    private var dotColor: Color {
        if hasError {
            return Color.red.opacity(isFilled ? 1 : 0)
        }
        return isFilled ? Color.primary : Color.clear
    }
    
    private var strokeColor: Color {
        if hasError {
            return .red
        }
        return isFilled ? Color.primary : Color(.systemGray3)
    }
}

#Preview("Empty") {
    PINDotsView(filledCount: 0)
        .padding()
}

#Preview("Half Filled") {
    PINDotsView(filledCount: 2)
        .padding()
}

#Preview("Full") {
    PINDotsView(filledCount: 4)
        .padding()
}

#Preview("Error") {
    PINDotsView(filledCount: 4, hasError: true)
        .padding()
}
