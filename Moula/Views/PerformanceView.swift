import SwiftUI

/// Performance Evolution View — Time-series tracking of portfolio performance
///
/// UX Intent:
/// - Answer "How has my portfolio grown/shrunk over time?"
/// - Interactive, premium charting experience
/// - Fluid scrubbing with haptic feedback
///
/// Foundation Compliance:
/// - One clear intent: Understand performance evolution
/// - Mobile-first with thumb-friendly controls
/// - Scannable in seconds with clear visual hierarchy
/// - Fast, fluid, and intentional interactions
/// - Privacy: Data cleared from memory on dismiss
///
/// Design Rationale:
/// Line Chart vs Bar Chart: A line chart was chosen over a bar chart because
/// performance data represents continuous change over time. The line emphasizes
/// the flow and trajectory of value, making trends immediately visible. Bar charts
/// are better suited for discrete comparisons (e.g., monthly totals), while line
/// charts communicate the narrative of "how did I get here?" which is the core
/// question this view answers.
struct PerformanceView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PerformanceViewModel()
    
    @Environment(\.dismiss) private var dismiss
    
    /// Optional context passed from the Home dashboard card (e.g. "S&P 500 (ESE)").
    /// Used only to tailor the chatbot CTA copy.
    let contextTitle: String?
    
    /// Optional account context for scoped performance (e.g. from Accounts Cards).
    /// When nil, the view behaves as before (overall portfolio).
    let accountId: UUID?
    
    @State private var showPulseAssistant: Bool = false
    
    init(contextTitle: String? = nil, accountId: UUID? = nil) {
        self.contextTitle = contextTitle
        self.accountId = accountId
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        // Summary header with delta
                        summaryHeader
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                        
                        // Interactive chart
                        chartSection
                            .padding(.top, 24)
                            .padding(.horizontal, 16)
                        
                        // Timeframe selector
                        timeframeSelector
                            .padding(.top, 20)
                            .padding(.horizontal, 16)
                        
                        // Insight section - plain-language explanation
                        // Placed between timeframe and key movers to create a logical
                        // flow: see the change → understand the context → see the details
                        if viewModel.hasData && !viewModel.isSinglePoint {
                            insightSection
                                .padding(.top, 24)
                                .padding(.horizontal, 16)
                        }
                        
                        // Chatbot CTA (replaces Key movers)
                        askPulseSection
                            .padding(.top, 24)
                            .padding(.horizontal, 16)
                        
                        // Bottom spacing
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 16)
                }
                .refreshable {
                    await viewModel.refresh()
                }
                
                // Loading overlay for initial load
                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    loadingOverlay
                }
                
                // Empty state
                if viewModel.hasLoadedOnce && !viewModel.hasData {
                    emptyStateOverlay
                }
            }
            .navigationTitle("Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
        }
        .task {
            await viewModel.fetchPerformance(accountId: accountId)
        }
        .onDisappear {
            // Privacy requirement: Clear chart data from memory
            viewModel.clearSensitiveData()
        }
        .fullScreenCover(isPresented: $showPulseAssistant) {
            PulseAssistantView(context: contextTitle ?? "your portfolio")
        }
    }
    
    // MARK: - Summary Header
    
    /// Header now includes contextLabel for improved interpretability
    /// UX Enhancement: Users can immediately understand whether their performance
    /// is good, bad, or neutral through the plain-language context label
    private var summaryHeader: some View {
        PerformanceDeltaHeader(
            balance: viewModel.displayValue,
            absoluteChange: viewModel.summary.formattedAbsoluteChange,
            percentageChange: viewModel.summary.formattedPercentageChange,
            isPositive: viewModel.summary.isPositive,
            scrubDate: viewModel.displayDateLabel,
            showDelta: viewModel.showDelta,
            contextLabel: viewModel.showDelta ? viewModel.summary.contextLabel : nil
        )
    }
    
    // MARK: - Insight Section
    
    /// Plain-language explanation of what changed and why
    /// UX Intent: Answers "What changed?" and "Why did it change?" without
    /// requiring users to interpret numbers themselves
    private var insightSection: some View {
        PerformanceInsightCard(
            insightSummary: viewModel.summary.insightSummary,
            driverExplanation: viewModel.summary.driverExplanation,
            isPositive: viewModel.summary.isPositive
        )
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(spacing: 0) {
            // Chart container
            InteractivePerformanceChart(
                dataPoints: viewModel.dataPoints,
                bounds: viewModel.yAxisScale,
                isPositive: viewModel.summary.isPositive,
                animationProgress: viewModel.chartAnimationProgress,
                scrubState: viewModel.scrubState,
                isTransitioning: viewModel.isTransitioning,
                onScrubUpdate: { normalizedX, bounds in
                    viewModel.updateScrub(at: normalizedX, in: bounds)
                },
                onScrubEnd: {
                    viewModel.endScrub()
                }
            )
            .frame(height: 220)
            
            // Sparse X-axis labels (minimalist per requirements)
            xAxisLabels
                .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - X-Axis Labels
    
    /// Sparse labels to reduce cognitive load
    private var xAxisLabels: some View {
        HStack {
            if let first = viewModel.dataPoints.first {
                Text(first.formattedDate(for: viewModel.selectedTimeframe))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let last = viewModel.dataPoints.last {
                Text(last.formattedDate(for: viewModel.selectedTimeframe))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Timeframe Selector
    
    private var timeframeSelector: some View {
        TimeframeSegmentedControl(selectedTimeframe: $viewModel.selectedTimeframe)
    }
    
    // MARK: - Ask Pulse Section
    
    private var askPulseSection: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.7)
            showPulseAssistant = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.purple.opacity(0.10))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ask the chatbot")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Get a quick explanation and next steps for \(contextTitle ?? "your portfolio").")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask the chatbot about \(contextTitle ?? "your portfolio")")
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        VStack(spacing: 20) {
            // Skeleton chart
            SkeletonChartView()
                .frame(height: 200)
                .padding(.horizontal, 32)
            
            // Loading indicator
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.9)
                
                Text("Analyzing performance...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).opacity(0.95))
    }
    
    // MARK: - Empty State
    
    private var emptyStateOverlay: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.purple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.accentColor)
            }
            
            // Message
            VStack(spacing: 8) {
                Text("No Performance Data")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Connect accounts to start tracking\nyour portfolio performance over time.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Skeleton Chart View

/// Loading skeleton for the chart
private struct SkeletonChartView: View {
    @State private var shimmerOffset: CGFloat = -0.5
    
    var body: some View {
        VStack(spacing: 16) {
            // Skeleton header
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 32)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 20)
            }
            
            // Skeleton chart
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height * 0.6))
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.25, y: height * 0.4),
                        control: CGPoint(x: width * 0.12, y: height * 0.5)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.5, y: height * 0.5),
                        control: CGPoint(x: width * 0.37, y: height * 0.3)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.75, y: height * 0.35),
                        control: CGPoint(x: width * 0.62, y: height * 0.55)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: width, y: height * 0.4),
                        control: CGPoint(x: width * 0.87, y: height * 0.25)
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
                        endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0.5)
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
            }
            .frame(height: 100)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
        }
    }
}

// MARK: - Preview

#Preview("Performance View") {
    let appState = AppState()
    appState.currentUser = UserModel(
        name: "Sarah Johnson",
        age: 32,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: "",
        membershipLevel: .premium
    )
    
    return PerformanceView()
        .environmentObject(appState)
}

#Preview("Performance View - Dark Mode") {
    let appState = AppState()
    appState.currentUser = UserModel(
        name: "Sarah Johnson",
        age: 32,
        email: "sarah@example.com",
        isEmailVerified: true,
        pinHash: "",
        membershipLevel: .premium
    )
    
    return PerformanceView()
        .environmentObject(appState)
        .preferredColorScheme(.dark)
}

#Preview("Performance View - Loading") {
    let appState = AppState()
    
    return ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        SkeletonChartView()
            .padding(32)
    }
}
