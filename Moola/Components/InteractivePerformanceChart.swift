import SwiftUI

/// Interactive performance chart with Bézier curves, gradient fill, and scrubbing
///
/// UX Intent:
/// - Premium, organic feel through smooth Bézier curves
/// - Responsive scrubbing with haptic feedback
/// - Dynamic Y-axis scaling with smooth animations
///
/// Foundation Compliance:
/// - Fluid, intentional interactions
/// - Clear visual feedback for all interactions
/// - On-device curve smoothing for premium feel
struct InteractivePerformanceChart: View {
    let dataPoints: [PerformanceDataPoint]
    let bounds: ChartBounds
    let isPositive: Bool
    let animationProgress: CGFloat
    let scrubState: ChartScrubState?
    let isTransitioning: Bool
    let onScrubUpdate: (CGFloat, CGRect) -> Void
    let onScrubEnd: () -> Void
    
    @State private var chartSize: CGSize = .zero
    @State private var isLongPressing: Bool = false
    
    // MARK: - Colors
    
    private var lineColor: Color {
        isPositive
            ? Color(red: 0.2, green: 0.7, blue: 0.4)   // Growth Green
            : Color(red: 0.95, green: 0.5, blue: 0.45) // Soft Coral
    }
    
    private var gradientColors: [Color] {
        [
            lineColor.opacity(0.3),
            lineColor.opacity(0.1),
            lineColor.opacity(0.0)
        ]
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid lines (very subtle)
                gridLines(in: geometry.size)
                
                // Main chart content
                if dataPoints.count >= 2 {
                    chartContent(in: geometry.size)
                } else if dataPoints.count == 1 {
                    singlePointView(in: geometry.size)
                }
                
                // Scrub indicator
                if let scrub = scrubState, !isTransitioning {
                    scrubIndicator(scrub: scrub, in: geometry.size)
                }
                
                // Shimmer overlay during transition
                if isTransitioning {
                    shimmerOverlay
                }
            }
            .contentShape(Rectangle())
            .gesture(scrubGesture(in: geometry.size))
            .onAppear {
                chartSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                chartSize = newSize
            }
        }
    }
    
    // MARK: - Grid Lines
    
    private func gridLines(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4) { index in
                if index > 0 {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 0.5)
                }
                Spacer()
            }
        }
        .opacity(0.5) // Very light per requirements
    }
    
    // MARK: - Chart Content
    
    private func chartContent(in size: CGSize) -> some View {
        ZStack {
            // Gradient fill area
            BezierAreaShape(
                dataPoints: dataPoints,
                bounds: bounds,
                progress: animationProgress
            )
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Data gap styling (dashed line segments for interpolated data)
            dataGapOverlay(in: size)
            
            // Main line
            BezierLineShape(
                dataPoints: dataPoints,
                bounds: bounds,
                progress: animationProgress
            )
            .stroke(
                lineColor,
                style: StrokeStyle(
                    lineWidth: 2.5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            
            // End point indicator
            if animationProgress >= 1, let lastPoint = dataPoints.last {
                endPointIndicator(for: lastPoint, in: size)
            }
        }
    }
    
    // MARK: - Data Gap Overlay
    
    /// Shows dashed line styling for interpolated (data gap) segments
    private func dataGapOverlay(in size: CGSize) -> some View {
        BezierLineShape(
            dataPoints: dataPoints,
            bounds: bounds,
            progress: animationProgress,
            interpolatedOnly: true
        )
        .stroke(
            lineColor.opacity(0.5),
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round,
                dash: [4, 4]
            )
        )
    }
    
    // MARK: - Single Point View
    
    private func singlePointView(in size: CGSize) -> some View {
        let point = dataPoints.first!
        let x = size.width / 2
        let y = size.height / 2
        
        return ZStack {
            // Pulsing ring
            Circle()
                .fill(lineColor.opacity(0.15))
                .frame(width: 40, height: 40)
            
            // Outer glow
            Circle()
                .fill(lineColor.opacity(0.3))
                .frame(width: 20, height: 20)
            
            // Inner dot
            Circle()
                .fill(lineColor)
                .frame(width: 10, height: 10)
            
            // Label
            VStack(spacing: 4) {
                Text("Starting Point")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .offset(y: 36)
        }
        .position(x: x, y: y)
        .opacity(animationProgress)
    }
    
    // MARK: - End Point Indicator
    
    private func endPointIndicator(for point: PerformanceDataPoint, in size: CGSize) -> some View {
        let normalizedY = bounds.normalizedY(for: point.doubleValue)
        let x = size.width - 8
        let y = 8 + normalizedY * (size.height - 16)
        
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
        .position(x: x, y: y)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Scrub Indicator
    
    private func scrubIndicator(scrub: ChartScrubState, in size: CGSize) -> some View {
        let x = 8 + scrub.normalizedX * (size.width - 16)
        let y = 8 + scrub.normalizedY * (size.height - 16)
        
        return ZStack {
            // Vertical line
            Rectangle()
                .fill(Color(.label).opacity(0.3))
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .position(x: x, y: size.height / 2)
            
            // Crosshair dot
            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                
                Circle()
                    .fill(lineColor)
                    .frame(width: 12, height: 12)
            }
            .position(x: x, y: y)
        }
        .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: scrub)
    }
    
    // MARK: - Shimmer Overlay
    
    private var shimmerOverlay: some View {
        ShimmerChartView()
            .opacity(0.6)
    }
    
    // MARK: - Scrub Gesture
    
    private func scrubGesture(in size: CGSize) -> some Gesture {
        LongPressGesture(minimumDuration: 0.15)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    // Long press recognized - prepare for scrubbing
                    isLongPressing = true
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                case .second(true, let drag):
                    // Dragging during long press
                    if let drag = drag {
                        let normalizedX = (drag.location.x - 8) / (size.width - 16)
                        onScrubUpdate(normalizedX, CGRect(origin: .zero, size: size))
                    }
                    
                default:
                    break
                }
            }
            .onEnded { _ in
                isLongPressing = false
                onScrubEnd()
            }
    }
}

