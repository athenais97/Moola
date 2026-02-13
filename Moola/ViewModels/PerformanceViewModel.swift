import Foundation
import Combine
import SwiftUI

/// ViewModel for Performance Analytics screen
/// UX Intent: Manage chart state with smooth transitions between timeframes
/// and responsive scrubbing interaction
///
/// Foundation Compliance:
/// - Fast, fluid experience with debounced fetches
/// - On-device smoothing for premium feel
/// - Privacy: Data cleared on view dismissal
final class PerformanceViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Currently selected timeframe
    @Published var selectedTimeframe: PerformanceTimeframe = .week {
        didSet {
            if oldValue != selectedTimeframe {
                Task { @MainActor in
                    onTimeframeChanged()
                }
            }
        }
    }
    
    /// Performance summary for current timeframe
    @Published private(set) var summary: PerformanceSummary = .empty
    
    /// Loading state for initial load
    @Published private(set) var isLoading: Bool = false
    
    /// Loading state for timeframe switch (shows shimmer, not full overlay)
    @Published private(set) var isTransitioning: Bool = false
    
    /// Whether initial data has loaded
    @Published private(set) var hasLoadedOnce: Bool = false
    
    /// Current scrub state (nil when not scrubbing)
    @Published var scrubState: ChartScrubState?
    
    /// Animation progress for chart path (0...1)
    @Published var chartAnimationProgress: CGFloat = 0
    
    /// Y-axis scale animation state
    @Published private(set) var yAxisScale: ChartBounds = ChartBounds(dataPoints: [])
    
    /// Error message if fetch fails
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Cache for loaded timeframe data
    private var dataCache: [PerformanceTimeframe: PerformanceSummary] = [:]

    /// Optional scoping for account-specific performance.
    /// When this changes, we reset cached data to avoid mixing contexts.
    private var scopedAccountId: UUID?
    
    /// Debounce for rapid timeframe switching
    private var timeframeDebounceTask: Task<Void, Never>?
    
    /// Last haptic index for scrubbing
    private var lastHapticIndex: Int = -1
    
    /// Haptic generator for scrubbing
    private let scrubHapticGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - Computed Properties
    
    /// Data points for chart display
    var dataPoints: [PerformanceDataPoint] {
        summary.dataPoints
    }
    
    /// Whether we have data to display
    var hasData: Bool {
        !summary.dataPoints.isEmpty
    }
    
    /// Whether we have only a single point (new account scenario)
    var isSinglePoint: Bool {
        summary.dataPoints.count == 1
    }
    
    /// Key movers for insight cards
    var keyMovers: [AccountPerformance] {
        summary.keyMovers
    }
    
    /// Display value - either scrub point or current balance
    var displayValue: String {
        if let scrub = scrubState {
            return scrub.formattedValue
        }
        return summary.formattedCurrentBalance
    }
    
    /// Display date label for scrubbing
    var displayDateLabel: String? {
        guard let scrub = scrubState else { return nil }
        return scrub.dataPoint.formattedDate(for: selectedTimeframe)
    }
    
    /// Delta display (hidden during scrub)
    var showDelta: Bool {
        scrubState == nil && hasData && !isSinglePoint
    }
    
    // MARK: - Initialization
    
    init() {
        scrubHapticGenerator.prepare()
    }
    
    // MARK: - Public Methods
    
    /// Fetches performance data
    /// Called when view appears
    @MainActor
    func fetchPerformance(accountId: UUID? = nil) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil

        // If scope changes (e.g. user switches accounts), reset cached data.
        if scopedAccountId != accountId {
            scopedAccountId = accountId
            dataCache.removeAll()
            summary = .empty
            scrubState = nil
            chartAnimationProgress = 0
            hasLoadedOnce = false
        }
        
        // Check cache first
        if let cached = dataCache[selectedTimeframe] {
            summary = cached
            yAxisScale = ChartBounds(dataPoints: cached.dataPoints)
            isLoading = false
            hasLoadedOnce = true
            animateChartIn()
            return
        }
        
        do {
            // Simulate API fetch (replace with actual implementation)
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6s

            // Connected demo data (single source of truth).
            let userKey = DemoDataStore.shared.currentUserKeyFromStoredUser() ?? "guest"
            DemoDataStore.shared.ensureSeededIfNeeded(for: userKey)
            let fetchedSummary = DemoDataStore.shared.performanceSummary(
                for: userKey,
                timeframe: selectedTimeframe,
                accountId: accountId
            )
            summary = fetchedSummary
            dataCache[selectedTimeframe] = fetchedSummary
            yAxisScale = ChartBounds(dataPoints: fetchedSummary.dataPoints)
            hasLoadedOnce = true
            
            animateChartIn()
            
        } catch {
            if !Task.isCancelled {
                errorMessage = "Unable to load performance data"
            }
        }
        
        isLoading = false
    }
    
    /// Called when timeframe changes
    @MainActor
    private func onTimeframeChanged() {
        // Cancel any pending debounce
        timeframeDebounceTask?.cancel()
        
        // Provide haptic feedback for selection
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        // Debounce rapid switching
        timeframeDebounceTask = Task { @MainActor in
            // Short delay to handle rapid taps
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            guard !Task.isCancelled else { return }
            
            await loadTimeframeData()
        }
    }
    
    /// Loads data for the current timeframe with transition animation
    @MainActor
    private func loadTimeframeData() async {
        isTransitioning = true
        chartAnimationProgress = 0
        
        // Check cache
        if let cached = dataCache[selectedTimeframe] {
            // Animate Y-axis smoothly
            withAnimation(.easeInOut(duration: 0.4)) {
                yAxisScale = ChartBounds(dataPoints: cached.dataPoints)
            }
            
            // Small delay for visual smoothness
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            summary = cached
            animateChartIn()
            isTransitioning = false
            return
        }
        
        do {
            // Fetch fresh data
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

            // Connected demo data (single source of truth). Keep account scope when present.
            let userKey = DemoDataStore.shared.currentUserKeyFromStoredUser() ?? "guest"
            DemoDataStore.shared.ensureSeededIfNeeded(for: userKey)
            let fetchedSummary = DemoDataStore.shared.performanceSummary(
                for: userKey,
                timeframe: selectedTimeframe,
                accountId: scopedAccountId
            )
            
            // Animate Y-axis smoothly per requirements
            withAnimation(.easeInOut(duration: 0.4)) {
                yAxisScale = ChartBounds(dataPoints: fetchedSummary.dataPoints)
            }
            
            summary = fetchedSummary
            dataCache[selectedTimeframe] = fetchedSummary
            
            animateChartIn()
            
        } catch {
            if !Task.isCancelled {
                errorMessage = "Unable to load data"
            }
        }
        
        isTransitioning = false
    }
    
    /// Animates the chart path drawing
    private func animateChartIn() {
        chartAnimationProgress = 0
        withAnimation(.easeOut(duration: 0.6)) {
            chartAnimationProgress = 1
        }
    }
    
    /// Updates scrub state from gesture
    /// Provides haptic tick when moving between data points
    func updateScrub(at normalizedX: CGFloat, in bounds: CGRect) {
        guard !dataPoints.isEmpty else { return }
        
        // Clamp to valid range
        let clampedX = max(0, min(1, normalizedX))
        
        // Find nearest data point
        let index = Int(round(clampedX * CGFloat(dataPoints.count - 1)))
        let safeIndex = max(0, min(dataPoints.count - 1, index))
        let point = dataPoints[safeIndex]
        
        // Calculate normalized Y
        let normalizedY = yAxisScale.normalizedY(for: point.doubleValue)
        
        // Haptic tick when moving to new point
        if safeIndex != lastHapticIndex {
            scrubHapticGenerator.selectionChanged()
            lastHapticIndex = safeIndex
        }
        
        scrubState = ChartScrubState(
            dataPoint: point,
            normalizedX: clampedX,
            normalizedY: normalizedY
        )
    }
    
    /// Ends scrubbing interaction
    func endScrub() {
        withAnimation(.easeOut(duration: 0.2)) {
            scrubState = nil
        }
        lastHapticIndex = -1
    }
    
    /// Clears sensitive data when view is dismissed
    /// Privacy requirement: Chart data cleared from memory
    func clearSensitiveData() {
        summary = .empty
        dataCache.removeAll()
        scrubState = nil
        chartAnimationProgress = 0
    }
    
    /// Refreshes data (pull-to-refresh or manual)
    @MainActor
    func refresh() async {
        // Clear cache for current timeframe to force refresh
        dataCache.removeValue(forKey: selectedTimeframe)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        await fetchPerformance(accountId: scopedAccountId)
        
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
    }
}

