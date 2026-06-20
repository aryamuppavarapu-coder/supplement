import SwiftUI

/// Explicitly-themed empty/placeholder state. Replaces SwiftUI's `ContentUnavailableView`,
/// whose title/description use SYSTEM label colors that render white on our fixed-light cards.
/// Everything here uses dark `Theme` tokens so it's always readable.
struct EmptyHint: View {
    let title: String
    let message: String
    var systemImage: String = "leaf"
    var tint: Color = Theme.sageDeep

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.tintFill)
                    .frame(width: 78, height: 78)
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(Theme.heading(19))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(.callout))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
