/**
 * Supplement-plan gating (SPEC §2.3, §2.4, §3.4).
 *
 * This module decides WHICH nutrients may even be considered and whether each is
 * allowed / warned / suppressed. It produces NO dosing and NO copy — the wellness
 * rationale and food sources are generated later by the constrained LLM step
 * (SPEC §5.4), but only for candidates this gate marks `allow` or `warn`.
 *
 * The marker→nutrient hints below are wellness associations (education), reviewable and
 * intentionally conservative: a nutrient is only considered when its associated marker
 * is in the direction the nutrient relates to (e.g. low vitamin D → vitamin D).
 */
import type { ProcessedMarker, ProcessedReport, SafetyConfig, UserProfile } from "./types.js";
import { isCriticalStatus } from "./flagging.js";
import { screenInteraction, type InteractionAction } from "./interactions.js";
import type { Nutrient } from "./taxonomy.js";

interface NutrientHint {
  markerStd: string;
  whenStatus: Array<"low" | "high">;
  nutrient: Nutrient;
}

const NUTRIENT_HINTS: NutrientHint[] = [
  { markerStd: "vitamin_d_25oh", whenStatus: ["low"], nutrient: "vitamin_d" },
  { markerStd: "vitamin_b12", whenStatus: ["low"], nutrient: "vitamin_b12" },
  { markerStd: "folate", whenStatus: ["low"], nutrient: "folate" },
  { markerStd: "ferritin", whenStatus: ["low"], nutrient: "iron" },
  { markerStd: "iron", whenStatus: ["low"], nutrient: "iron" },
  { markerStd: "magnesium", whenStatus: ["low"], nutrient: "magnesium" },
  { markerStd: "calcium", whenStatus: ["low"], nutrient: "calcium" },
  { markerStd: "zinc", whenStatus: ["low"], nutrient: "zinc" },
  { markerStd: "triglycerides", whenStatus: ["high"], nutrient: "omega_3" },
];

export interface NutrientGateResult {
  nutrient: Nutrient;
  fromMarker: string;
  status: ProcessedMarker["computedStatus"];
  decision: InteractionAction;
  reasons: string[];
  interactionNotes: string[];
  matchedTriggers: { triggerType: "medication" | "condition"; triggerId: string }[];
}

export interface SupplementGate {
  /** false = the whole plan is withheld; see withheldReason. */
  enabled: boolean;
  withheldReason?: string;
  candidates: NutrientGateResult[];
}

export function buildSupplementGate(
  report: ProcessedReport,
  profile: UserProfile,
  config: SafetyConfig,
): SupplementGate {
  // SPEC §3.1: meds/conditions must be disclosed, or suggestions are withheld with a reason.
  if (!profile.disclosedMeds || !profile.disclosedConditions) {
    return {
      enabled: false,
      withheldReason:
        "Add your medications and diagnosed conditions in your profile so we can safely screen suggestions. Until then, supplement guidance is withheld.",
      candidates: [],
    };
  }

  // SPEC §2.4 / §11: without a clinician-verified interaction table, the whole plan is withheld.
  if (!config.interactions.verified) {
    return {
      enabled: false,
      withheldReason:
        "Supplement guidance is turned off until the interaction-safety data has been reviewed and certified by a clinician.",
      candidates: [],
    };
  }

  const candidates: NutrientGateResult[] = [];

  for (const m of report.markers) {
    if (!m.nameStd) continue;
    const hints = NUTRIENT_HINTS.filter((h) => h.markerStd === m.nameStd);
    if (hints.length === 0) continue;

    for (const hint of hints) {
      // SPEC §2.3: a critical value on this marker suppresses suggestions for its pathway.
      if (isCriticalStatus(m.computedStatus)) {
        candidates.push({
          nutrient: hint.nutrient,
          fromMarker: m.nameStd,
          status: m.computedStatus,
          decision: "suppress",
          reasons: [
            "A critical value is present for this marker. We're routing you to urgent care and won't suggest supplements for it (SPEC §2.3).",
          ],
          interactionNotes: [],
          matchedTriggers: [],
        });
        continue;
      }

      const statusMatches =
        (m.computedStatus === "low" && hint.whenStatus.includes("low")) ||
        (m.computedStatus === "high" && hint.whenStatus.includes("high"));
      if (!statusMatches) continue;

      // SPEC §2.4: interaction gate.
      const screen = screenInteraction(hint.nutrient, profile, config);
      candidates.push({
        nutrient: hint.nutrient,
        fromMarker: m.nameStd,
        status: m.computedStatus,
        decision: screen.action,
        reasons:
          screen.action === "suppress"
            ? ["Suppressed by interaction screening against your profile (SPEC §2.4)."]
            : screen.action === "warn"
              ? ["Flagged for caution by interaction screening — discuss with your provider (SPEC §2.4)."]
              : ["Passed interaction screening — still framed as 'discuss with your provider' (SPEC §2.1)."],
        interactionNotes: screen.notes,
        matchedTriggers: screen.matchedTriggers,
      });
    }
  }

  return { enabled: true, candidates };
}

/** Nutrients cleared to surface to the LLM copy step (allow or warn, never suppress). */
export function allowedNutrients(gate: SupplementGate): NutrientGateResult[] {
  return gate.candidates.filter((c) => c.decision !== "suppress");
}
