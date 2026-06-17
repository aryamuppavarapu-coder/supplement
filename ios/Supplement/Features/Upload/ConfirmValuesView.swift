import SwiftUI

/// Step where the user confirms/corrects extracted values before analysis (SPEC §3.2).
/// A misread decimal is a safety event, so anything the engine flagged for review is
/// surfaced prominently here.
struct ConfirmValuesView: View {
    let reportId: String
    let markers: [Marker]
    var onDone: () -> Void

    @State private var editedValues: [Int: String] = [:]
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                Text("Check these against your report and fix anything that looks off. Then we'll analyze them.")
                    .font(.callout).foregroundStyle(.secondary)
            }

            ForEach(Array(markers.enumerated()), id: \.offset) { index, marker in
                Section {
                    HStack {
                        Text(marker.nameRaw).font(.headline)
                        Spacer()
                        StatusChip(status: marker.computedStatus)
                    }
                    HStack {
                        TextField(
                            "Value",
                            text: Binding(
                                get: { editedValues[index] ?? marker.value.map { formatted($0) } ?? "" },
                                set: { editedValues[index] = $0 }
                            )
                        )
                        .keyboardType(.decimalPad)
                        Text(marker.unitStd ?? marker.unitRaw ?? "")
                            .foregroundStyle(.secondary)
                    }
                    if let range = rangeText(marker) {
                        Text("Reference: \(range)").font(.caption).foregroundStyle(.secondary)
                    }
                    if marker.needsReview {
                        ForEach(marker.reviewReasons, id: \.self) { reason in
                            Label(reason, systemImage: "exclamationmark.triangle")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            }

            if let error { Text(error).foregroundStyle(.red) }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    if busy { ProgressView() } else { Text("Looks right — analyze").frame(maxWidth: .infinity) }
                }
                .disabled(busy)
            }
        }
        .navigationTitle("Confirm your values")
    }

    private func submit() async {
        busy = true; error = nil
        defer { busy = false }
        var corrections: [String: [String: Any]] = [:]
        for (index, text) in editedValues {
            let original = markers[index].value
            if let v = Double(text.replacingOccurrences(of: ",", with: ".")), v != original {
                corrections["\(index)"] = ["value": v]
            }
        }
        do {
            try await ReportService.confirmAndExplain(reportId: reportId, corrections: corrections)
            onDone()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func formatted(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }

    private func rangeText(_ m: Marker) -> String? {
        if let lo = m.refLow, let hi = m.refHigh { return "\(formatted(lo))–\(formatted(hi))" }
        if let hi = m.refHigh { return "< \(formatted(hi))" }
        if let lo = m.refLow { return "> \(formatted(lo))" }
        return m.refText
    }
}
