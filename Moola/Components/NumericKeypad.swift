import SwiftUI

/// Custom numeric keypad for PIN entry
/// Designed with mobile-first principles: large touch targets, clear feedback
struct NumericKeypad: View {
    let onDigitTap: (String) -> Void
    let onDelete: () -> Void
    
    @State private var pressedKey: String?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            // Row 1: 1, 2, 3
            ForEach(["1", "2", "3"], id: \.self) { digit in
                KeypadButton(digit: digit, isPressed: pressedKey == digit) {
                    handleTap(digit)
                }
            }
            
            // Row 2: 4, 5, 6
            ForEach(["4", "5", "6"], id: \.self) { digit in
                KeypadButton(digit: digit, isPressed: pressedKey == digit) {
                    handleTap(digit)
                }
            }
            
            // Row 3: 7, 8, 9
            ForEach(["7", "8", "9"], id: \.self) { digit in
                KeypadButton(digit: digit, isPressed: pressedKey == digit) {
                    handleTap(digit)
                }
            }
            
            // Row 4: Empty, 0, Delete
            Color.clear
                .frame(height: 72)
            
            KeypadButton(digit: "0", isPressed: pressedKey == "0") {
                handleTap("0")
            }
            
            DeleteButton(isPressed: pressedKey == "delete") {
                handleDelete()
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func handleTap(_ digit: String) {
        pressedKey = digit
        onDigitTap(digit)
        
        // Reset pressed state after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedKey = nil
        }
    }
    
    private func handleDelete() {
        pressedKey = "delete"
        onDelete()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedKey = nil
        }
    }
}

/// Individual keypad button with press animation
struct KeypadButton: View {
    let digit: String
    let isPressed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(digit)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .background(
                    Circle()
                        .fill(isPressed ? Color(.systemGray4) : Color(.systemGray6))
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

/// Delete button with backspace icon
struct DeleteButton: View {
    let isPressed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "delete.left")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.primary)
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .background(
                    Circle()
                        .fill(isPressed ? Color(.systemGray4) : Color.clear)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    NumericKeypad(
        onDigitTap: { digit in print("Tapped: \(digit)") },
        onDelete: { print("Delete") }
    )
    .padding()
}
