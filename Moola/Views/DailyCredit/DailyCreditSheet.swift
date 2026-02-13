import SwiftUI

/// Daily Credit bottom sheet (presented from the home "Daily Credit" chip).
struct DailyCreditSheet: View {
    @EnvironmentObject private var appState: AppState
    
    let onClaim: () -> Void
    
    private let designWidth: CGFloat = 390
    private let designHeight: CGFloat = 844
    
    var body: some View {
        GeometryReader { proxy in
            let scale = min(1, proxy.size.width / designWidth)
            let scaledHeight = designHeight * scale
            
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color(hex: "94CCFF") ?? DesignSystem.Colors.accent.opacity(0.35),
                        Color(hex: "BDA0FF") ?? DesignSystem.Colors.focusBorder
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    DailyCreditCanvas(
                        isClaimEnabled: isClaimEnabled,
                        onClaim: {
                            onClaim()
                        }
                    )
                    .frame(width: designWidth, height: designHeight)
                    .scaleEffect(scale, anchor: .top)
                    .frame(maxWidth: .infinity, minHeight: scaledHeight, alignment: .top)
                }
                
                // Bottom-sheet handle bar (same as Infinite paywall).
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)
                    .accessibilityHidden(true)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var isStandardPlan: Bool {
        (appState.currentUser?.membershipLevel ?? .standard) == .standard
    }
    
    private var email: String {
        appState.currentUser?.email ?? "guest"
    }
    
    private var hasClaimedToday: Bool {
        guard isStandardPlan else { return false }
        return DailyCreditStore.hasClaimedToday(email: email)
    }
    
    private var creditsInStockToday: Int {
        guard isStandardPlan else { return 0 }
        return hasClaimedToday ? 0 : 1
    }
    
    private var isClaimEnabled: Bool {
        isStandardPlan && creditsInStockToday > 0
    }
}

private struct DailyCreditCanvas: View {
    let isClaimEnabled: Bool
    let onClaim: () -> Void
    
    private let size = CGSize(width: 390, height: 844)
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("DailyCreditBottomSheet")
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .accessibilityHidden(true)
            
            // Transparent tappable overlay on the "CLAIM IT" button zone in the PNG.
            Button(action: onClaim) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.001)) // ensures hit-testing while remaining invisible
                    .frame(width: 330, height: 70)
            }
            .buttonStyle(.plain)
            .disabled(!isClaimEnabled)
            .position(x: 195, y: 720)
            .accessibilityLabel("Claim daily credit")
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct DailyCreditTimelineCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "FBFBFB") ?? DesignSystem.Colors.backgroundCanvas)
                .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
            
            VStack(spacing: 10) {
                timelineRow(
                    title: "Today",
                    subtitle: "Earn 1 credit day-by-day"
                )
                timelineRow(
                    title: "During week",
                    subtitle: "Accumule credits..."
                )
                timelineRow(
                    title: "In 5 days",
                    subtitle: "Earn your first bunch !"
                )
                .padding(.top, 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    private func timelineRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "BDA0FF") ?? DesignSystem.Colors.focusBorder,
                        Color(hex: "94CCFF") ?? DesignSystem.Colors.accent.opacity(0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 55, height: 56)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DesignSystem.Typography.ibmPlexSansHebrew(.medium, size: 16))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.ibmPlexSansHebrew(.medium, size: 14))
                    .foregroundColor(DesignSystem.Colors.inkSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
        )
    }
}

private struct DailyCreditReadyPill: View {
    var body: some View {
        Text("Your Daily Credit Is Ready !")
            .font(DesignSystem.Typography.ibmPlexSansHebrew(.medium, size: 14))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
    }
}

private struct DailyCreditClaimCard: View {
    let creditsInStockToday: Int
    let isClaimEnabled: Bool
    let onClaim: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "DBCDFC") ?? DesignSystem.Colors.focusBorder.opacity(0.45),
                            Color(hex: "D3E8FC") ?? DesignSystem.Colors.accent.opacity(0.20)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
            
            VStack(spacing: 8) {
                Button(action: onClaim) {
                    Text("CLAIM IT")
                        .font(DesignSystem.Typography.ibmPlexSansHebrew(.bold, size: 16))
                        .foregroundColor(Color(hex: "3E9FFF") ?? DesignSystem.Colors.accent)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .disabled(!isClaimEnabled)
                .opacity(isClaimEnabled ? 1.0 : 0.45)
                
                HStack(spacing: 8) {
                    Text("Credits on stock today : \(creditsInStockToday)")
                        .font(DesignSystem.Typography.ibmPlexSansHebrew(.medium, size: 14))
                        .foregroundColor(DesignSystem.Colors.inkSecondary)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "3E9FFF") ?? DesignSystem.Colors.accent)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: DesignSystem.Shadow.softColor, radius: DesignSystem.Shadow.softRadius, x: 0, y: 1)
            .padding(4)
        }
    }
}