// MARK: - Preview Helpers

extension PerformanceViewModel {
    /// Creates a preview instance with sample data
    static var preview: PerformanceViewModel {
        let viewModel = PerformanceViewModel()
        viewModel.summary = .sample(for: .week)
        viewModel.yAxisScale = ChartBounds(dataPoints: viewModel.summary.dataPoints)
        viewModel.hasLoadedOnce = true
        viewModel.chartAnimationProgress = 1
        return viewModel
    }
    
    /// Preview with single data point
    static var previewSinglePoint: PerformanceViewModel {
        let viewModel = PerformanceViewModel()
        viewModel.summary = .singlePoint
        viewModel.yAxisScale = ChartBounds(dataPoints: viewModel.summary.dataPoints)
        viewModel.hasLoadedOnce = true
        viewModel.chartAnimationProgress = 1
        return viewModel
    }
    
    /// Preview in loading state
    static var previewLoading: PerformanceViewModel {
        let viewModel = PerformanceViewModel()
        viewModel.isLoading = true
        return viewModel
    }
    
    /// Preview in transitioning state (shimmer)
    static var previewTransitioning: PerformanceViewModel {
        let viewModel = PerformanceViewModel()
        viewModel.summary = .sample(for: .week)
        viewModel.hasLoadedOnce = true
        viewModel.isTransitioning = true
        return viewModel
    }
}
