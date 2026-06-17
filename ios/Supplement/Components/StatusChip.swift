import SwiftUI

struct StatusChip: View {
    let status: MarkerStatus
    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.color(for: status).opacity(0.16), in: Capsule())
            .foregroundStyle(Theme.color(for: status))
            .accessibilityLabel("Status: \(status.label)")
    }
}
