import SwiftUI

/// Native-style segmented control for timeframe selection
///
/// UX Intent:
/// - Thumb-friendly placement (positioned for easy one-hand use)
/// - Native feel with smooth selection animation
/// - Clear visual feedback for current selection
///
/// Foundation Compliance:
/// - Primary actions reachable with one thumb
/// - Every interaction provides clear visual feedback
/// - Subtle, purposeful animations only
struct TimeframeSegmentedControl: View {
    @Binding var selectedTimeframe: PerformanceTimeframe
    
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(PerformanceTimeframe.allCases) { timeframe in
                timeframeButton(for: timeframe)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Timeframe Button
    
    private func timeframeButton(for timeframe: PerformanceTimeframe) -> some View {
        let isSelected = selectedTimeframe == timeframe
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTimeframe = timeframe
            }
        }) {
            Text(timeframe.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(minWidth: 44, minHeight: 32)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                            .matchedGeometryEffect(id: "selection", in: animation)
                    }
                }
        }
        .buttonStyle(TimeframeButtonStyle())
        .accessibilityLabel(timeframe.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Button Style

private struct TimeframeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Alternative Pill Style

/// Alternative pill-style segmented control (matches AnalysisView style)
struct TimeframePillControl: View {
    @Binding var selectedTimeframe: PerformanceTimeframe
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(PerformanceTimeframe.allCases) { timeframe in
                pillButton(for: timeframe)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func pillButton(for timeframe: PerformanceTimeframe) -> some View {
        let isSelected = selectedTimeframe == timeframe
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTimeframe = timeframe
            }
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }) {
            Text(timeframe.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(timeframe.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview("Segmented Control") {
    struct PreviewWrapper: View {
        @State private var selected: PerformanceTimeframe = .week
        
        var body: some View {
            VStack(spacing: 32) {
                TimeframeSegmentedControl(selectedTimeframe: $selected)
                
                Text("Selected: \(selected.accessibilityLabel)")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Pill Control") {
    struct PreviewWrapper: View {
        @State private var selected: PerformanceTimeframe = .week
        
        var body: some View {
            VStack(spacing: 32) {
                TimeframePillControl(selectedTimeframe: $selected)
                
                Text("Selected: \(selected.accessibilityLabel)")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Dark Mode") {
    struct PreviewWrapper: View {
        @State private var selected: PerformanceTimeframe = .month
        
        var body: some View {
            VStack(spacing: 32) {
                TimeframeSegmentedControl(selectedTimeframe: $selected)
                TimeframePillControl(selectedTimeframe: $selected)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
