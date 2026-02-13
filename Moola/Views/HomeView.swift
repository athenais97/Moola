import SwiftUI

/// Home view shown after successful onboarding or login
/// Simple welcome state to confirm authentication success
/// Includes navigation to Account screen for profile management
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAccount: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                }
                
                // Welcome message
                VStack(spacing: 12) {
                    Text("Welcome, \(appState.currentUser?.name ?? "")!")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("You're logged in.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Account info card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Details")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    VStack(spacing: 0) {
                        InfoRow(label: "Name", value: appState.currentUser?.name ?? "")
                        Divider()
                        InfoRow(label: "Email", value: appState.currentUser?.maskedEmail ?? "")
                        Divider()
                        InfoRow(label: "Email Verified", value: "Yes", valueColor: .green)
                        Divider()
                        InfoRow(label: "PIN Code", value: "Set", valueColor: .green)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                // Investor Profile card (if profiling completed)
                if let profile = appState.currentUser?.investorProfile {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Investor Profile")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        VStack(spacing: 0) {
                            InfoRow(
                                label: "Objective",
                                value: profile.objective?.title ?? "—",
                                valueColor: .accentColor
                            )
                            Divider()
                            InfoRow(
                                label: "Risk Tolerance",
                                value: profile.riskLabel,
                                valueColor: riskColor(for: profile.riskTolerance)
                            )
                            Divider()
                            InfoRow(
                                label: "Experience",
                                value: profile.knowledgeLevel?.title ?? "—",
                                valueColor: .accentColor
                            )
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Future: Biometric setup prompt would go here
                VStack(spacing: 8) {
                    Image(systemName: "faceid")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("Face ID coming soon")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        showAccount = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showAccount) {
            AccountView()
                .environmentObject(appState)
        }
    }
}

/// Info row for displaying account details
struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Helper Functions

extension HomeView {
    func riskColor(for value: Double) -> Color {
        switch value {
        case 0..<0.25:
            return .green
        case 0.25..<0.5:
            return .yellow
        case 0.5..<0.75:
            return .orange
        default:
            return .red
        }
    }
}

#Preview("Home View") {
    HomeView()
        .environmentObject({
            let appState = AppState()
            appState.currentUser = UserModel(
                name: "Jean",
                age: 28,
                email: "jean@example.com",
                phone: "+33612345678",
                isEmailVerified: true,
                pinHash: "hashed",
                membershipLevel: .premium
            )
            return appState
        }())
}
