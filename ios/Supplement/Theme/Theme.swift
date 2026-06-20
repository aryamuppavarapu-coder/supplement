import SwiftUI

/// Brand + design tokens. Frutiger-Aero "healthy sage": bright, glassy, glossy, nature-y.
/// Centralizing here means the whole app restyles from one place (and renaming is one line).
enum Theme {
    static let appName = "Supplement"
    static let tagline = "Know your labs. Eat smarter."

    // ── Palette ───────────────────────────────────────────────────────────────
    static let sage = Color(hex: 0x7FA888)       // primary sage green
    static let sageDeep = Color(hex: 0x40745A)   // deep sage (text/CTAs)
    static let mint = Color(hex: 0xA9E6C6)        // bright mint
    static let aqua = Color(hex: 0x8AD7D2)        // aqua accent (Frutiger Aero water)
    static let sky = Color(hex: 0xCBEDF2)         // pale sky
    static let cream = Color(hex: 0xF4F8EF)       // warm off-white background
    static let ink = Color(hex: 0x26352B)         // deep text
    static let inkSoft = Color(hex: 0x5C6F62)     // secondary text

    /// App accent (overrides the SwiftUI default via `.tint`).
    static let accent = sageDeep

    // ── Gradients ─────────────────────────────────────────────────────────────
    /// Full-screen brand background.
    static var background: LinearGradient {
        LinearGradient(colors: [sky, mint.opacity(0.55), cream],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    /// Glossy CTA fill.
    static var gloss: LinearGradient {
        LinearGradient(colors: [mint, sage, sageDeep],
                       startPoint: .top, endPoint: .bottom)
    }
    /// Soft tint fill for chips/badges.
    static var tintFill: LinearGradient {
        LinearGradient(colors: [mint.opacity(0.6), aqua.opacity(0.4)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // ── Type ──────────────────────────────────────────────────────────────────
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func heading(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func rounded(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    // ── Status colors (calm + non-alarming per SPEC §2.1, except critical) ──────
    static func color(for status: MarkerStatus) -> Color {
        switch status {
        case .inRange: return Color(hex: 0x4FA877)          // healthy green
        case .low, .high: return Color(hex: 0xE0A23C)       // warm amber
        case .criticalLow, .criticalHigh: return Color(hex: 0xE2574C) // coral red (still clearly urgent)
        case .qualitative: return aqua
        case .indeterminate: return inkSoft
        }
    }
}

extension Color {
    /// Hex literal init, e.g. `Color(hex: 0x7FA888)`.
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
