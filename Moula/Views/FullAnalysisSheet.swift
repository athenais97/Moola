import SwiftUI

/// Full analysis sheet opened from the home (Pulse) screen.
/// Shows progress context + detailed metrics, previously surfaced in `InsightsView`.
struct FullAnalysisSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe: Timeframe = .year
    @Namespace private var timeframeAnimation
    
    enum Timeframe: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case quarter = "3M"
        case year = "1Y"
        case all = "All"
    }
    
    var body: some View {
        ZStack {
            (Color(hex: "FBFBFB") ?? DesignSystem.Colors.backgroundPrimary)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    topBar
                    
                    heroCard
                    
                    detailedMetricsSection
                }
                // The sheet header was feeling visually "crushed" near the top.
                // Add breathing room so it sits comfortably under the notch.
                .padding(.top, 18)
                .padding(.horizontal, 18) // matches Figma sheet padding
                .padding(.bottom, 24)
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Spacer(minLength: 0)
            
            Text("View Analysis")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(.black)
                .accessibilityAddTraits(.isHeader)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var heroCard: some View {
        VStack(spacing: 14) {
            timeframePicker
                .padding(.top, 11)
            
            CandlestickChart(
                candles: CandlestickChart.sample,
                monthLabels: ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"]
            )
            .frame(height: 215)
            .padding(.horizontal, 12)
            
            onTrackInline
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(DesignSystem.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: DesignSystem.Shadow.softColor,
            radius: DesignSystem.Shadow.softRadius,
            x: DesignSystem.Shadow.softX,
            y: DesignSystem.Shadow.softY
        )
    }
    
    private var timeframePicker: some View {
        HStack(spacing: 4) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                let isSelected = selectedTimeframe == timeframe
                
                Button {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    Text(timeframe.rawValue)
                        .font(DesignSystem.Typography.plusJakarta(isSelected ? .semibold : .medium, size: 14))
                        .foregroundColor(isSelected ? .white : DesignSystem.Colors.inkSecondary.opacity(0.7))
                        .frame(width: 62, height: 38)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "BDA0FF") ?? DesignSystem.Colors.focusBorder,
                                                Color(hex: "94CCFF") ?? DesignSystem.Colors.accent
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .matchedGeometryEffect(id: "timeframe", in: timeframeAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(timeframe.rawValue)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .shadow(
                    color: DesignSystem.Shadow.softColor,
                    radius: DesignSystem.Shadow.softRadius,
                    x: DesignSystem.Shadow.softX,
                    y: DesignSystem.Shadow.softY
                )
        )
        .padding(.horizontal, 12)
    }
    
    private var onTrackInline: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("You’re on track !")
                    .font(DesignSystem.Typography.plusJakarta(.bold, size: 16))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Your portfolio grew +5.3% this month, outpacing the market average of +2.1%")
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.inkSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
            
            SparklineView(
                dataPoints: [12, 10, 11, 9, 8, 9, 10, 11, 10, 12, 13, 14].map { Decimal($0) },
                isPositive: true,
                height: 49,
                showsEndPoint: false
            )
            .frame(width: 92)
        }
    }
    
    private var detailedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Metrics")
                .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
                .foregroundColor(DesignSystem.Colors.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                MetricRowCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Total Gains",
                    value: "+$2,076.53",
                    badge: .init(text: "+11.7%", style: .positive),
                    subtitle: "You’ve grown 11,7% since you started"
                )
                
                MetricRowCard(
                    icon: "calendar",
                    title: "Monthly Return",
                    value: "+3.2%",
                    badge: .init(text: "More than market", style: .positive),
                    subtitle: "Your portfolio grew +3.2% this month,\noutpacing the market average of +2.1%"
                )
                
                MetricRowCard(
                    icon: "calendar",
                    title: "Dividends YTD",
                    value: "$156.78",
                    badge: .init(text: "+3.3%", style: .positive),
                    subtitle: "You’ve grown 11,7% since you started"
                )
                
                MetricRowCard(
                    icon: "hexagon",
                    title: "Risk Level",
                    value: "Moderate",
                    badge: nil,
                    subtitle: "Balanced for steady growth"
                )
            }
        }
    }
}

// MARK: - Components (sheet-local)

private struct MetricRowCard: View {
    struct Badge: Equatable {
        enum Style: Equatable {
            case positive
            case neutral
        }
        
        let text: String
        let style: Style
    }
    
    let icon: String
    let title: String
    let value: String
    let badge: Badge?
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DesignSystem.Colors.accent.opacity(0.10))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DesignSystem.Colors.accent.opacity(0.18), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: 16))
                    .foregroundColor(DesignSystem.Colors.ink)
                
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(value)
                        .font(DesignSystem.Typography.plusJakarta(.bold, size: 24))
                        .foregroundColor(DesignSystem.Colors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    if let badge {
                        MetricBadge(text: badge.text, style: badge.style)
                    }
                    
                    Spacer(minLength: 0)
                }
                
                Text(subtitle)
                    .font(DesignSystem.Typography.plusJakarta(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.inkSecondary.opacity(0.8))
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .surfaceCard(radius: 18)
    }
}

