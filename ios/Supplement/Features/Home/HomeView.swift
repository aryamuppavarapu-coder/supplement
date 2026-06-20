import SwiftUI

struct HomeView: View {
    @State private var store = ReportsListStore()
    @State private var showUpload = false
    @State private var showHelp = false

    private let tips = [
        TutorialStep(anchorID: "home.report", icon: "doc.text.magnifyingglass", title: "Your reports",
                     message: "Every lab report you add lives here. Tap one for a plain-language breakdown of each marker."),
        TutorialStep(icon: "plus.circle.fill", title: "Add a report",
                     message: "Tap the + in the top-right to scan or import a PDF or photo. We read the values and flag what's outside your range."),
        TutorialStep(icon: "leaf.fill", title: "Wellness-first & private",
                     message: "We explain results in everyday language — never a diagnosis — and your data is never sold."),
    ]

    var body: some View {
        NavigationStack {
            List {
                if store.reports.isEmpty {
                    GlassCard {
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Theme.tintFill)
                                    .frame(width: 84, height: 84)
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(Theme.sageDeep)
                            }
                            Text("No reports yet")
                                .font(Theme.heading(20))
                                .foregroundStyle(Theme.ink)
                            Text("Upload a lab report to see a plain-language breakdown.")
                                .font(Theme.rounded(.subheadline))
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center)
                            Button { showUpload = true } label: {
                                Label("Upload a report", systemImage: "tray.and.arrow.up.fill")
                            }
                            .buttonStyle(.aero)
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if !store.reports.isEmpty {
                    SectionLabel("Your reports")
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 2, trailing: 16))
                }

                ForEach(store.reports) { report in
                    NavigationLink {
                        ResultsDashboardView(reportId: report.id)
                    } label: {
                        ReportRow(report: report)
                    }
                    .tutorialAnchor(report.id == store.reports.first?.id ? "home.report" : "home.report-\(report.id)")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onDelete { offsets in
                    let ids = offsets.map { store.reports[$0].id }
                    Task { for id in ids { try? await ReportService.deleteReport(reportId: id) } }
                }
            }
            .listStyle(.plain)
            .aeroScreen()
            .navigationTitle(Theme.appName)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Wordmark(size: 22)
                }
                ToolbarItem(placement: .topBarLeading) {
                    TutorialHelpButton(replay: $showHelp)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showUpload = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Theme.sageDeep)
                            .shadow(color: Theme.sageDeep.opacity(0.3), radius: 4, y: 2)
                            .accessibilityLabel("Upload")
                    }
                }
            }
            .sheet(isPresented: $showUpload) { UploadView() }
            .onAppear { store.start() }
            .tutorial("reports", steps: tips, replay: $showHelp)
        }
        .tint(Theme.accent)
    }
}

private struct ReportRow: View {
    let report: Report
    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(report.hasCritical
                              ? AnyShapeStyle(Color(hex: 0xE2574C).opacity(0.18))
                              : AnyShapeStyle(Theme.tintFill))
                        .frame(width: 46, height: 46)
                    Image(systemName: report.hasCritical ? "exclamationmark.triangle.fill" : "drop.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(report.hasCritical ? Color(hex: 0xE2574C) : Theme.sageDeep)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(report.labName ?? "Lab report")
                        .font(Theme.rounded(.headline, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(statusText)
                        .font(Theme.rounded(.subheadline))
                        .foregroundStyle(Theme.inkSoft)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.sage.opacity(0.7))
            }
        }
    }

    private var statusText: String {
        switch report.status {
        case .uploaded: return "Uploading…"
        case .extracted: return "Ready to review your values"
        case .confirmed: return "Analyzing…"
        case .analyzed: return report.reportDate ?? "Analyzed"
        case .clinicalPending: return "Clinical review requested"
        case .clinicalReleased: return "Clinician guidance available"
        case .error: return "Something went wrong — tap to retry"
        }
    }
}
