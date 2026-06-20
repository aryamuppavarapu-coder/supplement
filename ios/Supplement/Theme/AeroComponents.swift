import SwiftUI

// MARK: - Background

/// Full-screen brand gradient with soft floating "bokeh" orbs (Frutiger Aero depth/light).
struct AeroBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            // Kept subtle so text stays readable over the background.
            orb(Theme.aqua.opacity(0.22), size: 320, x: -130, y: -240, blur: 95)
            orb(Theme.mint.opacity(0.24), size: 260, x: 150, y: -90, blur: 105)
            orb(Theme.sage.opacity(0.15), size: 300, x: 110, y: 380, blur: 115)
            orb(Color.white.opacity(0.35), size: 180, x: -120, y: 320, blur: 85)
        }
        .ignoresSafeArea()
    }

    private func orb(_ color: Color, size: CGFloat, x: CGFloat, y: CGFloat, blur: CGFloat) -> some View {
        Circle().fill(color).frame(width: size, height: size).blur(radius: blur).offset(x: x, y: y)
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

// MARK: - Glass card

/// Frosted, glossy, rounded card — the default container for content.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 22
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            // .regularMaterial (more opaque than ultraThin) so text on cards stays readable.
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.15)],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            )
            .shadow(color: Theme.sageDeep.opacity(0.14), radius: 14, x: 0, y: 8)
    }
}

extension View {
    /// Wrap any view in the standard frosted card chrome.
    func glassCard(cornerRadius: CGFloat = 22, padding: CGFloat = 16) -> some View {
        GlassCard(cornerRadius: cornerRadius, padding: padding) { self }
    }
}

// MARK: - Buttons

/// Primary glossy CTA. Use via `.buttonStyle(.aero)`.
struct AeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(.headline, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.gloss, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .top) {
                // top gloss highlight
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.45), .clear],
                                         startPoint: .top, endPoint: .center))
                    .padding(1)
                    .allowsHitTesting(false)
            }
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.4), lineWidth: 1))
            .shadow(color: Theme.sageDeep.opacity(0.35), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Secondary, soft glass button. Use via `.buttonStyle(.aeroSoft)`.
struct AeroSoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(.headline, weight: .medium))
            .foregroundStyle(Theme.sageDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.sage.opacity(0.45), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
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

/// The logo lockup: a glossy sage droplet-leaf in a gradient circle + the wordmark.
struct Wordmark: View {
    var size: CGFloat = 30
    var body: some View {
        HStack(spacing: 10) {
            LogoMark(size: size * 1.5)
            Text(Theme.appName)
                .font(.system(size: size, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
        }
    }
}

/// Just the icon mark (for nav bars / compact spots).
struct LogoMark: View {
    var size: CGFloat = 44
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Theme.mint, Theme.sage, Theme.sageDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(LinearGradient(colors: [.white.opacity(0.5), .clear],
                                         startPoint: .top, endPoint: .center))
                .padding(2)
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: Theme.sageDeep.opacity(0.4), radius: 1, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.sageDeep.opacity(0.3), radius: 5, y: 3)
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

/// Small rounded section label (e.g. "YOUR REPORTS").
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(Theme.sageDeep.opacity(0.8))
            .tracking(0.5)
    }
}
