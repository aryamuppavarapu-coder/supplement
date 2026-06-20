import SwiftUI

/// One step of a page tutorial. `anchorID` (optional) ties the step to an on-screen element
/// tagged with `.tutorialAnchor(id)`; when present, that element is spotlighted.
struct TutorialStep: Identifiable {
    let id = UUID()
    var anchorID: String? = nil
    let icon: String
    let title: String
    let message: String
}

// MARK: - Anchors

/// Collects the bounds of elements tagged with `.tutorialAnchor(id)` so the overlay can
/// spotlight them.
struct TutorialAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Tag a view so a tutorial step can spotlight it by `id`.
    func tutorialAnchor(_ id: String) -> some View {
        anchorPreference(key: TutorialAnchorKey.self, value: .bounds) { [id: $0] }
    }

    /// Show only a mask's *inverse* (cuts a hole) — used for the spotlight dim.
    fileprivate func reverseMask<M: View>(@ViewBuilder _ mask: () -> M) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: .center) { mask().blendMode(.destinationOut) }
                .compositingGroup()
        }
    }
}

// MARK: - Spotlight overlay

private struct TutorialSpotlight: View {
    let steps: [TutorialStep]
    @Binding var index: Int
    /// Resolved rect of the current step's anchored element (nil = centered, no spotlight).
    let targetRect: CGRect?
    let screenSize: CGSize
    let demo: TutorialDemo?
    let onClose: () -> Void
    @State private var showVideo = false

    private var step: TutorialStep { steps[min(max(index, 0), steps.count - 1)] }
    private var isLast: Bool { index >= steps.count - 1 }
    private var hole: CGRect? {
        guard let r = targetRect else { return nil }
        return r.insetBy(dx: -10, dy: -10)
    }
    /// Card goes to the top when the highlighted element sits low on screen.
    private var cardAtTop: Bool {
        guard let r = targetRect else { return false }
        return r.midY > screenSize.height * 0.58
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Dimmed scrim with a hole punched around the target.
            Color.black.opacity(0.58)
                .reverseMask {
                    if let h = hole {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .frame(width: h.width, height: h.height)
                            .position(x: h.midX, y: h.midY)
                    }
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onClose() }

            // Glowing highlight ring around the spotlighted element.
            if let h = hole {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.95), lineWidth: 2.5)
                    .frame(width: h.width, height: h.height)
                    .position(x: h.midX, y: h.midY)
                    .shadow(color: Theme.mint.opacity(0.9), radius: 10)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // Explanation card, kept clear of the highlighted element.
            VStack {
                if cardAtTop { card; Spacer(minLength: 0) }
                else { Spacer(minLength: 0); card }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: cardAtTop ? .top : .bottom)
        }
        .fullScreenCover(isPresented: $showVideo) {
            if let demo { DemoVideoView(demo: demo) }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(Theme.tintFill).frame(width: 46, height: 46)
                    Image(systemName: step.icon)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(Theme.sageDeep)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(Theme.heading(18))
                        .foregroundStyle(Theme.ink)
                    Text(step.message)
                        .font(Theme.rounded(.subheadline))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                        .padding(7)
                        .background(Theme.cream, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close tutorial")
            }

            // Watch the animated demo video for this page (shown on the first step).
            if demo != nil, index == 0 {
                Button { showVideo = true } label: {
                    Label("Watch a 20-sec demo", systemImage: "play.circle.fill")
                        .font(Theme.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.gloss, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(steps.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == index ? Theme.sageDeep : Theme.sage.opacity(0.25))
                            .frame(width: i == index ? 18 : 6, height: 6)
                    }
                }
                Spacer()
                if index > 0 {
                    Button("Back") { withAnimation(.easeInOut) { index -= 1 } }
                        .font(Theme.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.sageDeep)
                }
                Button {
                    if isLast { onClose() } else { withAnimation(.easeInOut) { index += 1 } }
                } label: {
                    Text(isLast ? "Got it" : "Next")
                        .font(Theme.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Theme.gloss, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.sage.opacity(0.15), lineWidth: 1))
        .shadow(color: Theme.ink.opacity(0.22), radius: 26, x: 0, y: 12)
    }
}

// MARK: - Modifier + API

private struct TutorialModifier: ViewModifier {
    let steps: [TutorialStep]
    let demo: TutorialDemo?
    @Binding var replay: Bool
    @AppStorage private var seen: Bool
    @State private var show = false
    @State private var index = 0

    init(key: String, steps: [TutorialStep], demo: TutorialDemo?, replay: Binding<Bool>) {
        self.steps = steps
        self.demo = demo
        self._replay = replay
        self._seen = AppStorage(wrappedValue: false, "tutorial.\(key).seen")
    }

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(TutorialAnchorKey.self) { anchors in
                GeometryReader { proxy in
                    if show, !steps.isEmpty {
                        let aid = steps[min(index, steps.count - 1)].anchorID
                        let rect: CGRect? = aid.flatMap { anchors[$0] }.map { proxy[$0] }
                        TutorialSpotlight(
                            steps: steps,
                            index: $index,
                            targetRect: rect,
                            screenSize: proxy.size,
                            demo: demo,
                            onClose: {
                                seen = true
                                withAnimation(.easeInOut(duration: 0.25)) { show = false }
                            }
                        )
                        .transition(.opacity)
                    }
                }
                .ignoresSafeArea()
            }
            .animation(.easeInOut(duration: 0.25), value: show)
            .onAppear {
                guard !seen, !steps.isEmpty else { return }
                index = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !seen { withAnimation(.easeInOut(duration: 0.3)) { show = true } }
                }
            }
            .onChange(of: replay) { _, newValue in
                if newValue {
                    index = 0
                    withAnimation(.easeInOut(duration: 0.25)) { show = true }
                    replay = false
                }
            }
    }
}

extension View {
    /// Attach a once-per-page interactive tutorial. `key` namespaces the "seen" flag; toggle
    /// `replay` to true (e.g. from a help button) to show it again. Pass `demo` to surface a
    /// "Watch demo" video pop-up on the first step.
    func tutorial(_ key: String, steps: [TutorialStep], replay: Binding<Bool>, demo: TutorialDemo? = nil) -> some View {
        modifier(TutorialModifier(key: key, steps: steps, demo: demo, replay: replay))
    }
}

/// Standard "replay tutorial" toolbar button.
struct TutorialHelpButton: View {
    @Binding var replay: Bool
    var body: some View {
        Button { replay = true } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.sageDeep)
        }
        .accessibilityLabel("Show tutorial")
    }
}
