/** Firestore <-> engine shape mapping. */
import type { BiologicalSex, UserProfile } from "@supplement/core";

export function toUserProfile(data: FirebaseFirestore.DocumentData | undefined): UserProfile {
  const p = (data?.profile ?? {}) as Record<string, unknown>;
  const sex = (p.sex as BiologicalSex) ?? "unknown";
  return {
    age: typeof p.age === "number" ? p.age : null,
    sex,
    pregnant: typeof p.pregnant === "boolean" ? p.pregnant : null,
    heightCm: typeof p.heightCm === "number" ? p.heightCm : null,
    weightKg: typeof p.weightKg === "number" ? p.weightKg : null,
    medications: Array.isArray(data?.medications) ? (data!.medications as string[]) : [],
    conditions: Array.isArray(data?.conditions) ? (data!.conditions as string[]) : [],
    // Disclosure is explicit: the intake step sets these flags so we know the user
    // actually answered (vs. left blank). Withhold suggestions if not disclosed (SPEC §3.1).
    disclosedMeds: data?.disclosedMeds === true,
    disclosedConditions: data?.disclosedConditions === true,
  };
}
