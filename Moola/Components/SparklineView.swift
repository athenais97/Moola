import SwiftUI

/// Minimalist sparkline chart for trend visualization
/// UX Intent: Show balance trend at a glance without overwhelming detail
/// Design: Elegant, simplified line with subtle gradient fill
struct SparklineView: View {
    let dataPoints: [BalanceDataPoint]
    let isPositive: Bool
    let height: CGFloat
    let showsEndPoint: Bool
    
    @State private var animationProgress: CGFloat = 0
    
    init(
        dataPoints: [BalanceDataPoint],
        isPositive: Bool = true,
        height: CGFloat = 60,
        showsEndPoint: Bool = true
    ) {
        self.dataPoints = dataPoints
        self.isPositive = isPositive
        self.height = height
        self.showsEndPoint = showsEndPoint
    }
    
    /// Convenience initializer for raw Decimal values
    /// Creates BalanceDataPoint entries with synthetic dates
    init(dataPoints: [Decimal], isPositive: Bool = true, height: CGFloat = 60, showsEndPoint: Bool = true) {
        let calendar = Calendar.current
        let today = Date()
        let count = dataPoints.count
        
        self.dataPoints = dataPoints.enumerated().map { index, value in
            let daysAgo = count - 1 - index
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            return BalanceDataPoint(date: date, value: value)
        }
        self.isPositive = isPositive
        self.height = height
        self.showsEndPoint = showsEndPoint
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient fill below the line
                if dataPoints.count >= 2 {
                    gradientFill(in: geometry.size)
                        .clipShape(
                            SparklineShape(
                                dataPoints: dataPoints,
                                progress: animationProgress,
                                closePath: true
                            )
                        )
                }
                
                // The sparkline itself
                SparklineShape(dataPoints: dataPoints, progress: animationProgress)
                    .stroke(
                        lineColor,
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
                    )
                
                // End point indicator
                if showsEndPoint, !dataPoints.isEmpty, animationProgress >= 1 {
                    endPointIndicator(in: geometry.size)
                }
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animationProgress = 1
            }
        }
    }
    
    // MARK: - Subviews
    
    private func gradientFill(in size: CGSize) -> some View {
        LinearGradient(
            colors: [
                lineColor.opacity(0.25),
                lineColor.opacity(0.05),
                lineColor.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func endPointIndicator(in size: CGSize) -> some View {
        let position = calculateEndPoint(in: size)
        
        return ZStack {
            // Outer glow
            Circle()
                .fill(lineColor.opacity(0.2))
                .frame(width: 16, height: 16)
            
            // Inner dot
            Circle()
                .fill(lineColor)
                .frame(width: 8, height: 8)
        }
        .position(position)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Computed Properties
    
    private var lineColor: Color {
        isPositive ? DesignSystem.Colors.positive : DesignSystem.Colors.negative
    }
    
    // MARK: - Calculations
    
    private func calculateEndPoint(in size: CGSize) -> CGPoint {
        guard dataPoints.count >= 2 else {
            return CGPoint(x: size.width, y: size.height / 2)
        }
        
        let values = dataPoints.map { NSDecimalNumber(decimal: $0.value).doubleValue }
        guard let minValue = values.min(), let maxValue = values.max() else {
            return CGPoint(x: size.width, y: size.height / 2)
        }
        
        let range = maxValue - minValue
        let padding: CGFloat = 8
        
        let x = size.width - padding
        let lastValue = values.last ?? 0
        
        let y: CGFloat
        if range == 0 {
            y = size.height / 2
        } else {
            let normalizedValue = (lastValue - minValue) / range
            y = size.height - padding - (CGFloat(normalizedValue) * (size.height - 2 * padding))
        }
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Sparkline Shape

/// Custom shape that draws the sparkline path
struct SparklineShape: Shape {
    let dataPoints: [BalanceDataPoint]
    var progress: CGFloat
    var closePath: Bool
    
    init(dataPoints: [BalanceDataPoint], progress: CGFloat = 1, closePath: Bool = false) {
        self.dataPoints = dataPoints
        self.progress = progress
        self.closePath = closePath
    }
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        guard dataPoints.count >= 2 else {
            return Path()
        }
        
        let values = dataPoints.map { NSDecimalNumber(decimal: $0.value).doubleValue }
        guard let minValue = values.min(), let maxValue = values.max() else {
            return Path()
        }
        
        var path = Path()
        
        let range = maxValue - minValue
        let padding: CGFloat = 8
        let availableWidth = rect.width - 2 * padding
        let availableHeight = rect.height - 2 * padding
        
        let points = values.enumerated().map { index, value -> CGPoint in
            let x = padding + (CGFloat(index) / CGFloat(values.count - 1)) * availableWidth
            
            let y: CGFloat
            if range == 0 {
                y = rect.height / 2
            } else {
                let normalizedValue = (value - minValue) / range
                y = rect.height - padding - (CGFloat(normalizedValue) * availableHeight)
            }
            
            return CGPoint(x: x, y: y)
        }
        
        // Calculate how many points to draw based on progress
        let totalLength = calculateTotalLength(points: points)
        let targetLength = totalLength * Double(progress)
        
        path.move(to: points[0])
        
        var currentLength: Double = 0
        for i in 1..<points.count {
            let segmentLength = distance(from: points[i-1], to: points[i])
            
            if currentLength + segmentLength <= targetLength {
                path.addLine(to: points[i])
                currentLength += segmentLength
            } else {
                // Partial segment
                let remainingLength = targetLength - currentLength
                let fraction = remainingLength / segmentLength
                let partialPoint = CGPoint(
                    x: points[i-1].x + CGFloat(fraction) * (points[i].x - points[i-1].x),
                    y: points[i-1].y + CGFloat(fraction) * (points[i].y - points[i-1].y)
                )
                path.addLine(to: partialPoint)
                break
            }
        }
        
        // Close path for gradient fill
        if closePath && progress >= 1 {
            path.addLine(to: CGPoint(x: points.last?.x ?? rect.width - padding, y: rect.height))
            path.addLine(to: CGPoint(x: points.first?.x ?? padding, y: rect.height))
            path.closeSubpath()
        }
        
        return path
    }
    
    private func calculateTotalLength(points: [CGPoint]) -> Double {
        var total: Double = 0
        for i in 1..<points.count {
            total += distance(from: points[i-1], to: points[i])
        }
        return total
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(Double(dx * dx + dy * dy))
    }
}

// MARK: - Preview

#Preview("Sparkline - Positive Trend") {
    VStack(spacing: 24) {
        SparklineView(
            dataPoints: BalanceDataPoint.sampleWeekData,
            isPositive: true,
            height: 80
        )
        .padding(.horizontal)
        
        Text("Positive Trend")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Sparkline - Negative Trend") {
    let negativeTrend: [BalanceDataPoint] = {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -6, to: today)!, value: 127000.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -5, to: today)!, value: 126500.50),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -4, to: today)!, value: 125800.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 126100.75),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -2, to: today)!, value: 124900.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 124200.25),
            BalanceDataPoint(date: today, value: 123450.32)
        ]
    }()
    
    VStack(spacing: 24) {
        SparklineView(
            dataPoints: negativeTrend,
            isPositive: false,
            height: 80
        )
        .padding(.horizontal)
        
        Text("Negative Trend")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Sparkline - Flat Trend") {
    let flatTrend: [BalanceDataPoint] = {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -6, to: today)!, value: 50000.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -5, to: today)!, value: 50000.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -4, to: today)!, value: 50000.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 50000.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -2, to: today)!, value: 50000.00),
            BalanceDataPoint(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 50000.00),
            BalanceDataPoint(date: today, value: 50000.00)
        ]
    }()
    
    VStack(spacing: 24) {
        SparklineView(
            dataPoints: flatTrend,
            isPositive: true,
            height: 80
        )
        .padding(.horizontal)
        
        Text("Flat Trend")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(.systemBackground))
}
