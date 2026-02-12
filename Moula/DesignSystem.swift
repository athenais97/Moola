import SwiftUI

// MARK: - Color Extensions

extension Color {
    /// Initialize a Color from a hex string
    /// Supports formats: "#RRGGBB", "RRGGBB", "#RGB", "RGB"
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        
        switch length {
        case 3: // RGB (12-bit)
            let r = Double((rgb & 0xF00) >> 8) / 15.0
            let g = Double((rgb & 0x0F0) >> 4) / 15.0
            let b = Double(rgb & 0x00F) / 15.0
            self.init(red: r, green: g, blue: b)
            
        case 6: // RRGGBB (24-bit)
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
            
        case 8: // RRGGBBAA (32-bit)
            let r = Double((rgb & 0xFF000000) >> 24) / 255.0
            let g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            let b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            let a = Double(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
            
        default:
            return nil
        }
    }
}

// MARK: - Design System (semantic tokens)

/// Centralized semantic styling tokens for Flouze.
/// Screens should reference these instead of hardcoding colors/radii/shadows.
enum DesignSystem {
    enum Colors {
        /// Figma canvas background (ref screens commonly use #FBFBFB).
        static let backgroundCanvas = Color(hex: "FBFBFB") ?? backgroundPrimary
        /// App background (ref: soft off-white).
        static let backgroundPrimary = Color(hex: "F7F7F9") ?? Color(uiColor: .systemGroupedBackground)
        /// Elevated surfaces (cards, sheets).
        static let surfacePrimary = Color(uiColor: .systemBackground)
        /// Subtle separators (avoid heavy borders).
        static let separator = Color(uiColor: .separator).opacity(0.35)
        
        /// Primary ink (DS: #191919).
        static let ink = Color(hex: "191919") ?? Color(uiColor: .label)
        
        /// Primary accent (DS primary button: #3E9FFF).
        static let accent = Color(hex: "3E9FFF") ?? Color.accentColor
        
        /// Focus border / highlight (DS input border: #BDA0FF).
        static let focusBorder = Color(hex: "BDA0FF") ?? accent
        
        /// Secondary label (DS: #B0B0B0).
        static let inkSecondary = Color(hex: "B0B0B0") ?? Color(uiColor: .secondaryLabel)
        
        /// Section header grey used in Market Insights watchlist (Figma: #929292).
        static let inkSectionHeader = Color(hex: "929292") ?? inkSecondary

        /// Chat question accent (Figma: #6B00E5).
        static let chatQuestionAccent = Color(hex: "6B00E5") ?? accent
        
        /// Input background (DS: rgba(176,176,176,0.1)).
        static let inputBackground = (Color(hex: "B0B0B0") ?? Color(uiColor: .systemGray3)).opacity(0.10)
        
        /// Status colors.
        static let positive = Color(hex: "0A750C") ?? Color(uiColor: .systemGreen)
        static let negative = Color(uiColor: .systemRed)
        static let warning = Color(uiColor: .systemOrange)
        
        /// Status backgrounds (Figma).
        static let positiveBackground = Color(hex: "E5F3E5") ?? Color(uiColor: .systemGreen).opacity(0.12)
        
        /// Market Insights "Live" pill (Figma).
        static let livePillFill = Color(hex: "E0FAF0") ?? positiveBackground
        static let livePillInk = Color(hex: "2DBC84") ?? positive
        
        /// Market Insights preview chips (Figma).
        static let chipTechFill = Color(hex: "E0E3FA") ?? Color(uiColor: .systemIndigo).opacity(0.15)
        static let chipTechInk = Color(hex: "2D37BC") ?? Color(uiColor: .systemIndigo)
        static let chipBondFill = Color(hex: "F5E0FA") ?? Color(uiColor: .systemPurple).opacity(0.15)
        static let chipBondInk = Color(hex: "BC2D9F") ?? Color(uiColor: .systemPurple)
        static let chipUSFill = Color(hex: "FAE0E0") ?? Color(uiColor: .systemRed).opacity(0.12)
        static let chipUSInk = Color(hex: "BC2D2D") ?? Color(uiColor: .systemRed)
        static let chipMoreFill = surfacePrimary
        static let chipMoreInk = inkSecondary
        
        /// Market Insights climate icon background (Figma).
        static let climateIconOuterFill = (Color(hex: "E0FAF0") ?? livePillFill).opacity(0.4)
        static let climateIconTileOuterFill = Color(hex: "ECFCF6") ?? livePillFill.opacity(0.7)
        static let climateIconTileInnerFill = Color(hex: "E0FAF0") ?? livePillFill
        
        /// Text colors.
        static let textPrimary = ink
        static let textSecondary = inkSecondary
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        
        /// Button states.
        static let buttonDisabledFill = accent.opacity(0.35)
    }
    
