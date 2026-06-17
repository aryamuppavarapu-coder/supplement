import SwiftUI

/// Top-level routing based on auth + onboarding state (SPEC §3).
struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ProgressView("Loading…")
            case .signedOut:
                AuthView()
            case .needsConsent:
                ConsentView()
            case .needsIntake:
                IntakeView()
            case .ready:
                MainTabView()
            }
        }
        .task { await session.start() }
    }
}

/// Main app shell once onboarded (SPEC §3.3–§3.7).
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Reports", systemImage: "doc.text.magnifyingglass") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            DoctorDirectoryView()
                .tabItem { Label("Doctors", systemImage: "stethoscope") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
