import SwiftUI
import RevenueCat

/// Freemium paywall (SPEC §3.7, §10.1) via RevenueCat wrapping StoreKit 2 (§7.6).
/// Free: first report analysis + basic breakdown. Paid: ongoing analyses, trends, full plans.
@Observable
final class PaywallModel {
    var packages: [Package] = []
    var busy = false
    var error: String?

    // Purchases.shared fatal-errors (uncatchable) if configure() was never called — which
    // happens in any build without a RevenueCat key set. Guard every access on isConfigured.
    func load() async {
        guard Purchases.isConfigured else {
            error = "Subscriptions aren't available in this build (no RevenueCat key configured)."
            return
        }
        do {
            let offerings = try await Purchases.shared.offerings()
            packages = offerings.current?.availablePackages ?? []
        } catch { self.error = error.localizedDescription }
    }

    func purchase(_ package: Package) async {
        guard Purchases.isConfigured else { return }
        busy = true; defer { busy = false }
        do { _ = try await Purchases.shared.purchase(package: package) }
        catch { self.error = error.localizedDescription }
    }

    func restore() async {
        guard Purchases.isConfigured else { return }
        busy = true; defer { busy = false }
        do { _ = try await Purchases.shared.restorePurchases() }
        catch { self.error = error.localizedDescription }
    }
}

struct PaywallView: View {
    @State private var model = PaywallModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Glossy hero
                GlassCard(cornerRadius: 24, padding: 22) {
                    VStack(spacing: 14) {
                        LogoMark(size: 72)
                        VStack(spacing: 6) {
                            Text("Supplement Plus")
                                .font(Theme.title(30))
                                .foregroundStyle(Theme.ink)
                            Text("Go further with your wellness journey.")
                                .font(Theme.rounded(.callout))
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // What's included
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel("What's included")
                        FeatureRow("Unlimited report analyses")
                        FeatureRow("Trends over time")
                        FeatureRow("Full food-first guidance & plans")
                    }
                }

                // Plans
                VStack(spacing: 12) {
                    if model.packages.isEmpty {
                        GlassCard {
                            HStack(spacing: 10) {
                                ProgressView().tint(Theme.sageDeep)
                                Text("Loading plans…")
                                    .font(Theme.rounded(.callout))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    ForEach(model.packages, id: \.identifier) { package in
                        Button {
                            Task { await model.purchase(package) }
                        } label: {
                            HStack {
                                Text(package.storeProduct.localizedTitle)
                                Spacer()
                                Text(package.storeProduct.localizedPriceString).bold()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.aero)
                        .disabled(model.busy)
                    }
                }

                Button("Restore purchases") { Task { await model.restore() } }
                    .buttonStyle(.aeroSoft)
                    .disabled(model.busy)

                if let error = model.error {
                    GlassCard(cornerRadius: 16, padding: 14) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Theme.color(for: .high))
                            Text(error)
                                .font(Theme.rounded(.footnote))
                                .foregroundStyle(Theme.ink)
                            Spacer(minLength: 0)
                        }
                    }
                }

                Text("Subscription renews automatically until cancelled. Manage in Settings.")
                    .font(Theme.rounded(.caption2))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            .padding(20)
        }
        .aeroScreen()
        .navigationTitle("Upgrade")
        .task { await model.load() }
    }
}

private struct FeatureRow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.sage)
            Text(text)
                .font(Theme.rounded(.body, weight: .medium))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}
