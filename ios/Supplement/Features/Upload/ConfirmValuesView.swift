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
        ScrollView {
            VStack(spacing: 18) {
                // Intro / context card
                GlassCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.sageDeep)
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel("Confirm extracted values")
                            Text("Check these against your report and fix anything that looks off. Then we'll analyze them.")
                                .font(Theme.rounded(.callout))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }

                // One glass card per marker
                ForEach(Array(markers.enumerated()), id: \.offset) { index, marker in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(marker.nameRaw)
                                    .font(Theme.heading(18))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                StatusChip(status: marker.computedStatus)
                            }

                            HStack(spacing: 10) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.aqua)
                                TextField(
                                    "Value",
                                    text: Binding(
                                        get: { editedValues[index] ?? marker.value.map { formatted($0) } ?? "" },
                                        set: { editedValues[index] = $0 }
                                    )
                                )
                                .keyboardType(.decimalPad)
                                .font(Theme.rounded(.title3, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                                Text(marker.unitStd ?? marker.unitRaw ?? "")
                                    .font(Theme.rounded(.callout))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Theme.sage.opacity(0.35), lineWidth: 1)
                            )

                            if let range = rangeText(marker) {
                                HStack(spacing: 6) {
                                    Image(systemName: "ruler")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.sage)
                                    Text("Reference: \(range)")
                                        .font(Theme.rounded(.caption))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }

                            if marker.needsReview {
                                ForEach(marker.reviewReasons, id: \.self) { reason in
                                    Label(reason, systemImage: "exclamationmark.triangle.fill")
                                        .font(Theme.rounded(.caption, weight: .medium))
                                        .foregroundStyle(Theme.color(for: .high))
                                }
                            }
                        }
                    }
                }

                if let error {
                    GlassCard {
                        Label(error, systemImage: "exclamationmark.octagon.fill")
                            .font(Theme.rounded(.callout, weight: .medium))
                            .foregroundStyle(Theme.color(for: .criticalHigh))
                    }
                }

                // Keep the medical disclaimer (SPEC §2.5)
                DisclaimerBanner()

                // Primary CTA
                Button {
                    Task { await submit() }
                } label: {
                    if busy {
                        ProgressView().tint(.white)
                    } else {
                        Label("Looks right — analyze", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.aero)
                .disabled(busy)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .aeroScreen()
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
