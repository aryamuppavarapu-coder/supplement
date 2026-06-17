import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseFunctions

/// Upload + pipeline calls (SPEC §3.2, §8). Uploading the file triggers the server-side
/// extraction function; the app then listens for results and calls confirmAndExplain.
enum ReportService {
    private static var functions: Functions { Functions.functions(region: AppConfig.functionsRegion) }

    enum ServiceError: LocalizedError {
        case notSignedIn
        var errorDescription: String? { "You need to be signed in." }
    }

    /// Creates the report doc and uploads the file. Returns the new reportId.
    /// - Parameter contentType: "application/pdf", "image/jpeg", or "image/png".
    @discardableResult
    static func uploadReport(data: Data, contentType: String) async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else { throw ServiceError.notSignedIn }
        let reportId = UUID().uuidString
        let ext = contentType.contains("pdf") ? "pdf" : (contentType.contains("png") ? "png" : "jpg")
        let path = "users/\(uid)/reports/\(reportId)/source.\(ext)"

        // The report doc is created server-side by the onReportUpload storage trigger — clients
        // cannot write report docs (status is function-authored, SPEC §2.2). We only upload the
        // file (which carries reportId in its path); the app then listens for the doc to appear.
        let meta = StorageMetadata()
        meta.contentType = contentType
        _ = try await Storage.storage().reference(withPath: path).putDataAsync(data, metadata: meta)
        return reportId
    }

    /// Submit user-confirmed/corrected values and request Tier-1 analysis (SPEC §3.2, §5.4).
    /// `corrections` is keyed by marker index -> corrected fields.
    static func confirmAndExplain(reportId: String, corrections: [String: [String: Any]]) async throws {
        _ = try await functions.httpsCallable("confirmAndExplain").call([
            "reportId": reportId,
            "corrections": corrections
        ])
    }

    /// Tier-2 escalation (SPEC §3.8). Server hard-gates this; it throws unless the clinical
    /// tier is enabled and every §14 prerequisite is met.
    static func requestClinicalReview(reportId: String) async throws {
        _ = try await functions.httpsCallable("requestClinicalReview").call(["reportId": reportId])
    }

    /// Deletes a report server-side so its markers subcollection, plan, and Storage file are
    /// all purged (the client cannot delete the markers subcollection or other users' data).
    static func deleteReport(reportId: String) async throws {
        _ = try await functions.httpsCallable("deleteReport").call(["reportId": reportId])
    }
}
