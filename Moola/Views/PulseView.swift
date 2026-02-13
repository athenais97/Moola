import SwiftUI

/// Home dashboard wrapper (keeps existing Pulse dashboard behavior).
struct PulseView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: MainTabView.Tab
    
    var body: some View {
        PulseDashboardView(selectedTab: $selectedTab)
            .environmentObject(appState)
    }
}

#Preview("Home Dashboard") {
    PulseView(selectedTab: .constant(.home))
        .environmentObject(AppState())
}
