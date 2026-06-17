import SwiftUI

/// Per-report results (SPEC §3.3). Branches on report status: waits during processing,
/// routes to confirmation after extraction, and shows the dashboard once analyzed. The
/// critical banner is pinned at the top whenever any value is critical (SPEC §2.3).
struct ResultsDashboardView: View {
    let reportId: String
    @State private var store: ReportDetailStore

    init(reportId: String) {
        self.reportId = reportId
        _store = State(initialValue: ReportDetailStore(reportId: reportId))
    }

    var body: some View {
        Group {
            switch store.report?.status {
            case .uploaded, .none:
                ProgressView("Extracting your report…")
            case .extracted, .confirmed:
                ConfirmValuesView(reportId: reportId, markers: store.markers, onDone: {})
            case .error:
                ContentUnavailableView("Couldn't read this report", systemImage: "xmark.octagon",
                                       description: Text("Try re-uploading a clearer scan or photo."))
            case .analyzed, .clinicalPending, .clinicalReleased:
                analyzed
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.start() }
        .onDisappear { store.stop() }
    }

    private var analyzed: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if store.report?.hasCritical == true {
                    CriticalBanner(markers: store.report?.criticalMarkers ?? [])
                }
                if let summary = store.report?.overallSummary {
                    Text(summary).font(.callout)
                }

                ForEach(store.sortedMarkers) { marker in
                    NavigationLink {
                        MarkerDetailView(marker: marker)
                    } label: {
                        MarkerRow(marker: marker)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    SupplementPlanView(plan: store.plan, hasCritical: store.report?.hasCritical ?? false)
                } label: {
                    Label("Supplement & food plan", systemImage: "leaf")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                DisclaimerBanner()
            }
            .padding()
        }
    }
}

struct MarkerRow: View {
    let marker: Marker
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(marker.nameRaw).font(.headline)
                if let v = marker.value {
                    Text("\(trim(v)) \(marker.unitStd ?? marker.unitRaw ?? "")")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            StatusChip(status: marker.computedStatus)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
    private func trim(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(v) }
}

/// Pinned urgent-care banner — no model discretion (SPEC §2.3).
struct CriticalBanner: View {
    let markers: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("This needs prompt medical attention", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
            Text("One or more values are in a range that warrants contacting a healthcare provider or urgent care promptly. We've paused supplement suggestions for these.")
                .font(.callout)
            if !markers.isEmpty {
                Text(markers.joined(separator: ", ")).font(.caption).bold()
            }
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red, in: RoundedRectangle(cornerRadius: 12))
    }
}
