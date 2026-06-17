import SwiftUI

struct HomeView: View {
    @State private var store = ReportsListStore()
    @State private var showUpload = false

    var body: some View {
        NavigationStack {
            List {
                if store.reports.isEmpty {
                    ContentUnavailableView(
                        "No reports yet",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Upload a lab report to see a plain-language breakdown.")
                    )
                }
                ForEach(store.reports) { report in
                    NavigationLink {
                        ResultsDashboardView(reportId: report.id)
                    } label: {
                        ReportRow(report: report)
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { store.reports[$0].id }
                    Task { for id in ids { try? await ReportService.deleteReport(reportId: id) } }
                }
            }
            .navigationTitle(Theme.appName)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showUpload = true } label: { Label("Upload", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showUpload) { UploadView() }
            .onAppear { store.start() }
        }
    }
}

private struct ReportRow: View {
    let report: Report
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(report.labName ?? "Lab report").font(.headline)
                Spacer()
                if report.hasCritical {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                }
            }
            Text(statusText).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
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
