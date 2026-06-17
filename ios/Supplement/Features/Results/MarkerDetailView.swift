import SwiftUI

struct MarkerDetailView: View {
    let marker: Marker

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(marker.nameRaw).font(.title2.bold())
                    Spacer()
                    StatusChip(status: marker.computedStatus)
                }

                if let v = marker.value {
                    LabeledContent("Your value", value: "\(trim(v)) \(marker.unitStd ?? marker.unitRaw ?? "")")
                }
                if let range = rangeText {
                    LabeledContent("Reference range (from your report)", value: range)
                }

                if marker.computedStatus.isCritical {
                    CriticalBanner(markers: [marker.nameRaw])
                }

                if let explanation = marker.explanation {
                    sectionTitle("What this means")
                    Text(explanation)
                }
                if let food = marker.foodContext, !food.isEmpty {
                    sectionTitle("Food context")
                    Text(food)
                }

                Text("This is educational, not a diagnosis. Talk with your provider about what your results mean for you.")
                    .font(.footnote).foregroundStyle(.secondary)

                DisclaimerBanner()
            }
            .padding()
        }
        .navigationTitle(marker.nameRaw)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s).font(.headline).padding(.top, 4)
    }
    private func trim(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(v) }
    private var rangeText: String? {
        if let lo = marker.refLow, let hi = marker.refHigh { return "\(trim(lo))–\(trim(hi))" }
        if let hi = marker.refHigh { return "< \(trim(hi))" }
        if let lo = marker.refLow { return "> \(trim(lo))" }
        return marker.refText
    }
}
