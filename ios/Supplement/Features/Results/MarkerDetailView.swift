import SwiftUI

struct MarkerDetailView: View {
    let marker: Marker

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header card: marker name + status
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            HStack(spacing: 10) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Theme.sage)
                                Text(marker.nameRaw)
                                    .font(Theme.title(24))
                                    .foregroundStyle(Theme.ink)
                            }
                            Spacer()
                            StatusChip(status: marker.computedStatus)
                        }

                        if let v = marker.value {
                            valueRow(
                                icon: "chart.dots.scatter",
                                label: "Your value",
                                value: "\(trim(v)) \(marker.unitStd ?? marker.unitRaw ?? "")"
                            )
                        }
                        if let range = rangeText {
                            if marker.value != nil {
                                Divider().overlay(Theme.sage.opacity(0.25))
                            }
                            valueRow(
                                icon: "ruler",
                                label: "Reference range (from your report)",
                                value: range
                            )
                        }
                    }
                }

                if marker.computedStatus.isCritical {
                    CriticalBanner(markers: [marker.nameRaw])
                }

                if let explanation = marker.explanation {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("What this means", icon: "sparkles")
                            Text(explanation)
                                .font(Theme.rounded(.body))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
                if let food = marker.foodContext, !food.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("Food context", icon: "leaf.fill")
                            Text(food)
                                .font(Theme.rounded(.body))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }

                Text("This is educational, not a diagnosis. Talk with your provider about what your results mean for you.")
                    .font(Theme.rounded(.footnote))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 4)

                DisclaimerBanner()
            }
            .padding()
        }
        .aeroScreen()
        .navigationTitle(marker.nameRaw)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ s: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.sageDeep)
            SectionLabel(s)
        }
    }

    private func valueRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.sage)
                .frame(width: 18)
            Text(label)
                .font(Theme.rounded(.subheadline))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
    }

    private func trim(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(v) }
    private var rangeText: String? {
        if let lo = marker.refLow, let hi = marker.refHigh { return "\(trim(lo))–\(trim(hi))" }
        if let hi = marker.refHigh { return "< \(trim(hi))" }
        if let lo = marker.refLow { return "> \(trim(lo))" }
        return marker.refText
    }
}
