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
                VStack(spacing: 16) {
                    LogoMark(size: 64)
                    ProgressView("Extracting your report…")
                        .font(Theme.rounded(.callout, weight: .medium))
                        .tint(Theme.sageDeep)
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .glassCard()
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aeroScreen()
            case .extracted, .confirmed:
                ConfirmValuesView(reportId: reportId, markers: store.markers, onDone: {})
            case .error:
                EmptyHint(
                    title: "Couldn't read this report",
                    message: "Try re-uploading a clearer scan or photo.",
                    systemImage: "leaf.arrow.circlepath",
                    tint: Theme.amber
                )
                .glassCard()
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aeroScreen()
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
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    LogoMark(size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your results").font(Theme.heading(20)).foregroundStyle(Theme.ink)
                        if let lab = store.report?.labName {
                            Text(lab).font(Theme.rounded(.footnote)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    Spacer()
                }

                if store.report?.hasCritical == true {
                    CriticalBanner(markers: store.report?.criticalMarkers ?? [])
                }

                if let summary = store.report?.overallSummary {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Summary")
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.blue)
                            Text(summary)
                                .font(Theme.rounded(.callout))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .glassCard()
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel("Your markers")
                    VStack(spacing: 10) {
                        ForEach(store.sortedMarkers) { marker in
                            NavigationLink {
                                MarkerDetailView(marker: marker)
                            } label: {
                                MarkerRow(marker: marker)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                NavigationLink {
                    SupplementPlanView(plan: store.plan, hasCritical: store.report?.hasCritical ?? false)
                } label: {
                    Label("Supplement & food plan", systemImage: "leaf.fill")
                }
                .buttonStyle(.aero)
                .padding(.top, 2)

                DisclaimerBanner()
            }
            .padding()
        }
        .aeroScreen()
    }
}

struct MarkerRow: View {
    let marker: Marker
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.color(for: marker.computedStatus))
                .frame(width: 34, height: 34)
                .background(Theme.color(for: marker.computedStatus).opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(marker.nameRaw)
                    .font(Theme.rounded(.headline, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                if let v = marker.value {
                    Text("\(trim(v)) \(marker.unitStd ?? marker.unitRaw ?? "")")
                        .font(Theme.rounded(.subheadline))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer()
            StatusChip(status: marker.computedStatus)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .glassCard(cornerRadius: 18, padding: 14)
    }
    private func trim(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(v) }
}

/// Pinned urgent-care banner — no model discretion (SPEC §2.3).
struct CriticalBanner: View {
    let markers: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("This needs prompt medical attention", systemImage: "exclamationmark.triangle.fill")
                .font(Theme.rounded(.headline, weight: .semibold))
            Text("One or more values are in a range that warrants contacting a healthcare provider or urgent care promptly. We've paused supplement suggestions for these.")
                .font(Theme.rounded(.callout))
            if !markers.isEmpty {
                Text(markers.joined(separator: ", "))
                    .font(Theme.rounded(.caption, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.22), in: Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Theme.color(for: .criticalHigh),
                                    Theme.color(for: .criticalHigh).opacity(0.82)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.35), .clear],
                                     startPoint: .top, endPoint: .center))
                .padding(1)
                .allowsHitTesting(false)
        }
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.4), lineWidth: 1))
        .shadow(color: Theme.color(for: .criticalHigh).opacity(0.35), radius: 12, x: 0, y: 6)
    }
}
