import SwiftUI
import UIKit
import RevenueCat

@main
struct SupplementApp: App {
    @State private var session = SessionStore()

    init() {
        FirebaseBootstrap.configure()
        if !AppConfig.revenueCatAPIKey.isEmpty {
            Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey)
        }
        Self.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .tint(Theme.accent)
                // The whole design is a FIXED light theme (light gradients + dark ink). Lock to
                // light so system-colored elements (nav titles, tab labels, ContentUnavailableView)
                // never flip to white on a device set to dark mode.
                .preferredColorScheme(.light)
        }
    }

    /// Style the UIKit bars so titles + tab labels are dark green (not the default white-in-dark).
    private static func configureAppearance() {
        let titleColor = UIColor(Theme.sageDeep)
        let inkColor = UIColor(Theme.ink)

        // Navigation bars — transparent so the AeroBackground shows through; dark-green titles.
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = .clear
        nav.titleTextAttributes = [.foregroundColor: titleColor]
        nav.largeTitleTextAttributes = [.foregroundColor: titleColor]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(Theme.sageDeep)

        // Tab bar — clean light background; selected = deep green, unselected = readable ink-soft.
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.cream)
        for item in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            item.selected.iconColor = UIColor(Theme.sageDeep)
            item.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.sageDeep)]
            item.normal.iconColor = UIColor(Theme.inkSoft)
            item.normal.titleTextAttributes = [.foregroundColor: inkColor.withAlphaComponent(0.7)]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
