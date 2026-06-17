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
                }
                ForEach(store.doctors) { doc in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(doc.name).font(.headline)
                            if doc.sponsored {
                                Text("Sponsored")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(.yellow.opacity(0.3), in: Capsule())
                            }
                        }
                        Text("\(doc.specialty) · \(doc.location)").font(.subheadline).foregroundStyle(.secondary)
                        if let bio = doc.bio { Text(bio).font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
            .navigationTitle("Find a provider")
            .task { await store.load() }
        }
    }
}
