import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: MainTabView.Tab = .home
    @State private var isShowingSplash: Bool = true
    
    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashView()
                    .transition(AnyTransition.opacity)
            } else {
                if appState.isAuthenticated {
                    if let user = appState.currentUser, !user.hasCompletedProfiling {
                        InvestorProfilingContainerView()
                            .environmentObject(appState)
                    } else {
                        MainTabView(selectedTab: $selectedTab)
                            .environmentObject(appState)
                    }
                } else {
                    AuthEntryView()
                        .environmentObject(appState)
                }
            }
        }
        .onAppear {
            // Brief, branded splash (matches Figma). Keep this short to avoid feeling like a loading screen.
            guard isShowingSplash else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.easeOut(duration: 0.25)) {
                    isShowingSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

// MARK: - Splash (Figma)

/// Branded splash screen matching Figma.
///
/// Note: kept in `ContentView.swift` so it's included in the Xcode target
/// without altering project structure.
private struct SplashView: View {
    private let baseSize = CGSize(width: 390, height: 844)
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let scale = min(size.width / baseSize.width, size.height / baseSize.height)
            
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                // Center logo (Figma: perfectly centered on 390x844 artboard)
                Image("AuthLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 149 * scale, height: 150 * scale)
                    .shadow(
                        color: DesignSystem.Shadow.softColor,
                        radius: DesignSystem.Shadow.softRadius * scale,
                        x: DesignSystem.Shadow.softX,
                        y: DesignSystem.Shadow.softY * scale
                    )
                    .position(x: size.width / 2, y: size.height / 2)
                
                // App name near bottom (Figma: y = 779.5 on 844h artboard)
                Text("Moola")
                    .font(DesignSystem.Typography.plusJakarta(.semibold, size: 24 * scale))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .position(x: size.width / 2, y: 779.5 * scale)
            }
        }
    }
}