// MARK: - Bézier Line Shape

/// Custom shape that draws a smooth Bézier curve through data points
/// UX: On-device smoothing for premium, organic feel
struct BezierLineShape: Shape {
    let dataPoints: [PerformanceDataPoint]
    let bounds: ChartBounds
    var progress: CGFloat
    var interpolatedOnly: Bool
    
    init(
        dataPoints: [PerformanceDataPoint],
        bounds: ChartBounds,
        progress: CGFloat,
        interpolatedOnly: Bool = false
    ) {
        self.dataPoints = dataPoints
        self.bounds = bounds
        self.progress = progress
        self.interpolatedOnly = interpolatedOnly
    }
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        guard dataPoints.count >= 2 else { return Path() }
        
        let padding: CGFloat = 8
        let width = rect.width - 2 * padding
        let height = rect.height - 2 * padding
        
        // Convert data points to screen coordinates
        let points: [CGPoint] = dataPoints.enumerated().map { index, point in
            let x = padding + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * width
            let y = padding + bounds.normalizedY(for: point.doubleValue) * height
            return CGPoint(x: x, y: y)
        }
        
        var path = Path()
        
        if interpolatedOnly {
            // Only draw segments where data is interpolated
            drawInterpolatedSegments(points: points, in: &path)
        } else {
            // Draw full curve
            drawSmoothCurve(points: points, progress: progress, in: &path)
        }
        
        return path
    }
    
    /// Draws segments only where data points are interpolated (data gaps)
    private func drawInterpolatedSegments(points: [CGPoint], in path: inout Path) {
        for i in 0..<dataPoints.count - 1 {
            let current = dataPoints[i]
            let next = dataPoints[i + 1]
            
            // Draw if either point is interpolated
            if current.isInterpolated || next.isInterpolated {
                path.move(to: points[i])
                
                // Simple control points for smooth connection
                let controlDistance = (points[i + 1].x - points[i].x) / 3
                let control1 = CGPoint(x: points[i].x + controlDistance, y: points[i].y)
                let control2 = CGPoint(x: points[i + 1].x - controlDistance, y: points[i + 1].y)
                
                path.addCurve(to: points[i + 1], control1: control1, control2: control2)
            }
        }
    }
    
    /// Draws a smooth Bézier curve through all points
    private func drawSmoothCurve(points: [CGPoint], progress: CGFloat, in path: inout Path) {
        guard points.count >= 2 else { return }
        
        path.move(to: points[0])
        
        // Calculate total path length for progress animation
        let totalLength = calculateTotalLength(points: points)
        let targetLength = totalLength * Double(progress)
        var currentLength: Double = 0
        
        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]
            
            // Catmull-Rom to Bézier conversion for smooth curves
            let tension: CGFloat = 0.3
            
            let control1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension,
                y: p1.y + (p2.y - p0.y) * tension
            )
            
            let control2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension,
                y: p2.y - (p3.y - p1.y) * tension
            )
            
            let segmentLength = distance(from: p1, to: p2)
            
            if currentLength + segmentLength <= targetLength {
                path.addCurve(to: p2, control1: control1, control2: control2)
                currentLength += segmentLength
            } else {
                // Partial segment
                let remainingLength = targetLength - currentLength
                let fraction = CGFloat(remainingLength / segmentLength)
                
                // Approximate partial curve point
                let partialPoint = interpolateBezier(
                    p0: p1, p1: control1, p2: control2, p3: p2, t: fraction
                )
                path.addLine(to: partialPoint)
                break
            }
        }
    }
    
    private func calculateTotalLength(points: [CGPoint]) -> Double {
        var total: Double = 0
        for i in 1..<points.count {
            total += distance(from: points[i - 1], to: points[i])
        }
        return total
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(Double(dx * dx + dy * dy))
    }
    
    private func interpolateBezier(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
        let t2 = t * t
        let t3 = t2 * t
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        
        return CGPoint(
            x: mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x,
            y: mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y
        )
    }
}

