import SwiftUI

/// Top-level routing based on auth + onboarding state (SPEC §3).
struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack {
            AeroBackground()
            Group {
                switch session.phase {
                case .loading:
                    LoadingView()
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
        }
        .tint(Theme.accent)
        .task { await session.start() }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            LogoMark(size: 86)
            ProgressView()
                .tint(Theme.sageDeep)
            Text("Getting things ready…")
                .font(Theme.rounded(.subheadline))
                .foregroundStyle(Theme.inkSoft)
        }
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
        .tint(Theme.sageDeep)
    }
}
