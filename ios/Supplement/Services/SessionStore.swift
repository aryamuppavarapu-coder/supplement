import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

/// The signed-in user's profile document (SPEC §3.1, §4 `users/{uid}`).
struct UserProfileDoc: Codable, Sendable {
    struct Profile: Codable, Sendable {
        var age: Int?
        var sex: String?
        var pregnant: Bool?
        var heightCm: Double?
        var weightKg: Double?
        var goals: [String]?
    }
    var profile: Profile?
    var medications: [String]?
    var conditions: [String]?
    var disclosedMeds: Bool?
    var disclosedConditions: Bool?
    var consentVersion: String?
    var consentAt: Timestamp?
}

/// Auth + onboarding state machine (SPEC §3.1). `@Observable` per SPEC §7.1 (Observation/MVVM).
@Observable
final class SessionStore {
    enum Phase { case loading, signedOut, needsConsent, needsIntake, ready }

    private(set) var phase: Phase = .loading
    private(set) var uid: String?
    private(set) var profile: UserProfileDoc?
    var lastError: String?

    /// The consent copy version the user must accept (bump when the policy changes).
    static let currentConsentVersion = "2026-06-tier1-v1"

    private var authHandle: AuthStateDidChangeListenerHandle?
    // Computed (not a stored `let`): touching Firestore.firestore() during SessionStore
    // construction would run BEFORE FirebaseApp.configure() in the App init and crash at launch.
    private var db: Firestore { Firestore.firestore() }

    func start() async {
        if authHandle == nil {
            authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { await self?.handleAuthChange(user) }
            }
        }
    }

    private func handleAuthChange(_ user: User?) async {
        guard let user else {
            uid = nil; profile = nil; phase = .signedOut; return
        }
        uid = user.uid
        await refreshProfile()
    }

    func refreshProfile() async {
        guard let uid else { phase = .signedOut; return }
        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            let doc = try? snap.data(as: UserProfileDoc.self)
            profile = doc
            phase = computePhase(doc)
        } catch {
            lastError = error.localizedDescription
            phase = .needsConsent
        }
    }

    private func computePhase(_ doc: UserProfileDoc?) -> Phase {
        guard let doc, doc.consentVersion == Self.currentConsentVersion else { return .needsConsent }
        // Intake is complete once the disclosure flags are explicitly set (SPEC §3.1).
        guard doc.disclosedMeds != nil, doc.disclosedConditions != nil else { return .needsIntake }
        return .ready
    }

    // MARK: - Mutations

    func recordConsent() async {
        guard let uid else { return }
        do {
            try await db.collection("users").document(uid).setData([
                "consentVersion": Self.currentConsentVersion,
                "consentAt": FieldValue.serverTimestamp()
            ], merge: true)
            await refreshProfile()
        } catch { lastError = error.localizedDescription }
    }

    func saveIntake(
        profile: UserProfileDoc.Profile,
        medications: [MedicationClass],
        conditions: [HealthCondition],
        disclosedMeds: Bool,
        disclosedConditions: Bool
    ) async {
        guard let uid else { return }
        do {
            try await db.collection("users").document(uid).setData([
                "profile": [
                    "age": profile.age as Any,
                    "sex": profile.sex as Any,
                    "pregnant": profile.pregnant as Any,
                    "heightCm": profile.heightCm as Any,
                    "weightKg": profile.weightKg as Any
                ],
                "medications": medications.map(\.rawValue),
                "conditions": conditions.map(\.rawValue),
                "disclosedMeds": disclosedMeds,
                "disclosedConditions": disclosedConditions
            ], merge: true)
            await refreshProfile()
        } catch { lastError = error.localizedDescription }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }
}
