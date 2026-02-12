import SwiftUI

/// Full-screen view for editing personal information
/// UX Intent: Single-focus form with clear save action
/// Foundation compliance: No full-page long forms, grouped logically
struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    private var user: UserModel? { appState.currentUser }
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var isEditing: Bool = false
    @State private var isSaving: Bool = false
    @State private var showDiscardAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Info card explaining masking
                    infoCard
                    
                    // Personal details section
                    detailsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Personal Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing && hasChanges {
                        Button("Save") {
                            saveChanges()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                        .disabled(isSaving)
                    }
                }
            }
            .onAppear {
                loadUserData()
            }
            .alert("Discard changes?", isPresented: $showDiscardAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Continue Editing", role: .cancel) {}
            } message: {
                Text("Your unsaved changes will be lost.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Your data is protected")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Some information is partially masked for your security.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var detailsSection: some View {
        VStack(spacing: 0) {
            // Name field
            editableRow(
                label: "Full Name",
                value: $name,
                placeholder: "Your name",
                keyboardType: .default,
                isSecure: false
            )
            
            Divider().padding(.leading, 16)
            
            // Email field
            editableRow(
                label: "Email",
                value: $email,
                placeholder: "your@email.com",
                keyboardType: .emailAddress,
                isSecure: false
            )
            
            Divider().padding(.leading, 16)
            
            // Phone field
            editableRow(
                label: "Phone",
                value: $phone,
                placeholder: "+1 XXX XXX XXXX",
                keyboardType: .phonePad,
                isSecure: false
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func editableRow(
        label: String,
        value: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            if isEditing {
                TextField(placeholder, text: value)
                    .font(.system(size: 16))
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .autocorrectionDisabled()
            } else {
                HStack {
                    Text(value.wrappedValue.isEmpty ? "—" : value.wrappedValue)
                        .font(.system(size: 16))
                        .foregroundColor(value.wrappedValue.isEmpty ? .secondary : .primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing = true
                        }
                    }) {
                        Text("Edit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Actions
    
    private func loadUserData() {
        guard let user = user else { return }
        name = user.name
        email = user.email
        phone = user.phone
    }
    
    private func saveChanges() {
        isSaving = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSaving = false
            isEditing = false
            generator.notificationOccurred(.success)
            // TODO: Actually persist changes to AppState and server
        }
    }
    
    private var hasChanges: Bool {
        guard let user = user else { return false }
        return name != user.name || email != user.email || phone != user.phone
    }
}

// MARK: - Preview

#Preview("Personal Info") {
    PersonalInfoView()
        .environmentObject({
            let appState = AppState()
            appState.currentUser = UserModel(
                name: "Jean-Pierre Dupont",
                age: 35,
                email: "jean.pierre@example.com",
                phone: "+33612345678",
                isEmailVerified: true,
                pinHash: ""
            )
            return appState
        }())
}
