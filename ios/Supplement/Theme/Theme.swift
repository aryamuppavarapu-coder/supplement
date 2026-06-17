import SwiftUI

/// Centralized look + app-name string so renaming "Supplement" later is a one-line change.
enum Theme {
    static let appName = "Supplement"
    static let accent = Color.accentColor

    // Status colors (kept calm + non-alarming per SPEC §2.1, except critical).
    static func color(for status: MarkerStatus) -> Color {
        switch status {
        case .low, .high: return .orange
        case .inRange: return .green
        case .criticalLow, .criticalHigh: return .red
        case .qualitative: return .blue
        case .indeterminate: return .gray
        }
    }
}

/// The persistent medical disclaimer (SPEC §2.5). Must appear on results + plan screens.
struct DisclaimerBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
            Text("Educational information, not medical advice or diagnosis. Always consult a licensed healthcare provider.")
                .font(.footnote)
        }
        .foregroundStyle(.secondary)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}
