import SwiftUI

/// Gated supplement + food plan (SPEC §3.4, §2.3, §2.4). Food first, supplements second,
/// quality cert badges, and a "discuss with your provider" CTA. If the gate withheld the
/// plan (no disclosure, unverified safety config, or critical values) we say exactly why.
struct SupplementPlanView: View {
    let plan: SupplementPlan?
    let hasCritical: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding()
        }
        .aeroScreen()
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
            GlassCard {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(Theme.sageDeep)
                    Text("Preparing your plan…")
                        .font(Theme.rounded(.callout, weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    @ViewBuilder
    private func enabledContent(_ plan: SupplementPlan) -> some View {
        let shown = plan.items.filter { $0.decision != "suppress" }

        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    LogoMark(size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel("Your wellness plan")
                        Text("Food first, then optional supplements")
                            .font(Theme.heading(20))
                            .foregroundStyle(Theme.ink)
                    }
                }

                Label {
                    Text("These are general wellness ideas tied to your out-of-range markers — not prescriptions. Discuss anything you're considering with your doctor or pharmacist.")
                        .font(Theme.rounded(.callout))
                        .foregroundStyle(Theme.inkSoft)
                } icon: {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Theme.sage)
                }
            }
        }

        if shown.isEmpty {
            GlassCard {
                ContentUnavailableView(
                    "Nothing to suggest right now",
                    systemImage: "leaf",
                    description: Text("No out-of-range markers mapped to a wellness suggestion, or all were screened out for your safety.")
                )
            }
        }

        ForEach(shown) { item in PlanItemCard(item: item) }

        GlassCard {
            Label {
                Text("Affiliate disclosure: some supplement links may be affiliate links. We only surface products with third-party quality testing. (⚠️ partner terms pending — SPEC §10.2.)")
                    .font(Theme.rounded(.caption2))
                    .foregroundStyle(Theme.inkSoft)
            } icon: {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.aqua)
            }
        }

        DisclaimerBanner()
    }

    @ViewBuilder
    private func withheld(_ reason: String?) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Suggestions are turned off")
                        .font(Theme.heading(20))
                        .foregroundStyle(Theme.ink)
                } icon: {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(Theme.sageDeep)
                }

                Text(reason ?? "We can't safely show suggestions right now.")
                    .font(Theme.rounded(.callout))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        DisclaimerBanner()
    }
}

private struct PlanItemCard: View {
    let item: PlanItem

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label {
                        Text(displayName)
                            .font(Theme.heading(18))
                            .foregroundStyle(Theme.ink)
                    } icon: {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(Theme.sage)
                    }
                    Spacer()
                    if item.decision == "warn" {
                        Label("Use caution", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(.caption, weight: .semibold))
                            .foregroundStyle(Theme.color(for: .high))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Theme.color(for: .high).opacity(0.14), in: Capsule())
                    }
                }

                if let rationale = item.rationaleText {
                    Text(rationale)
                        .font(Theme.rounded(.callout))
                        .foregroundStyle(Theme.ink)
                }

                if !item.foodSources.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel("Food sources first")
                        Text(item.foodSources.joined(separator: " · "))
                            .font(Theme.rounded(.callout))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }

                if let note = item.interactionNote, !note.isEmpty {
                    Label(note, systemImage: "info.circle.fill")
                        .font(Theme.rounded(.caption, weight: .medium))
                        .foregroundStyle(Theme.color(for: .high))
                }

                HStack(spacing: 6) {
                    CertBadge("USP Verified")
                    CertBadge("NSF Certified")
                    CertBadge("Informed Sport")
                }

                Button { /* TODO: Fullscript/affiliate deep link — ⚠️ VERIFY partner (SPEC §10.2) */ } label: {
                    Label("Discuss with your provider", systemImage: "stethoscope")
                }
                .buttonStyle(.aeroSoft)
                .disabled(true)
            }
        }
    }

    private var displayName: String {
        item.nutrient.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private struct CertBadge: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Label(text, systemImage: "checkmark.seal.fill")
            .font(Theme.rounded(.caption2, weight: .semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Theme.tintFill, in: Capsule())
            .foregroundStyle(Theme.sageDeep)
            .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
    }
}