    enum Radius {
        static let card: CGFloat = 18
        static let cardSecondary: CGFloat = 18
        static let pill: CGFloat = 18
        static let input: CGFloat = 16
        static let badge: CGFloat = 6
        static let button: CGFloat = 18
    }
    
    enum Shadow {
        /// DS soft shadow: 0 1 10 rgba(0,0,0,0.05)
        static let softColor = Color.black.opacity(0.05)
        static let softRadius: CGFloat = 10
        static let softX: CGFloat = 0
        static let softY: CGFloat = 1
    }
    
    enum Spacing {
        static let screenPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let cardPadding: CGFloat = 18
    }
    
    enum Gradients {
        /// Decorative accent gradient (keep subtle; not functional).
        static var accent: LinearGradient {
            LinearGradient(
                colors: [
                    Colors.accent.opacity(0.95),
                    Colors.accent.opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        /// Homepage hero background (Figma: lavender → soft blue → off-white).
        static var homeHero: LinearGradient {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "DBCDFC") ?? Colors.accent.opacity(0.35), location: 0),
                    .init(color: Color(hex: "C5E2FD") ?? Colors.accent.opacity(0.25), location: 0.28365),
                    .init(color: Colors.backgroundCanvas, location: 0.75962),
                    .init(color: Colors.backgroundCanvas, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        /// Chat accent gradient (Figma: lavender → soft blue).
        static var chatAccent: LinearGradient {
            LinearGradient(
                colors: [
                    Color(hex: "BDA0FF") ?? Colors.focusBorder,
                    Color(hex: "94CCFF") ?? Colors.accent.opacity(0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        /// Chat (lighter) accent gradient variant used in some screens.
        static var chatAccentSoft: LinearGradient {
            LinearGradient(
                colors: [
                    Color(hex: "DBCDFC") ?? Colors.focusBorder.opacity(0.45),
                    Color(hex: "C5E2FD") ?? Colors.accent.opacity(0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Typography
    
    /// Font helpers (DS: IBM Plex Sans Hebrew).
    /// If the font isn't bundled yet, SwiftUI will fall back at runtime.
    enum Typography {
        enum PlexWeight {
            case thin
            case extraLight
            case light
            case regular
            case medium
            case semibold
            case bold
        }
        
        /// Map these to the PostScript names in your bundled font files.
        /// Common values are like "IBMPlexSansHebrew-Regular" etc.
        private static func plexName(for weight: PlexWeight) -> String {
            switch weight {
            case .thin: return "IBMPlexSansHebrew-Thin"
            case .extraLight: return "IBMPlexSansHebrew-ExtraLight"
            case .light: return "IBMPlexSansHebrew-Light"
            case .regular: return "IBMPlexSansHebrew-Regular"
            case .medium: return "IBMPlexSansHebrew-Medium"
            case .semibold: return "IBMPlexSansHebrew-SemiBold"
            case .bold: return "IBMPlexSansHebrew-Bold"
            }
        }
        
        static func ibmPlexSansHebrew(_ weight: PlexWeight, size: CGFloat) -> Font {
            .custom(plexName(for: weight), size: size)
        }
        
        /// Compatibility shim: existing views call `plusJakarta(...)`.
        /// This now returns IBM Plex Sans Hebrew to apply the new DS globally.
        static func plusJakarta(_ weight: PlexWeight, size: CGFloat) -> Font {
            ibmPlexSansHebrew(weight, size: size)
        }
    }
}

// MARK: - Reusable styling helpers

struct SurfaceCardModifier: ViewModifier {
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
    }
}

extension View {
    func surfaceCard(radius: CGFloat = DesignSystem.Radius.card) -> some View {
        modifier(SurfaceCardModifier(radius: radius))
    }
}

// MARK: - DS Input Field

private struct DSInputFieldModifier: ViewModifier {
    let isFocused: Bool
    let hasError: Bool
    
    func body(content: Content) -> some View {
        content
            .font(DesignSystem.Typography.plusJakarta(.medium, size: 16))
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(24)
            .background(DesignSystem.Colors.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
            )
            .shadow(
                color: DesignSystem.Shadow.softColor,
                radius: DesignSystem.Shadow.softRadius,
                x: DesignSystem.Shadow.softX,
                y: DesignSystem.Shadow.softY
            )
    }
    
    private var borderColor: Color {
        if hasError { return DesignSystem.Colors.negative }
        if isFocused { return DesignSystem.Colors.focusBorder }
        return Color.clear
    }
}

extension View {
    /// DS text-field container styling (background, border, padding, shadow).
    func dsInputField(isFocused: Bool, hasError: Bool = false) -> some View {
        modifier(DSInputFieldModifier(isFocused: isFocused, hasError: hasError))
    }
}
