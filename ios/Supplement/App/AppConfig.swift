import Foundation

enum AppConfig {
    /// RevenueCat PUBLIC SDK key (SPEC §7.6). Safe to ship in the app — it is NOT a server
    /// secret like the Anthropic key (which lives only in Cloud Functions, SPEC §7.7).
    /// Replace with your key from the RevenueCat dashboard, e.g. "appl_xxxxx".
    static let revenueCatAPIKey = ""

    /// Cloud Functions region for CALLABLES. They deploy to us-central1 (the firebase
    /// default) — the storage trigger is separately pinned to the bucket region. Must match
    /// where the callables actually run, or callable invocations 404 ("NOT FOUND").
    static let functionsRegion = "us-central1"
}
