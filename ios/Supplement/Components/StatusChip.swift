import SwiftUI

/// Compact status pill (In range / High / Low / Critical …). Solid soft-tinted capsule with a
/// leading status icon and a bold label in a readable dark shade of the status hue — designed
/// for at-a-glance scanning and strong contrast on light cards.
struct StatusChip: View {
    let status: MarkerStatus

    var body: some View {
        let tint = Theme.color(for: status)
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(status.label)
                .font(Theme.rounded(.caption2, weight: .bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(tint.opacity(0.32), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(status.label)")
    }

    private var icon: String {
        switch status {
        case .inRange: return "checkmark.circle.fill"
        case .low: return "arrow.down.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .criticalLow, .criticalHigh: return "exclamationmark.triangle.fill"
        case .qualitative: return "circle.lefthalf.filled"
        case .indeterminate: return "questionmark.circle.fill"
        }
    }
}
