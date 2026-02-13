import SwiftUI

/// Lightweight draggable bottom sheet (no external deps).
/// Collapsed by default; expands to show full transaction list.
struct AccountDetailsBottomSheet: View {
    @Binding var isExpanded: Bool
    
    let account: PortfolioAccount
    let transactions: [Transaction]
    let isPrivacyMode: Bool
    let onPerformanceTap: () -> Void
    
    private let minHeight: CGFloat = 220
    
    @GestureState private var dragTranslation: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            let maxHeight = min(proxy.size.height * 0.72, 620)
            let safeBottom = proxy.safeAreaInsets.bottom
            let collapsedHeight = minHeight + safeBottom
            let maxOffset = max(0, maxHeight - collapsedHeight)
            
            let baseOffset = isExpanded ? 0 : maxOffset
            let proposedOffset = baseOffset + dragTranslation
            let clampedOffset = min(max(proposedOffset, 0), maxOffset)
            
            VStack(spacing: 0) {
                sheetHandle(maxOffset: maxOffset)
                
                VStack(alignment: .leading, spacing: 14) {
                    header
                    
                    PerformanceCTAView(onTap: onPerformanceTap)
                        .accessibilityLabel("Open performance for this account")
                    
                    Divider()
                        .background(DesignSystem.Colors.separator)
                    
                    transactionsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12 + safeBottom)
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: maxHeight, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DesignSystem.Colors.surfacePrimary)
                    .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .offset(y: clampedOffset)
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: isExpanded)
            .accessibilityElement(children: .contain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func sheetHandle(maxOffset: CGFloat) -> some View {
        let dragGesture = DragGesture(minimumDistance: 3, coordinateSpace: .global)
            .updating($dragTranslation) { value, state, _ in
                // Clamp drag so we don't overshoot too far.
                let proposed = value.translation.height
                state = min(max(proposed, -maxOffset), maxOffset)
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let travel = value.translation.height
                
                // Favor intent: fast swipe up expands, fast swipe down collapses.
                if velocity < -60 {
                    isExpanded = true
                    return
                }
                if velocity > 60 {
                    isExpanded = false
                    return
                }
                
                // Otherwise snap based on distance.
                if travel < -max(24, maxOffset * 0.20) {
                    isExpanded = true
                } else if travel > max(24, maxOffset * 0.20) {
                    isExpanded = false
                }
            }
        
        return VStack(spacing: 8) {
            Capsule()
                .fill(DesignSystem.Colors.separator.opacity(0.85))
                .frame(width: 44, height: 5)
                .padding(.top, 10)
            
            // Make collapsed sheet tappable to expand (keeps UX quick).
            Color.clear
                .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isExpanded {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                    isExpanded = true
                }
            }
        }
        .gesture(dragGesture)
        .accessibilityLabel(isExpanded ? "Collapse details" : "Expand details")
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Net Worth")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)
            
            Text(isPrivacyMode ? "••••••" : account.formattedBalance)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isExpanded {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                    isExpanded = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Transactions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if transactions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 26))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("No recent transactions")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                if isExpanded {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(transactions.enumerated()), id: \.element.id) { index, tx in
                                TransactionRow(transaction: tx, isPrivacyMode: isPrivacyMode)
                                if index < transactions.count - 1 {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .frame(maxHeight: 320)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(transactions.prefix(3).enumerated()), id: \.element.id) { index, tx in
                            TransactionRow(transaction: tx, isPrivacyMode: isPrivacyMode)
                            if index < min(transactions.count, 3) - 1 {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

#Preview("Bottom Sheet") {
    ZStack(alignment: .bottom) {
        DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()
        AccountDetailsBottomSheet(
            isExpanded: .constant(false),
            account: PortfolioAccount.sampleAccounts[0],
            transactions: Transaction.sampleTransactions,
            isPrivacyMode: false,
            onPerformanceTap: {}
        )
    }
}

