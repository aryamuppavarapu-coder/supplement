import FirebaseCore

enum FirebaseBootstrap {
    /// Call once at launch. Requires a real GoogleService-Info.plist in the app bundle
    /// (see ios/README.md). No API keys for Claude live here — the app only talks to your
    /// Cloud Functions, which hold the Anthropic key server-side (SPEC §7.7).
    static func configure() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}
