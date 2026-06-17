import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

/// Live list of the user's reports (SPEC §3.3 home).
@Observable
final class ReportsListStore {
    private(set) var reports: [Report] = []
    var error: String?
    private var listener: ListenerRegistration?

    func start() {
        guard listener == nil, let uid = Auth.auth().currentUser?.uid else { return }
        listener = Firestore.firestore()
            .collection("users").document(uid).collection("reports")
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                if let err { self?.error = err.localizedDescription; return }
                self?.reports = snap?.documents.compactMap { Self.decode($0) } ?? []
            }
    }

    func stop() { listener?.remove(); listener = nil }

    private static func decode(_ doc: QueryDocumentSnapshot) -> Report? {
        let d = doc.data()
        let analysis = d["analysis"] as? [String: Any]
        let lab = d["lab"] as? [String: Any]
        let extraction = d["extraction"] as? [String: Any]
        return Report(
            id: doc.documentID,
            status: ReportStatus(rawValue: d["status"] as? String ?? "uploaded") ?? .uploaded,
            labName: lab?["labName"] as? String,
            reportDate: lab?["reportDate"] as? String,
            hasCritical: analysis?["hasCritical"] as? Bool ?? false,
            criticalMarkers: analysis?["criticalMarkers"] as? [String] ?? [],
            overallSummary: analysis?["overallSummary"] as? String,
            needsHumanReview: extraction?["needsHumanReview"] as? Bool ?? false
        )
    }
}

/// Live detail for one report: its markers + gated plan (SPEC §3.3–§3.4).
@Observable
final class ReportDetailStore {
    let reportId: String
    private(set) var report: Report?
    private(set) var markers: [Marker] = []
    private(set) var plan: SupplementPlan?
    var error: String?

    private var reportListener: ListenerRegistration?
    private var markersListener: ListenerRegistration?
    private var planListener: ListenerRegistration?

    init(reportId: String) { self.reportId = reportId }

    func start() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let base = Firestore.firestore().collection("users").document(uid).collection("reports").document(reportId)

        reportListener = base.addSnapshotListener { [weak self] snap, _ in
            guard let d = snap?.data() else { return }
            let analysis = d["analysis"] as? [String: Any]
            let lab = d["lab"] as? [String: Any]
            self?.report = Report(
                id: self?.reportId ?? "",
                status: ReportStatus(rawValue: d["status"] as? String ?? "uploaded") ?? .uploaded,
                labName: lab?["labName"] as? String,
                reportDate: lab?["reportDate"] as? String,
                hasCritical: analysis?["hasCritical"] as? Bool ?? false,
                criticalMarkers: analysis?["criticalMarkers"] as? [String] ?? [],
                overallSummary: analysis?["overallSummary"] as? String,
                needsHumanReview: (d["extraction"] as? [String: Any])?["needsHumanReview"] as? Bool ?? false
            )
        }

        markersListener = base.collection("markers").addSnapshotListener { [weak self] snap, err in
            if let err { self?.error = err.localizedDescription; return }
            self?.markers = snap?.documents.compactMap { try? $0.data(as: Marker.self) } ?? []
        }

        planListener = Firestore.firestore().collection("users").document(uid)
            .collection("plans").document(reportId)
            .addSnapshotListener { [weak self] snap, _ in
                self?.plan = try? snap?.data(as: SupplementPlan.self)
            }
    }

    func stop() {
        reportListener?.remove(); markersListener?.remove(); planListener?.remove()
        reportListener = nil; markersListener = nil; planListener = nil
    }

    /// Markers grouped for display, criticals first then out-of-range, then in-range.
    var sortedMarkers: [Marker] {
        markers.sorted { lhs, rhs in
            func rank(_ s: MarkerStatus) -> Int {
                switch s {
                case .criticalLow, .criticalHigh: return 0
                case .indeterminate: return 1
                case .low, .high: return 2
                case .qualitative: return 3
                case .inRange: return 4
                }
            }
            return rank(lhs.computedStatus) < rank(rhs.computedStatus)
        }
    }
}
