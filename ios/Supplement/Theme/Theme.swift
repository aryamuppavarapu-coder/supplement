import SwiftUI

/// Brand + design tokens. Clean, high-contrast wellness green: solid surfaces, dark text on
/// light, white text on the green accent — no translucency-over-gradient contrast traps.
/// Token NAMES are stable so every screen restyles from here.
enum Theme {
    static let appName = "Supplement"
    static let tagline = "Know your labs. Eat smarter."

    // ── Palette ───────────────────────────────────────────────────────────────
    static let sage = Color(hex: 0x2F8F66)        // primary green (icons, accents)
    static let sageDeep = Color(hex: 0x1F6B49)    // deep green (accent text, buttons)
    static let mint = Color(hex: 0xE6F2EB)        // very light green (chips, soft buttons)
    static let aqua = Color(hex: 0x3D9BA8)        // teal accent
    static let sky = Color(hex: 0xDCEFF2)         // faint sky
    static let cream = Color(hex: 0xF4F6F1)       // app background (light)
    static let surface = Color.white              // card surface (solid → always readable)
    static let ink = Color(hex: 0x18271F)         // primary text (near-black)
    static let inkSoft = Color(hex: 0x586860)     // secondary text (medium, readable on white)

    // Accent text colors — all chosen dark enough to read on light surfaces (≥4.5:1),
    // so headings/labels/icons can use color tastefully instead of only black.
    static let blue = Color(hex: 0x2C6FA6)        // calm blue (info, summaries)
    static let teal = Color(hex: 0x227F86)        // deep teal (qualitative, badges)
    static let amber = Color(hex: 0xB26C12)       // warm amber/orange (caution, highlights)
    static let berry = Color(hex: 0xB14A6B)       // muted berry (occasional accent)

    static let accent = sageDeep

    // ── Gradients (subtle) ──────────────────────────────────────────────────────
    static var background: LinearGradient {
        LinearGradient(colors: [Color(hex: 0xEAF4ED), cream], startPoint: .top, endPoint: .bottom)
    }
    /// Primary button fill (always paired with WHITE text).
    static var gloss: LinearGradient {
        LinearGradient(colors: [sage, sageDeep], startPoint: .top, endPoint: .bottom)
    }
    /// Soft light-green fill for chips/badges (always paired with DARK/green text).
    static var tintFill: LinearGradient {
        LinearGradient(colors: [mint, mint], startPoint: .top, endPoint: .bottom)
    }

    // ── Type (clean SF Pro) ─────────────────────────────────────────────────────
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold) }
    static func heading(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold) }
    static func rounded(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default).weight(weight)
    }

    // ── Status colors ───────────────────────────────────────────────────────────
    static func color(for status: MarkerStatus) -> Color {
        switch status {
        case .inRange: return Color(hex: 0x2A8159)              // green
        case .low: return Color(hex: 0xC9870A)                  // strong amber-yellow (caution)
        case .high: return Color(hex: 0xD23B2C)                 // red (alarming)
        case .criticalLow, .criticalHigh: return Color(hex: 0xB02617) // deep red (urgent)
        case .qualitative: return teal
        case .indeterminate: return inkSoft
        }
    }
}

extension Color {
    /// Hex literal init, e.g. `Color(hex: 0x2F8F66)`.
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

/// The persistent medical disclaimer (SPEC §2.5). Must appear on results + plan screens.
struct DisclaimerBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "leaf.circle.fill").foregroundStyle(Theme.sage)
            Text("Educational information, not medical advice or diagnosis. Always consult a licensed healthcare provider.")
                .font(Theme.rounded(.footnote))
        }
        .foregroundStyle(Theme.inkSoft)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.mint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
