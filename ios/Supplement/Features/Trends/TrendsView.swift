import SwiftUI
import Charts
import FirebaseAuth
import FirebaseFirestore

/// Marker trends over time (SPEC §3.5) — the retention driver. Aggregates analyzed reports
/// and plots each marker with its reference-range band.
@Observable
final class TrendsStore {
    struct Point: Identifiable { let id = UUID(); let date: Date; let value: Double }
    struct Series { var points: [Point]; var refLow: Double?; var refHigh: Double?; var unit: String? }

    private(set) var series: [String: Series] = [:]
    var loading = false

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid, !loading else { return }
        loading = true; defer { loading = false }
        let db = Firestore.firestore()
        // Any report that's been read by the server has plottable markers (extracted onward) —
        // not just fully-analyzed ones — so trends fill in as soon as a report is processed.
        guard let reports = try? await db.collection("users").document(uid)
            .collection("reports")
            .whereField("status", in: ["extracted", "confirmed", "analyzed", "clinical_released"])
            .getDocuments() else { return }

        var built: [String: Series] = [:]
        for report in reports.documents {
            let date = (report.data()["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            guard let markers = try? await report.reference.collection("markers").getDocuments() else { continue }
            for doc in markers.documents {
                guard let m = try? doc.data(as: Marker.self), let key = m.nameStd, let v = m.value else { continue }
                var s = built[key] ?? Series(points: [], refLow: m.refLow, refHigh: m.refHigh, unit: m.unitStd ?? m.unitRaw)
                s.points.append(Point(date: date, value: v))
                s.refLow = m.refLow; s.refHigh = m.refHigh
                built[key] = s
            }
        }
        for key in built.keys { built[key]?.points.sort { $0.date < $1.date } }
        series = built
    }
}

struct TrendsView: View {
    @State private var store = TrendsStore()
    @State private var selected: String?
    @State private var showHelp = false

    private let tips = [
        TutorialStep(icon: "chart.xyaxis.line", title: "Track over time",
                     message: "Each marker is plotted as you add reports, so you can see whether it's trending toward or away from your range."),
        TutorialStep(anchorID: "trends.picker", icon: "slider.horizontal.3", title: "Pick a marker",
                     message: "Choose any marker from this menu to see its own chart and reference band."),
        TutorialStep(anchorID: "trends.chart", icon: "leaf.fill", title: "The shaded band",
                     message: "The green band is your reference range — points inside it are within range."),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if store.series.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionLabel("Choose a marker")
                                Picker("Marker", selection: Binding(get: { selected ?? store.series.keys.sorted().first ?? "" },
                                                                    set: { selected = $0 })) {
                                    ForEach(store.series.keys.sorted(), id: \.self) { Text(display($0)).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.sageDeep)
                                .font(Theme.rounded(.body, weight: .medium))
                            }
                            .glassCard()
                            .tutorialAnchor("trends.picker")
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                        if let key = selected ?? store.series.keys.sorted().first, let s = store.series[key] {
                            Section {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chart.xyaxis.line")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(Theme.sageDeep)
                                        Text(display(key))
                                            .font(Theme.heading(20))
                                            .foregroundStyle(Theme.ink)
                                        Spacer()
                                        if let unit = s.unit, !unit.isEmpty {
                                            Text(unit)
                                                .font(Theme.rounded(.caption, weight: .medium))
                                                .foregroundStyle(Theme.inkSoft)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Theme.tintFill, in: Capsule())
                                                .overlay(Capsule().stroke(Theme.sage.opacity(0.25), lineWidth: 1))
                                        }
                                    }
                                    chart(s)
                                    HStack(spacing: 8) {
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.sage)
                                        Text("Shaded band shows your reference range.")
                                            .font(Theme.rounded(.footnote))
                                            .foregroundStyle(Theme.inkSoft)
                                    }
                                }
                                .glassCard()
                                .tutorialAnchor("trends.chart")
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Trends")
            .aeroScreen()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    TutorialHelpButton(replay: $showHelp)
                }
            }
            .task { await store.load() }
            .tutorial("trends", steps: tips, replay: $showHelp,
                      demo: TutorialDemo(resource: "trends", title: "How Trends works",
                                         caption: "Pick any marker to see it charted over time against your reference range."))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.tintFill)
                    .frame(width: 96, height: 96)
                    .overlay(Circle().stroke(Theme.sage.opacity(0.25), lineWidth: 1))
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Theme.sageDeep)
            }
            Text("No trends yet")
                .font(Theme.title(24))
                .foregroundStyle(Theme.ink)
            Text("Upload a lab report and your markers start tracking here. Add more over time to see the trend.")
                .font(Theme.rounded(.callout))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .glassCard()
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func chart(_ s: TrendsStore.Series) -> some View {
        Chart {
            if let lo = s.refLow, let hi = s.refHigh {
                RectangleMark(yStart: .value("low", lo), yEnd: .value("high", hi))
                    .foregroundStyle(Theme.sage.opacity(0.18))
            }
            ForEach(s.points) { p in
                LineMark(x: .value("Date", p.date), y: .value("Value", p.value))
                    .foregroundStyle(Theme.sageDeep)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", p.date), y: .value("Value", p.value))
                    .foregroundStyle(Theme.sage)
                    .symbolSize(70)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.sage.opacity(0.18))
                AxisTick().foregroundStyle(Theme.sage.opacity(0.35))
                AxisValueLabel().foregroundStyle(Theme.inkSoft)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.sage.opacity(0.18))
                AxisTick().foregroundStyle(Theme.sage.opacity(0.35))
                AxisValueLabel().foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(height: 240)
    }

    private func display(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