private struct MetricBadge: View {
    let text: String
    let style: MetricRowCard.Badge.Style
    
    var body: some View {
        HStack(spacing: 6) {
            if style == .positive {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(foreground)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
    
    private var foreground: Color {
        switch style {
        case .positive:
            return DesignSystem.Colors.positive
        case .neutral:
            return DesignSystem.Colors.inkSecondary
        }
    }
    
    private var background: Color {
        switch style {
        case .positive:
            return Color(hex: "E0FAF0") ?? DesignSystem.Colors.positiveBackground.opacity(0.85)
        case .neutral:
            return (Color(hex: "E2E2E2") ?? Color(uiColor: .systemGray5)).opacity(0.9)
        }
    }
}

private struct CandlestickChart: View {
    struct Candle: Identifiable {
        let id = UUID()
        let open: CGFloat
        let close: CGFloat
        let high: CGFloat
        let low: CGFloat
    }
    
    let candles: [Candle]
    let monthLabels: [String]
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let padding: CGFloat = 10
            let plotRect = CGRect(x: padding, y: padding, width: size.width - padding * 2, height: size.height - padding * 2 - 18)
            let minY = candles.map(\.low).min() ?? 0
            let maxY = candles.map(\.high).max() ?? 1
            let range = max(1, maxY - minY)
            let candleWidth = max(6, plotRect.width / CGFloat(max(1, candles.count)) * 0.6)
            let spacing = plotRect.width / CGFloat(max(1, candles.count))
            
            ZStack {
                // Grid
                VStack(spacing: 0) {
                    ForEach(0..<4) { idx in
                        if idx > 0 {
                            Rectangle()
                                .fill(DesignSystem.Colors.separator.opacity(0.35))
                                .frame(height: 0.5)
                        }
                        Spacer()
                    }
                }
                .frame(width: plotRect.width, height: plotRect.height)
                .position(x: plotRect.midX, y: plotRect.midY)
                
                // Candles
                ForEach(Array(candles.enumerated()), id: \.offset) { index, candle in
                    let x = plotRect.minX + spacing * (CGFloat(index) + 0.5)
                    let openY = y(candle.open, in: plotRect, min: minY, range: range)
                    let closeY = y(candle.close, in: plotRect, min: minY, range: range)
                    let highY = y(candle.high, in: plotRect, min: minY, range: range)
                    let lowY = y(candle.low, in: plotRect, min: minY, range: range)
                    
                    let isUp = candle.close >= candle.open
                    let color = isUp ? DesignSystem.Colors.positive : DesignSystem.Colors.negative
                    
                    // Wick
                    Rectangle()
                        .fill(color.opacity(0.85))
                        .frame(width: 1.5, height: max(2, lowY - highY))
                        .position(x: x, y: (highY + lowY) / 2)
                    
                    // Body
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(color)
                        .frame(width: candleWidth, height: max(6, abs(closeY - openY)))
                        .position(x: x, y: (openY + closeY) / 2)
                }
                
                // X labels
                HStack {
                    ForEach(monthLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.inkSecondary.opacity(0.7))
                        if label != monthLabels.last { Spacer() }
                    }
                }
                .frame(width: plotRect.width)
                .position(x: plotRect.midX, y: plotRect.maxY + 14)
            }
        }
    }
    
    private func y(_ value: CGFloat, in rect: CGRect, min: CGFloat, range: CGFloat) -> CGFloat {
        let normalized = (value - min) / range
        return rect.maxY - normalized * rect.height
    }
    
    /// Static sample to match the look of the design.
    static let sample: [Candle] = [
        .init(open: 52, close: 54, high: 56, low: 50),
        .init(open: 54, close: 58, high: 60, low: 53),
        .init(open: 58, close: 62, high: 64, low: 57),
        .init(open: 62, close: 59, high: 63, low: 58),
        .init(open: 59, close: 61, high: 62, low: 57),
        .init(open: 61, close: 57, high: 62, low: 55),
        .init(open: 57, close: 53, high: 58, low: 51),
        .init(open: 53, close: 49, high: 54, low: 47),
        .init(open: 49, close: 46, high: 50, low: 44),
        .init(open: 46, close: 44, high: 47, low: 42),
        .init(open: 44, close: 45, high: 46, low: 43),
        .init(open: 45, close: 47, high: 49, low: 44),
        .init(open: 47, close: 50, high: 52, low: 46),
        .init(open: 50, close: 53, high: 54, low: 49),
        .init(open: 53, close: 55, high: 57, low: 52),
        .init(open: 55, close: 52, high: 56, low: 50),
        .init(open: 52, close: 54, high: 56, low: 51),
        .init(open: 54, close: 57, high: 59, low: 53),
        .init(open: 57, close: 60, high: 62, low: 56),
        .init(open: 60, close: 58, high: 61, low: 57),
        .init(open: 58, close: 61, high: 63, low: 57),
        .init(open: 61, close: 59, high: 62, low: 58)
    ]
}

#Preview("Full Analysis Sheet") {
    FullAnalysisSheet()
}

