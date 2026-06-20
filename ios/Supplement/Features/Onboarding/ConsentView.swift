import SwiftUI

/// Explicit, versioned consent + the educational-not-medical opt-in (SPEC §2.5, §3.1, §9).
struct ConsentView: View {
    @Environment(SessionStore.self) private var session
    @State private var agreed = false
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BrandHeader(subtitle: "A quick note before we begin")

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionLabel("Before we start")

                        Text("Know your labs, the gentle way")
                            .font(Theme.title(24))
                            .foregroundStyle(Theme.ink)

                        VStack(alignment: .leading, spacing: 14) {
                            bullet("leaf.fill",
                                   "Supplement gives you educational information about your lab results. It does not diagnose disease or prescribe treatment.")
                            bullet("chart.bar.fill",
                                   "It explains values as above/below the typical reference range — never as a diagnosis. Always consult a licensed healthcare provider for decisions.")
                            bullet("lock.fill",
                                   "Your health data is encrypted, is never sold, and is never used to train AI models (SPEC §2.6).")
                            bullet("square.and.arrow.up.fill",
                                   "You can export or permanently delete your data at any time from Profile.")
                        }
                    }
                }

                DisclaimerBanner()

                GlassCard {
                    Toggle(isOn: $agreed) {
                        Text("I understand this is educational information, not medical advice or diagnosis, and I consent to the privacy terms.")
                            .font(Theme.rounded(.callout))
                            .foregroundStyle(Theme.ink)
                    }
                    .tint(Theme.sage)
                }

                Button {
                    busy = true
                    Task { await session.recordConsent(); busy = false }
                } label: {
                    if busy {
                        ProgressView().tint(.white)
                    } else {
                        Label("Agree & continue", systemImage: "checkmark.seal.fill")
                    }
                }
                .buttonStyle(.aero)
                .disabled(!agreed || busy)
            }
            .padding(20)
        }
        .aeroScreen()
    }

    private func bullet(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.sageDeep)
                .frame(width: 24)
            Text(text)
                .font(Theme.rounded(.subheadline))
                .foregroundStyle(Theme.inkSoft)
        }
    }
}
