import SwiftUI

// MARK: - Background

/// Calm, light app background — a gentle top-to-bottom green-tinted wash. Deliberately flat
/// (no busy translucent orbs) so every surface above it has even, predictable contrast.
struct AeroBackground: View {
    var body: some View {
        Theme.background.ignoresSafeArea()
    }
}

extension View {
    /// Place the brand background behind a screen and let scroll content show through it.
    func aeroScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(AeroBackground())
    }
}

// MARK: - Card

/// The default content container: a SOLID white card with a soft shadow and a hairline border.
/// Solid (not translucent) so dark text on it is always readable, regardless of what's behind.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.sage.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Theme.ink.opacity(0.06), radius: 12, x: 0, y: 5)
    }
}

extension View {
    /// Wrap any view in the standard card chrome.
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        GlassCard(cornerRadius: cornerRadius, padding: padding) { self }
    }
}

// MARK: - Buttons

/// Primary CTA: green fill, WHITE text. Use via `.buttonStyle(.aero)`.
struct AeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Body(configuration: configuration)
    }

    /// Inner view so we can read `isEnabled` and visibly grey the button out when disabled.
    /// Must be at least as accessible as AeroButtonStyle (ButtonStyle.Body requirement) — not private.
    struct Body: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled
        private var greyed: LinearGradient {
            LinearGradient(colors: [Color(hex: 0xBCC6BF), Color(hex: 0xA6B1AA)], startPoint: .top, endPoint: .bottom)
        }
        var body: some View {
            configuration.label
                .font(Theme.rounded(.headline, weight: .semibold))
                .foregroundStyle(isEnabled ? .white : Color.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(isEnabled ? Theme.gloss : greyed, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .top) {
                    // subtle top sheen — kept faint so it never washes out the white label
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [.white.opacity(isEnabled ? 0.22 : 0.12), .clear],
                                             startPoint: .top, endPoint: .center))
                        .padding(1)
                        .allowsHitTesting(false)
                }
                .shadow(color: (isEnabled ? Theme.sageDeep : Color.gray).opacity(isEnabled ? 0.28 : 0.12), radius: 9, x: 0, y: 4)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(isEnabled ? (configuration.isPressed ? 0.92 : 1) : 0.85)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
}

/// Secondary button: light-green fill, GREEN text. Use via `.buttonStyle(.aeroSoft)`.
struct AeroSoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(.headline, weight: .semibold))
            .foregroundStyle(Theme.sageDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.mint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.sage.opacity(0.4), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AeroButtonStyle {
    static var aero: AeroButtonStyle { AeroButtonStyle() }
}
extension ButtonStyle where Self == AeroSoftButtonStyle {
    static var aeroSoft: AeroSoftButtonStyle { AeroSoftButtonStyle() }
}

// MARK: - Brand marks

/// The logo lockup: a green leaf mark + the wordmark.
struct Wordmark: View {
    var size: CGFloat = 30
    var body: some View {
        HStack(spacing: 10) {
            LogoMark(size: size * 1.5)
            Text(Theme.appName)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(Theme.ink)
        }
    }
}

/// Just the icon mark (for nav bars / compact spots): white leaf in a green gradient circle.
struct LogoMark: View {
    var size: CGFloat = 44
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Theme.sage, Theme.sageDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.sageDeep.opacity(0.25), radius: 5, y: 3)
    }
}

/// Centered brand header for auth / onboarding screens.
struct BrandHeader: View {
    var subtitle: String = Theme.tagline
    var body: some View {
        VStack(spacing: 14) {
            LogoMark(size: 78)
            Text(Theme.appName).font(Theme.title(34)).foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(Theme.rounded(.callout))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }
}

/// Small uppercase section label (e.g. "YOUR REPORTS").
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, weight: .semibold))
            .foregroundStyle(Theme.sageDeep)
            .tracking(0.6)
    }
}
