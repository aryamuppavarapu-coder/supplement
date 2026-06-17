import SwiftUI
import RevenueCat

@main
struct SupplementApp: App {
    @State private var session = SessionStore()

    init() {
        FirebaseBootstrap.configure()
        if !AppConfig.revenueCatAPIKey.isEmpty {
            Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .tint(Theme.accent)
        }
    }
}
