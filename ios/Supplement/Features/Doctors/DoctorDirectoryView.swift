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

    var body: some View {
        NavigationStack {
            List {
                if store.doctors.isEmpty {
                    ContentUnavailableView("No practitioners listed yet", systemImage: "stethoscope")
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
            .task { await store.load() }
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
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.sageDeep)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.tintFill, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
    }
}