// MARK: - Bézier Area Shape

/// Fills the area under the Bézier curve
struct BezierAreaShape: Shape {
    let dataPoints: [PerformanceDataPoint]
    let bounds: ChartBounds
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        guard dataPoints.count >= 2 else { return Path() }
        
        let padding: CGFloat = 8
        let width = rect.width - 2 * padding
        let height = rect.height - 2 * padding
        
        let points: [CGPoint] = dataPoints.enumerated().map { index, point in
            let x = padding + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * width
            let y = padding + bounds.normalizedY(for: point.doubleValue) * height
            return CGPoint(x: x, y: y)
        }
        
        var path = Path()
        
        // Draw line path first
        path.move(to: points[0])
        
        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]
            
            let tension: CGFloat = 0.3
            
            let control1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension,
                y: p1.y + (p2.y - p0.y) * tension
            )
            
            let control2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension,
                y: p2.y - (p3.y - p1.y) * tension
            )
            
            path.addCurve(to: p2, control1: control1, control2: control2)
        }
        
        // Close path to bottom
        path.addLine(to: CGPoint(x: points.last?.x ?? rect.width - padding, y: rect.height))
        path.addLine(to: CGPoint(x: points.first?.x ?? padding, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Shimmer Chart View

/// Loading state shimmer animation
struct ShimmerChartView: View {
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        GeometryReader { geometry in
            // Fake chart line
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let padding: CGFloat = 8
                
                path.move(to: CGPoint(x: padding, y: height * 0.6))
                path.addQuadCurve(
                    to: CGPoint(x: width * 0.3, y: height * 0.4),
                    control: CGPoint(x: width * 0.15, y: height * 0.5)
                )
                path.addQuadCurve(
                    to: CGPoint(x: width * 0.6, y: height * 0.5),
                    control: CGPoint(x: width * 0.45, y: height * 0.3)
                )
                path.addQuadCurve(
                    to: CGPoint(x: width - padding, y: height * 0.35),
                    control: CGPoint(x: width * 0.8, y: height * 0.55)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5)
                    ],
                    startPoint: UnitPoint(x: shimmerOffset, y: 0.5),
                    endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.3
            }
        }
    }
}

// MARK: - Preview

#Preview("Interactive Chart - Positive") {
    let viewModel = PerformanceViewModel.preview
    
    return VStack {
        InteractivePerformanceChart(
            dataPoints: viewModel.dataPoints,
            bounds: viewModel.yAxisScale,
            isPositive: true,
            animationProgress: 1,
            scrubState: nil,
            isTransitioning: false,
            onScrubUpdate: { _, _ in },
            onScrubEnd: { }
        )
        .frame(height: 200)
        .padding()
    }
    .background(Color(.systemBackground))
}

#Preview("Interactive Chart - Negative") {
    VStack {
        InteractivePerformanceChart(
            dataPoints: PerformanceSummary.sample(for: .month).dataPoints,
            bounds: ChartBounds(dataPoints: PerformanceSummary.sample(for: .month).dataPoints),
            isPositive: false,
            animationProgress: 1,
            scrubState: nil,
            isTransitioning: false,
            onScrubUpdate: { _, _ in },
            onScrubEnd: { }
        )
        .frame(height: 200)
        .padding()
    }
    .background(Color(.systemBackground))
}

#Preview("Chart - Shimmer Loading") {
    VStack {
        InteractivePerformanceChart(
            dataPoints: [],
            bounds: ChartBounds(dataPoints: []),
            isPositive: true,
            animationProgress: 0,
            scrubState: nil,
            isTransitioning: true,
            onScrubUpdate: { _, _ in },
            onScrubEnd: { }
        )
        .frame(height: 200)
        .padding()
    }
    .background(Color(.systemBackground))
}

#Preview("Chart - Single Point") {
    let summary = PerformanceSummary.singlePoint
    
    return VStack {
        InteractivePerformanceChart(
            dataPoints: summary.dataPoints,
            bounds: ChartBounds(dataPoints: summary.dataPoints),
            isPositive: true,
            animationProgress: 1,
            scrubState: nil,
            isTransitioning: false,
            onScrubUpdate: { _, _ in },
            onScrubEnd: { }
        )
        .frame(height: 200)
        .padding()
    }
    .background(Color(.systemBackground))
}
