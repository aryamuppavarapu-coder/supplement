import SwiftUI

/// Explicit, versioned consent + the educational-not-medical opt-in (SPEC §2.5, §3.1, §9).
struct ConsentView: View {
    @Environment(SessionStore.self) private var session
    @State private var agreed = false
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Before we start")
                    .font(.title.bold())

                Group {
                    bullet("Supplement gives you educational information about your lab results. It does not diagnose disease or prescribe treatment.")
                    bullet("It explains values as above/below the typical reference range — never as a diagnosis. Always consult a licensed healthcare provider for decisions.")
                    bullet("Your health data is encrypted, is never sold, and is never used to train AI models (SPEC §2.6).")
                    bullet("You can export or permanently delete your data at any time from Profile.")
                }

                DisclaimerBanner()

                Toggle(isOn: $agreed) {
                    Text("I understand this is educational information, not medical advice or diagnosis, and I consent to the privacy terms.")
                        .font(.callout)
                }
                .padding(.top, 4)

                Button {
                    busy = true
                    Task { await session.recordConsent(); busy = false }
                } label: {
                    if busy { ProgressView() } else { Text("Agree & continue").bold().frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!agreed || busy)
            }
            .padding()
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
            Text(text)
        }
    }
}
