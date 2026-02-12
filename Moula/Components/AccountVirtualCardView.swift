import SwiftUI

/// Premium virtual card for a `PortfolioAccount`.
/// Designed for paging carousel use (large tappable surface, calm depth).
struct AccountVirtualCardView: View {
    let account: PortfolioAccount
    let isSelected: Bool
    var displayMode: DisplayMode = .full
    var onViewDetailsTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            cardBackground
            if displayMode == .full {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(account.institutionName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                            
                            Text(account.accountName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        
                        Spacer(minLength: 0)
                        
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: 42, height: 42)
                            
                            Image(systemName: account.accountType.iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.95))
                        }
                        .accessibilityHidden(true)
                    }
                    
                    Spacer(minLength: 0)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(maskedNumber)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                            .tracking(1.2)
                            .monospacedDigit()
                        
                        HStack(alignment: .firstTextBaseline) {
                            Text("Balance")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))
                                .textCase(.uppercase)
                                .tracking(0.8)
                            
                            Spacer(minLength: 0)
                            
                            Text(account.formattedBalance)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(20)
            } else if displayMode == .cards {
                // Reference-style: light card with minimal info.
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(account.accountName)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.ink.opacity(0.82))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            
                            Text(account.institutionName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.inkSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer(minLength: 0)
                        
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.inkSecondary)
                            .padding(.top, 2)
                            .accessibilityHidden(true)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Decorative chip hint (keeps it “card-like” without adding more info).
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 54, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                        .accessibilityHidden(true)
                }
                .padding(22)
            } else {
                // Artwork-only mode: no text, just subtle branding hints.
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.10))
                                .frame(width: 44, height: 44)
                            Image(systemName: account.accountType.iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.90))
                        }
                        .padding(18)
                        .accessibilityHidden(true)
                    }
                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(isSelected ? 0.18 : 0.10), radius: isSelected ? 18 : 12, x: 0, y: isSelected ? 12 : 8)
        .scaleEffect(isSelected ? 1.0 : 0.94)
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.accountName)")
    }
    
    private var maskedNumber: String {
        let suffix = account.lastFourDigits.isEmpty ? "••••" : account.lastFourDigits
        return "••••  ••••  ••••  \(suffix)"
    }
    
    private var cardBackground: some View {
        ZStack {
            if displayMode == .cards {
                // Light, modern gradient (reference-inspired).
                LinearGradient(
                    stops: [
                        .init(color: gradientColors[0], location: 0),
                        .init(color: gradientColors[1], location: 0.55),
                        .init(color: gradientColors[2], location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle glass sheen
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.clear,
                        Color.white.opacity(0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.35)
            } else {
                // Default (darker) look for other usages.
                LinearGradient(
                    colors: [
                        Color(hex: "1E1E22") ?? Color.black,
                        Color(hex: "0F0F14") ?? Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                RadialGradient(
                    colors: [
                        DesignSystem.Colors.accent.opacity(0.35),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 220
                )
                .blendMode(.screen)
                .opacity(0.8)
                
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        Color.clear,
                        Color.white.opacity(0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.35)
            }
        }
    }
}

private extension AccountVirtualCardView {
    var gradientColors: [Color] {
        // Deterministic palette per account (calm pastels like reference).
        let palettes: [[Color]] = [
            [Color(hex: "CFE9FF") ?? .blue.opacity(0.20), Color(hex: "F7F1D6") ?? .yellow.opacity(0.18), Color(hex: "FFD7A8") ?? .orange.opacity(0.22)],
            [Color(hex: "DCCBFF") ?? .purple.opacity(0.20), Color(hex: "E7F4FF") ?? .blue.opacity(0.16), Color(hex: "FFE0F2") ?? .pink.opacity(0.20)],
            [Color(hex: "D7FFF1") ?? .mint.opacity(0.18), Color(hex: "E7F4FF") ?? .blue.opacity(0.16), Color(hex: "FFF0D6") ?? .yellow.opacity(0.18)],
            [Color(hex: "FFE6F0") ?? .pink.opacity(0.18), Color(hex: "F0F3FF") ?? .indigo.opacity(0.14), Color(hex: "D7F7FF") ?? .cyan.opacity(0.16)]
        ]
        let idx = abs(account.id.uuidString.hashValue) % palettes.count
        return palettes[idx]
    }
}

extension AccountVirtualCardView {
    enum DisplayMode {
        case full
        case artworkOnly
        case cards
    }
}

#Preview("Account Card") {
    AccountVirtualCardView(account: PortfolioAccount.sampleAccounts[0], isSelected: true)
        .frame(height: 260)
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}
