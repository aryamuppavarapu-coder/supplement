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
    @State private var showHelp = false
    @State private var showEditProfile = false

    private let tips = [
        TutorialStep(icon: "person.crop.circle", title: "Your account",
                     message: "Manage your sign-in and your subscription from here."),
        TutorialStep(icon: "lock.shield.fill", title: "Your data, your control",
                     message: "Export a full copy of your data anytime, or permanently delete your account and everything in it."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Brand lockup
                    VStack(spacing: 12) {
                        LogoMark(size: 66)
                        Wordmark(size: 26)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // ── Account ──────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel("Account")
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundStyle(Theme.sage)
                                    Text("Email")
                                        .font(Theme.rounded(.subheadline, weight: .medium))
                                        .foregroundStyle(Theme.inkSoft)
                                    Spacer()
                                    Text(Auth.auth().currentUser?.email ?? "—")
                                        .font(Theme.rounded(.subheadline, weight: .semibold))
                                        .foregroundStyle(Theme.ink)
                                }

                                Divider().overlay(Theme.sage.opacity(0.25))

                                Button("Sign out") { session.signOut() }
                                    .buttonStyle(.aeroSoft)
                            }
                        }
                    }

                    // ── Health profile ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel("Health profile")
                        Button { showEditProfile = true } label: {
                            GlassCard {
                                HStack(spacing: 12) {
                                    Image(systemName: "heart.text.square.fill")
                                        .foregroundStyle(Theme.sage)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Edit health details")
                                            .font(Theme.rounded(.body, weight: .semibold))
                                            .foregroundStyle(Theme.ink)
                                        Text("Age, biological sex, medications & conditions")
                                            .font(Theme.rounded(.footnote))
                                            .foregroundStyle(Theme.inkSoft)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Subscription ─────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel("Subscription")
                        NavigationLink {
                            PaywallView()
                        } label: {
                            GlassCard {
                                HStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(Theme.sageDeep)
                                    Text("Manage plan")
                                        .font(Theme.rounded(.body, weight: .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Privacy ──────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel("Privacy")
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Button {
                                    Task { await exportData() }
                                } label: {
                                    if busy {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        Label("Export my data", systemImage: "square.and.arrow.up")
                                    }
                                }
                                .buttonStyle(.aeroSoft)
                                .disabled(busy)

                                Button {
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete my account & data", systemImage: "trash")
                                        .foregroundStyle(Theme.color(for: .criticalHigh))
                                }
                                .buttonStyle(.aeroSoft)

                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.aqua)
                                    Text("Export gives you a copy of your data. Delete permanently removes your profile, reports, and uploaded files.")
                                        .font(Theme.rounded(.footnote))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                        }
                    }

                    DisclaimerBanner()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .aeroScreen()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    TutorialHelpButton(replay: $showHelp)
                }
            }
            .tutorial("profile", steps: tips, replay: $showHelp)
            .sheet(isPresented: $showEditProfile) {
                IntakeView(isEditing: true).environment(session)
            }
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
                    ScrollView {
                        Text(payload.text)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .glassCard()
                            .padding()
                    }
                    .aeroScreen()
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
