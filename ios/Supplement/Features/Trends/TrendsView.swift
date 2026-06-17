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
        guard let reports = try? await db.collection("users").document(uid)
            .collection("reports").whereField("status", isEqualTo: "analyzed").getDocuments() else { return }

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

    var body: some View {
        NavigationStack {
            Group {
                if store.series.isEmpty {
                    ContentUnavailableView("No trends yet", systemImage: "chart.xyaxis.line",
                        description: Text("Upload more than one report to see how your markers change over time."))
                } else {
                    List {
                        Picker("Marker", selection: Binding(get: { selected ?? store.series.keys.sorted().first ?? "" },
                                                            set: { selected = $0 })) {
                            ForEach(store.series.keys.sorted(), id: \.self) { Text(display($0)).tag($0) }
                        }
                        if let key = selected ?? store.series.keys.sorted().first, let s = store.series[key] {
                            Section(display(key)) { chart(s) }
                        }
                    }
                }
            }
            .navigationTitle("Trends")
            .task { await store.load() }
        }
    }

    @ViewBuilder
    private func chart(_ s: TrendsStore.Series) -> some View {
        Chart {
            if let lo = s.refLow, let hi = s.refHigh {
                RectangleMark(yStart: .value("low", lo), yEnd: .value("high", hi))
                    .foregroundStyle(.green.opacity(0.12))
            }
            ForEach(s.points) { p in
                LineMark(x: .value("Date", p.date), y: .value("Value", p.value))
                PointMark(x: .value("Date", p.date), y: .value("Value", p.value))
            }
        }
        .frame(height: 240)
    }

    private func display(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
