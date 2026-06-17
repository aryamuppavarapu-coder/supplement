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
            VStack(spacing: 16) {
                Text("Supplement Plus").font(.largeTitle.bold())
                FeatureRow("Unlimited report analyses")
                FeatureRow("Trends over time")
                FeatureRow("Full food-first guidance & plans")

                if model.packages.isEmpty {
                    Text("Loading plans…").foregroundStyle(.secondary)
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
                    .buttonStyle(.borderedProminent)
                }

                Button("Restore purchases") { Task { await model.restore() } }
                    .font(.footnote)

                if let error = model.error { Text(error).font(.footnote).foregroundStyle(.red) }

                Text("Subscription renews automatically until cancelled. Manage in Settings.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Upgrade")
        .task { await model.load() }
    }
}

private struct FeatureRow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack { Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.accent); Text(text); Spacer() }
    }
}
