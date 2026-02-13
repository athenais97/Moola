import SwiftUI

/// Full-screen view for support and help resources
/// UX Intent: Easy access to help without friction
/// Foundation compliance: Scannable options, clear actions
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showChat: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick help header
                    helpHeader
                    
                    // Help options
                    helpOptionsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showChat) {
            ChatSupportView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Subviews
    
    private var helpHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.purple)
            }
            
            Text("How can we help you?")
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var helpOptionsSection: some View {
        VStack(spacing: 0) {
            helpOptionRow(
                icon: "message.fill",
                iconColor: .blue,
                title: "Live Chat",
                subtitle: "Response in minutes",
                action: { showChat = true }
            )
            
            Divider().padding(.leading, 62)
            
            helpOptionRow(
                icon: "envelope.fill",
                iconColor: .green,
                title: "Send an Email",
                subtitle: "support@example.com",
                action: {
                    if let url = URL(string: "mailto:support@example.com") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            
            Divider().padding(.leading, 62)
            
            helpOptionRow(
                icon: "phone.fill",
                iconColor: .orange,
                title: "Call Us",
                subtitle: "Mon-Fri 9am-6pm",
                action: {
                    if let url = URL(string: "tel:+33100000000") {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func helpOptionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Chat Support View (Placeholder)

struct ChatSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "ellipsis.message.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("Chat Coming Soon")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Our team is actively working on this feature.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Help View") {
    HelpView()
}
