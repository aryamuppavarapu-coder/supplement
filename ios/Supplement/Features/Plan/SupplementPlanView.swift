import SwiftUI

/// Gated supplement + food plan (SPEC §3.4, §2.3, §2.4). Food first, supplements second,
/// quality cert badges, and a "discuss with your provider" CTA. If the gate withheld the
/// plan (no disclosure, unverified safety config, or critical values) we say exactly why.
struct SupplementPlanView: View {
    let plan: SupplementPlan?
    let hasCritical: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding()
        }
        .navigationTitle("Your plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if let plan {
            if plan.enabled {
                enabledContent(plan)
            } else {
                withheld(plan.withheldReason)
            }
        } else {
            ProgressView("Preparing your plan…")
        }
    }

    @ViewBuilder
    private func enabledContent(_ plan: SupplementPlan) -> some View {
        let shown = plan.items.filter { $0.decision != "suppress" }

        Text("Food first, then optional supplements")
            .font(.title3.bold())
        Text("These are general wellness ideas tied to your out-of-range markers — not prescriptions. Discuss anything you're considering with your doctor or pharmacist.")
            .font(.callout).foregroundStyle(.secondary)

        if shown.isEmpty {
            ContentUnavailableView(
                "Nothing to suggest right now",
                systemImage: "leaf",
                description: Text("No out-of-range markers mapped to a wellness suggestion, or all were screened out for your safety.")
            )
        }

        ForEach(shown) { item in PlanItemCard(item: item) }

        Text("Affiliate disclosure: some supplement links may be affiliate links. We only surface products with third-party quality testing. (⚠️ partner terms pending — SPEC §10.2.)")
            .font(.caption2).foregroundStyle(.secondary)

        DisclaimerBanner()
    }

    @ViewBuilder
    private func withheld(_ reason: String?) -> some View {
        Label("Suggestions are turned off", systemImage: "hand.raised").font(.headline)
        Text(reason ?? "We can't safely show suggestions right now.")
        DisclaimerBanner()
    }
}

private struct PlanItemCard: View {
    let item: PlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(displayName).font(.headline)
                Spacer()
                if item.decision == "warn" {
                    Label("Use caution", systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                }
            }

            if let rationale = item.rationaleText { Text(rationale).font(.callout) }

            if !item.foodSources.isEmpty {
                Text("Food sources first").font(.subheadline.bold())
                Text(item.foodSources.joined(separator: " · ")).font(.callout).foregroundStyle(.secondary)
            }

            if let note = item.interactionNote, !note.isEmpty {
                Label(note, systemImage: "info.circle").font(.caption).foregroundStyle(.orange)
            }

            HStack(spacing: 6) {
                CertBadge("USP Verified")
                CertBadge("NSF Certified")
                CertBadge("Informed Sport")
            }

            Button { /* TODO: Fullscript/affiliate deep link — ⚠️ VERIFY partner (SPEC §10.2) */ } label: {
                Label("Discuss with your provider", systemImage: "stethoscope")
            }
            .font(.footnote)
            .disabled(true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var displayName: String {
        item.nutrient.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private struct CertBadge: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Theme.accent.opacity(0.12), in: Capsule())
            .foregroundStyle(Theme.accent)
    }
}
