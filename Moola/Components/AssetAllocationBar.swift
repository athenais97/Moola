import SwiftUI

/// Horizontal segmented bar showing asset allocation
/// UX Intent: Quickly communicate portfolio distribution without overwhelming detail
/// Design Decision: Segmented bar chosen over pie chart because:
/// - Simpler to read at a glance in a mobile context
/// - Horizontal orientation fits natural thumb movement and screen width
/// - Less visual noise than multi-color pie chart
/// - Easier to compare relative sizes of segments
/// - Follows foundation principle: "scannable in a few seconds"
struct AssetAllocationBar: View {
    let allocation: AssetAllocation
    let isPrivacyMode: Bool
    let height: CGFloat
    
    @State private var animationProgress: CGFloat = 0
    
    init(allocation: AssetAllocation, isPrivacyMode: Bool = false, height: CGFloat = 8) {
        self.allocation = allocation
        self.isPrivacyMode = isPrivacyMode
        self.height = height
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // The segmented bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(Array(allocation.activeCategories.enumerated()), id: \.element.category) { index, item in
                        segmentView(
                            category: item.category,
                            percentage: item.percentage,
                            totalWidth: geometry.size.width,
                            isFirst: index == 0,
                            isLast: index == allocation.activeCategories.count - 1
                        )
                    }
                }
            }
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))
            )
            .clipShape(RoundedRectangle(cornerRadius: height / 2))
            
            // Legend
            if !isPrivacyMode {
                legendView
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animationProgress = 1
            }
        }
    }
    
    // MARK: - Segment View
    
    private func segmentView(
        category: AssetCategory,
        percentage: Double,
        totalWidth: CGFloat,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        let effectivePercentage = percentage * Double(animationProgress)
        
        return category.color
            .frame(width: max(0, totalWidth * CGFloat(effectivePercentage) - (isFirst || isLast ? 1 : 2)))
            .animation(.easeOut(duration: 0.5), value: animationProgress)
    }
    
    // MARK: - Legend View
    
    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(allocation.activeCategories, id: \.category) { item in
                legendItem(
                    category: item.category,
                    percentage: item.percentage,
                    amount: item.amount
                )
            }
            
            Spacer()
        }
    }
    
    private func legendItem(category: AssetCategory, percentage: Double, amount: Decimal) -> some View {
        HStack(spacing: 6) {
            // Color indicator
            Circle()
                .fill(category.color)
                .frame(width: 8, height: 8)
            
            // Category name and percentage
            VStack(alignment: .leading, spacing: 0) {
                Text(category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(formatPercentage(percentage))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
}

// MARK: - Compact Variant

/// A more compact version without legend, for tight spaces
struct AssetAllocationBarCompact: View {
    let allocation: AssetAllocation
    let height: CGFloat
    
    @State private var animationProgress: CGFloat = 0
    
    init(allocation: AssetAllocation, height: CGFloat = 6) {
        self.allocation = allocation
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1.5) {
                ForEach(Array(allocation.activeCategories.enumerated()), id: \.element.category) { index, item in
                    let effectivePercentage = item.percentage * Double(animationProgress)
                    
                    item.category.color
                        .frame(width: max(0, geometry.size.width * CGFloat(effectivePercentage) - 1.5))
                }
            }
        }
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: height / 2)
                .fill(Color(.systemGray5))
        )
        .clipShape(RoundedRectangle(cornerRadius: height / 2))
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Preview

#Preview("Asset Allocation Bar") {
    VStack(spacing: 32) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Asset Allocation")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            AssetAllocationBar(
                allocation: .sample,
                height: 10
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Compact Version")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            AssetAllocationBarCompact(
                allocation: .sample,
                height: 6
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Asset Allocation - Different Distributions") {
    VStack(spacing: 24) {
        // Mostly cash
        VStack(alignment: .leading, spacing: 8) {
            Text("Conservative (Mostly Cash)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            AssetAllocationBar(
                allocation: AssetAllocation(cash: 80000, stocks: 15000, crypto: 5000, other: 0),
                height: 10
            )
        }
        
        // Mostly stocks
        VStack(alignment: .leading, spacing: 8) {
            Text("Growth (Mostly Stocks)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            AssetAllocationBar(
                allocation: AssetAllocation(cash: 10000, stocks: 75000, crypto: 10000, other: 5000),
                height: 10
            )
        }
        
        // Balanced
        VStack(alignment: .leading, spacing: 8) {
            Text("Balanced")
                .font(.caption)
                .foregroundColor(.secondary)
            
            AssetAllocationBar(
                allocation: AssetAllocation(cash: 30000, stocks: 40000, crypto: 20000, other: 10000),
                height: 10
            )
        }
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Asset Allocation - Privacy Mode") {
    VStack(alignment: .leading, spacing: 8) {
        Text("Privacy Mode Enabled")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
        
        AssetAllocationBar(
            allocation: .sample,
            isPrivacyMode: true,
            height: 10
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
