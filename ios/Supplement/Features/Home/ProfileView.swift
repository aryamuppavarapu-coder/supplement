import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

/// Profile + privacy controls. Data export & delete (DSAR) are required for Tier 1 under
/// the FTC Health Breach Notification Rule and state health-privacy laws (SPEC §9).
struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    @State private var showDeleteConfirm = false
    @State private var exportText: String?
    @State private var busy = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Email", value: Auth.auth().currentUser?.email ?? "—")
                    Button("Sign out") { session.signOut() }
                }

                Section("Subscription") {
                    NavigationLink("Manage plan") { PaywallView() }
                }

                Section {
                    Button {
                        Task { await exportData() }
                    } label: {
                        if busy { ProgressView() } else { Text("Export my data") }
                    }
                    Button("Delete my account & data", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Export gives you a copy of your data. Delete permanently removes your profile, reports, and uploaded files.")
                }

                Section {
                    DisclaimerBanner()
                }
            }
            .navigationTitle("Profile")
            .alert("Delete everything?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { Task { await deleteAccount() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account, reports, and files. This can't be undone.")
            }
            .alert("Couldn't delete your account", isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }
            .sheet(item: Binding(get: { exportText.map { ExportPayload(text: $0) } }, set: { _ in exportText = nil })) { payload in
                NavigationStack {
                    ScrollView { Text(payload.text).font(.system(.footnote, design: .monospaced)).padding() }
                        .navigationTitle("Your data")
                }
            }
        }
    }

    private func exportData() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        busy = true; defer { busy = false }
        let db = Firestore.firestore()
        var dump: [String: Any] = [:]
        if let user = try? await db.collection("users").document(uid).getDocument().data() { dump["profile"] = user }
        if let reports = try? await db.collection("users").document(uid).collection("reports").getDocuments() {
            var out: [[String: Any]] = []
            for r in reports.documents {
                var entry: [String: Any] = ["id": r.documentID, "data": r.data()]
                // Include the extracted marker values (the core health data) for a complete export.
                if let markers = try? await r.reference.collection("markers").getDocuments() {
                    entry["markers"] = markers.documents.map { ["id": $0.documentID, "data": $0.data()] }
                }
                out.append(entry)
            }
            dump["reports"] = out
        }
        if let plans = try? await db.collection("users").document(uid).collection("plans").getDocuments() {
            dump["plans"] = plans.documents.map { ["id": $0.documentID, "data": $0.data()] }
        }
        if let data = try? JSONSerialization.data(withJSONObject: dump, options: [.prettyPrinted, .sortedKeys]) {
            exportText = String(data: data, encoding: .utf8)
        }
    }

    private func deleteAccount() async {
        // Server-side cascade purge (SPEC §9): the deleteAccount function removes Firestore
        // subcollections, Storage files, and clinical PHI, then deletes the Auth record. We only
        // sign out if it actually succeeded, so we never falsely tell the user their data is gone.
        do {
            _ = try await Functions.functions(region: AppConfig.functionsRegion)
                .httpsCallable("deleteAccount").call()
        } catch {
            deleteError = error.localizedDescription
            return
        }
        session.signOut()
    }
}

private struct ExportPayload: Identifiable {
    let id = UUID()
    let text: String
}
