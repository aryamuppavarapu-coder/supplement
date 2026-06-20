import SwiftUI

/// Plan screen (SPEC §3.4, §2.1–2.4). Two layers:
///  1. GENERAL wellness ideas — deterministic, food-first education from each out-of-range,
///     non-critical marker. Always available (not a supplement suggestion), so the screen is
///     useful even when the screened gate clears nothing.
///  2. SCREENED supplement suggestions — gated server-side by interaction screening (§2.4),
///     critical-suppressed (§2.3), withheld with a reason when the gate says so.
struct SupplementPlanView: View {
    let plan: SupplementPlan?
    let hasCritical: Bool
    var markers: [Marker] = []

    private var generalTips: [GeneralTip] { MarkerGuidance.tips(for: markers) }
    private var screenedItems: [PlanItem] {
        guard let plan, plan.enabled else { return [] }
        return plan.items.filter { $0.decision != "suppress" }
    }
    private var suppressedCount: Int { plan?.items.filter { $0.decision == "suppress" }.count ?? 0 }

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
        header

        // ── General wellness ideas (food-first, always available) ──────────────
        if !generalTips.isEmpty {
            SectionLabel("General wellness ideas").padding(.horizontal, 4)
            ForEach(generalTips) { GeneralTipCard(tip: $0) }
        }

        // ── Screened supplement suggestions ────────────────────────────────────
        if let plan {
            if plan.enabled {
                if !screenedItems.isEmpty {
                    SectionLabel("Supplements to discuss").padding(.horizontal, 4)
                    illustrativeNotice
                    ForEach(screenedItems) { item in PlanItemCard(item: item) }
                    affiliateNotice
                }
            } else {
                withheld(plan.withheldReason)
            }
        } else if generalTips.isEmpty {
            // Plan still loading and we have no marker-derived tips yet.
            GlassCard {
                HStack(spacing: 12) {
                    ProgressView().tint(Theme.sageDeep)
                    Text("Preparing your plan…")
                        .font(Theme.rounded(.callout, weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }

        // All candidate supplements were screened out by interaction screening (§2.4 transparency).
        if (plan?.enabled ?? false) && screenedItems.isEmpty && suppressedCount > 0 {
            GlassCard(cornerRadius: 16, padding: 14) {
                Label {
                    Text("Some supplement ideas were screened out based on the medications or conditions you shared — that's for your safety. Talk with your doctor or pharmacist about options.")
                        .font(Theme.rounded(.footnote, weight: .medium))
                        .foregroundStyle(Theme.ink)
                } icon: {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Theme.sageDeep)
                }
            }
        }

        // Markers loaded and all in range — still give a positive maintenance plan (never blank).
        if !markers.isEmpty && generalTips.isEmpty && screenedItems.isEmpty && suppressedCount == 0 {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color(hex: 0x2A8159).opacity(0.14)).frame(width: 40, height: 40)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x2A8159))
                        }
                        Text("Your markers look on track")
                            .font(Theme.heading(17))
                            .foregroundStyle(Theme.ink)
                        Spacer(minLength: 0)
                    }
                    Text("Nothing is out of range right now. To keep it that way, everyday wellness habits help — and many people discuss a daily multivitamin or vitamin D with their provider.")
                        .font(Theme.rounded(.callout))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel("Everyday basics")
                        Text("Colorful vegetables  ·  Whole grains  ·  Regular activity  ·  Hydration  ·  Sleep")
                            .font(Theme.rounded(.callout, weight: .medium))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }

        DisclaimerBanner()
    }

    private var header: some View {
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
                    Text("General wellness ideas tied to your out-of-range markers — not prescriptions or a diagnosis. Discuss anything you're considering with your doctor or pharmacist.")
                        .font(Theme.rounded(.callout))
                        .foregroundStyle(Theme.inkSoft)
                } icon: {
                    Image(systemName: "leaf.fill").foregroundStyle(Theme.sage)
                }
                if hasCritical {
                    Label {
                        Text("Some values need prompt medical attention — we've paused supplement suggestions for those and routed you to care.")
                            .font(Theme.rounded(.footnote, weight: .medium))
                            .foregroundStyle(Theme.ink)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.color(for: .criticalHigh))
                    }
                }
            }
        }
    }

    private var illustrativeNotice: some View {
        GlassCard(cornerRadius: 16, padding: 14) {
            Label {
                Text("These supplement ideas currently use **illustrative** safety data for development — not yet clinician-reviewed. Always confirm with your doctor or pharmacist before taking anything.")
                    .font(Theme.rounded(.footnote, weight: .medium))
                    .foregroundStyle(Theme.ink)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.amber)
            }
        }
    }

    private var affiliateNotice: some View {
        GlassCard {
            Label {
                Text("Affiliate disclosure: some supplement links may be affiliate links. We only surface products with third-party quality testing. (⚠️ partner terms pending — SPEC §10.2.)")
                    .font(Theme.rounded(.caption2))
                    .foregroundStyle(Theme.inkSoft)
            } icon: {
                Image(systemName: "sparkles").foregroundStyle(Theme.aqua)
            }
        }
    }

    @ViewBuilder
    private func withheld(_ reason: String?) -> some View {
        GlassCard(cornerRadius: 16, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Specific supplement suggestions are paused")
                        .font(Theme.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                } icon: {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Theme.sageDeep)
                }
                Text(reason ?? "Add your medications and conditions in your profile so we can screen suggestions safely.")
                    .font(Theme.rounded(.footnote))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }
}

/// A general, food-first wellness idea derived from one out-of-range marker.
private struct GeneralTipCard: View {
    let tip: GeneralTip

    var body: some View {
        // Colored wash keeps the high/low cue; the icon itself uses a darker shade so it reads (AA).
        let wash = tip.isHigh ? Color(hex: 0xD23B2C) : Color(hex: 0xC9870A)
        let iconColor = tip.isHigh ? Color(hex: 0xB02617) : Color(hex: 0x8B5F0A)
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(wash.opacity(0.16)).frame(width: 40, height: 40)
                        Image(systemName: tip.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                    Text(tip.title)
                        .font(Theme.heading(17))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                }

                Text(tip.body)
                    .font(Theme.rounded(.callout))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                if !tip.foods.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel("Food-first ideas")
                        Text(tip.foods.joined(separator: "  ·  "))
                            .font(Theme.rounded(.callout, weight: .medium))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
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
                            .foregroundStyle(Theme.amber)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Theme.amber.opacity(0.14), in: Capsule())
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
                        .foregroundStyle(Theme.amber)
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
            .background(Theme.teal.opacity(0.12), in: Capsule())
            .foregroundStyle(Theme.teal)
            .overlay(Capsule().stroke(Theme.teal.opacity(0.3), lineWidth: 1))
    }
}
