import SwiftUI
import FirebaseFirestore

/// Doctor directory (SPEC §3.6). Sponsored listings are clearly LABELED "Sponsored" — this
/// is a disclosed advertising/listing model, NOT pay-per-referral (SPEC §10.3, ⚠️ VERIFY
/// with a healthcare attorney before launch).
struct Doctor: Codable, Identifiable {
    let id: String
    let name: String
    let specialty: String
    let location: String
    let bio: String?
    let sponsored: Bool
}

@Observable
final class DoctorStore {
    private(set) var doctors: [Doctor] = []
    func load() async {
        let snap = try? await Firestore.firestore().collection("doctors").getDocuments()
        doctors = snap?.documents.compactMap { try? $0.data(as: Doctor.self) } ?? []
        // Sponsored first, but always labeled.
        doctors.sort { ($0.sponsored ? 0 : 1) < ($1.sponsored ? 0 : 1) }
    }
}

struct DoctorDirectoryView: View {
    @State private var store = DoctorStore()
    @State private var showHelp = false

    private let tips = [
        TutorialStep(icon: "stethoscope", title: "Find a provider",
                     message: "Browse practitioners who can help you act on your results — always discuss anything the app surfaces with a real clinician."),
        TutorialStep(icon: "checkmark.seal.fill", title: "Clearly labeled",
                     message: "Sponsored listings are always marked “Sponsored.” We never hide who paid for placement."),
    ]

    var body: some View {
        NavigationStack {
            List {
                if store.doctors.isEmpty {
                    EmptyHint(
                        title: "No providers listed yet",
                        message: "Check back soon — practitioners you can talk to about your results will appear here.",
                        systemImage: "stethoscope"
                    )
                    .glassCard()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                ForEach(store.doctors) { doc in
                    DoctorRow(doc: doc)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .navigationTitle("Find a provider")
            .aeroScreen()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    TutorialHelpButton(replay: $showHelp)
                }
            }
            .task { await store.load() }
            .tutorial("doctors", steps: tips, replay: $showHelp)
        }
    }
}

/// One frosted, glossy provider card.
private struct DoctorRow: View {
    let doc: Doctor

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.tintFill)
                            .frame(width: 44, height: 44)
                        Image(systemName: "stethoscope")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.sageDeep)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(doc.name)
                                .font(Theme.heading(18))
                                .foregroundStyle(Theme.ink)
                            if doc.sponsored {
                                SponsoredBadge()
                            }
                        }
                        Label {
                            Text("\(doc.specialty) · \(doc.location)")
                                .font(Theme.rounded(.subheadline))
                                .foregroundStyle(Theme.inkSoft)
                        } icon: {
                            Image(systemName: "leaf.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.sage)
                        }
                    }
                    Spacer(minLength: 0)
                }

                if let bio = doc.bio {
                    Text(bio)
                        .font(Theme.rounded(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// Clearly-labeled "Sponsored" chip (SPEC §10.3 — disclosed listing, always visible).
private struct SponsoredBadge: View {
    var body: some View {
        Text("Sponsored")
            .font(.system(.caption2, weight: .bold))
            .foregroundStyle(Theme.amber)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.amber.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(Theme.amber.opacity(0.3), lineWidth: 1))
    }
}
