/**
 * Nutrient–drug / nutrient–condition interaction screening (SPEC §2.4, §6.2).
 *
 * Every supplement suggestion must pass this gate before it can be shown. Fail-safe:
 * if the interaction table is not clinician-verified, we cannot vouch for safety, so we
 * SUPPRESS (SPEC §2.4, §11 "behind a flag").
 */
import type { SafetyConfig, UserProfile } from "./types.js";

export type InteractionAction = "allow" | "warn" | "suppress";

export interface InteractionDecision {
  nutrient: string;
  action: InteractionAction;
  notes: string[];
  matchedTriggers: { triggerType: "medication" | "condition"; triggerId: string }[];
  configVerified: boolean;
}

export function screenInteraction(
  nutrient: string,
  profile: UserProfile,
  config: SafetyConfig,
): InteractionDecision {
  const table = config.interactions;

  if (!table.verified) {
    return {
      nutrient,
      action: "suppress",
      notes: ["Interaction screening isn't certified yet, so this suggestion is withheld."],
      matchedTriggers: [],
      configVerified: false,
    };
  }

  const matches = table.entries.filter(
    (e) =>
      e.nutrient === nutrient &&
      ((e.triggerType === "medication" && profile.medications.includes(e.triggerId)) ||
        (e.triggerType === "condition" && profile.conditions.includes(e.triggerId))),
  );

  const matchedTriggers = matches.map((m) => ({
    triggerType: m.triggerType,
    triggerId: m.triggerId,
  }));

  const suppress = matches.filter((m) => m.action === "suppress");
  if (suppress.length > 0) {
    return {
      nutrient,
      action: "suppress",
      notes: suppress.map((m) => m.note),
      matchedTriggers,
      configVerified: true,
    };
  }

  const warn = matches.filter((m) => m.action === "warn");
  if (warn.length > 0) {
    return {
      nutrient,
      action: "warn",
      notes: warn.map((m) => m.note),
      matchedTriggers,
      configVerified: true,
    };
  }

  return { nutrient, action: "allow", notes: [], matchedTriggers: [], configVerified: true };
}
