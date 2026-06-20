import SwiftUI

struct StatusChip: View {
    let status: MarkerStatus
    var body: some View {
        let tint = Theme.color(for: status)
        Text(status.label)
            .font(Theme.rounded(.caption2, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.18))
            )
            .overlay(alignment: .top) {
                // top gloss highlight
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.55), .clear],
                                         startPoint: .top, endPoint: .center))
                    .padding(1)
                    .allowsHitTesting(false)
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.25), radius: 4, x: 0, y: 2)
            .accessibilityLabel("Status: \(status.label)")
    }
}
