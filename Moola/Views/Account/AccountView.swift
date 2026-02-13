import SwiftUI

/// Full-screen Account modal (used by some legacy entry points like `HomeView`).
/// The main app uses the Account tab (`AccountTabView`) directly.
struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AccountTabView()
            .environmentObject(appState)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
    }
}

#Preview {
    AccountView()
        .environmentObject(AppState())
}