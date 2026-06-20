import SwiftUI

/// One step of a page tutorial.
struct TutorialStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
}

/// A clean, non-blocking coachmark. It floats as a card at the BOTTOM of the screen so it never
/// covers the page's titles or main content, over a barely-there scrim (tap to dismiss). Shown
/// once per page (persisted via @AppStorage) and replayable from a help (?) button.
struct TutorialOverlay: View {
    let steps: [TutorialStep]
    @Binding var index: Int
    let onClose: () -> Void

    private var step: TutorialStep { steps[min(max(index, 0), steps.count - 1)] }
    private var isLast: Bool { index >= steps.count - 1 }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Deliberately faint — dims the page just enough to draw the eye without hiding text.
            Color.black.opacity(0.07)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onClose() }

            card
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
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

            HStack(spacing: 10) {
                // progress dots
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
        .shadow(color: Theme.ink.opacity(0.18), radius: 26, x: 0, y: 12)
    }
}

// MARK: - Modifier + API

private struct TutorialModifier: ViewModifier {
    let steps: [TutorialStep]
    @Binding var replay: Bool
    @AppStorage private var seen: Bool
    @State private var show = false
    @State private var index = 0

    init(key: String, steps: [TutorialStep], replay: Binding<Bool>) {
        self.steps = steps
        self._replay = replay
        self._seen = AppStorage(wrappedValue: false, "tutorial.\(key).seen")
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if show {
                    TutorialOverlay(steps: steps, index: $index) {
                        seen = true
                        withAnimation(.easeInOut(duration: 0.25)) { show = false }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: show)
            .onAppear {
                guard !seen, !steps.isEmpty else { return }
                index = 0
                // let the page draw first so the coachmark animates in over real content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
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
    /// Attach a once-per-page tutorial. `key` namespaces the "seen" flag; toggle `replay` to true
    /// (e.g. from a help button) to show it again.
    func tutorial(_ key: String, steps: [TutorialStep], replay: Binding<Bool>) -> some View {
        modifier(TutorialModifier(key: key, steps: steps, replay: replay))
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
