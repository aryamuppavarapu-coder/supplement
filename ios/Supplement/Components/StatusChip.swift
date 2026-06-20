import SwiftUI

/// Compact status pill. In-range stays calm (soft green). Out-of-range is deliberately
/// alarming — a FILLED chip (red = high, yellow = low, deep red = critical) with a direction
/// icon — so a problem reads instantly at a glance.
struct StatusChip: View {
    let status: MarkerStatus

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .heavy))
            Text(status.label)
                .font(Theme.rounded(.caption2, weight: .heavy))
        }
        .foregroundStyle(style.fg)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(style.bg, in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(style.stroke, lineWidth: 1))
        .shadow(color: style.shadow, radius: style.filled ? 5 : 0, x: 0, y: style.filled ? 2 : 0)
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

    private struct ChipStyle {
        var fg: Color; var bg: Color; var stroke: Color; var shadow: Color; var filled: Bool
    }

    private var style: ChipStyle {
        switch status {
        case .inRange:
            let c = Color(hex: 0x2A8159)
            return ChipStyle(fg: c, bg: c.opacity(0.12), stroke: c.opacity(0.32), shadow: .clear, filled: false)
        case .low:
            // Filled warning yellow with dark text — clearly a caution.
            return ChipStyle(fg: Color(hex: 0x4A3700), bg: Color(hex: 0xF5C518),
                             stroke: Color(hex: 0xCFA300), shadow: Color(hex: 0xC9870A).opacity(0.35), filled: true)
        case .high:
            // Filled red with white text — reads as a problem.
            return ChipStyle(fg: .white, bg: Color(hex: 0xD23B2C),
                             stroke: Color(hex: 0xB02617), shadow: Color(hex: 0xD23B2C).opacity(0.4), filled: true)
        case .criticalLow, .criticalHigh:
            return ChipStyle(fg: .white, bg: Color(hex: 0xB02617),
                             stroke: Color(hex: 0x8A1B10), shadow: Color(hex: 0xB02617).opacity(0.5), filled: true)
        case .qualitative:
            return ChipStyle(fg: Theme.teal, bg: Theme.teal.opacity(0.12), stroke: Theme.teal.opacity(0.32), shadow: .clear, filled: false)
        case .indeterminate:
            return ChipStyle(fg: Theme.inkSoft, bg: Theme.inkSoft.opacity(0.12), stroke: Theme.inkSoft.opacity(0.3), shadow: .clear, filled: false)
        }
    }
}
