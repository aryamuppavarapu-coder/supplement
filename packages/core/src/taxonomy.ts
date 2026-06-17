/**
 * Canonical ids shared by the intake UI, the interaction table (SPEC §6.2), and the
 * engine. Keeping these in one place means the app's pickers and the safety table can
 * never drift apart.
 *
 * ⚠️ These are *categories for matching*, not clinical facts. The actual interaction
 * rules (which nutrient + which trigger → suppress/warn) live in config/interactions.json
 * and must be confirmed by a clinician/pharmacist (SPEC §6.2). Expand as needed.
 */

/** Medication classes a user can disclose at intake. */
export const MEDICATION_CLASSES = [
  "anticoagulant", // e.g. warfarin and similar
  "antiplatelet",
  "ace_inhibitor",
  "arb",
  "potassium_sparing_diuretic",
  "loop_diuretic",
  "thiazide_diuretic",
  "thyroid_hormone",
  "levothyroxine",
  "statin",
  "metformin",
  "ppi", // proton-pump inhibitor
  "diabetes_other",
  "immunosuppressant",
  "chemotherapy",
  "lithium",
  "digoxin",
  "iron_supplement",
  "other",
] as const;
export type MedicationClass = (typeof MEDICATION_CLASSES)[number];

/** Diagnosed conditions a user can disclose at intake (SPEC §3.1 examples). */
export const CONDITIONS = [
  "ckd", // chronic kidney disease
  "kidney_disease_advanced",
  "thyroid_disorder",
  "hyperthyroidism",
  "hypothyroidism",
  "hemochromatosis", // iron overload
  "liver_disease",
  "heart_failure",
  "hypertension",
  "diabetes_type1",
  "diabetes_type2",
  "pregnancy",
  "g6pd_deficiency",
  "other",
] as const;
export type Condition = (typeof CONDITIONS)[number];

/** Nutrients/supplements the plan can consider (SPEC §3.4). */
export const NUTRIENTS = [
  "vitamin_d",
  "vitamin_b12",
  "folate",
  "iron",
  "ferritin_iron",
  "magnesium",
  "potassium",
  "calcium",
  "vitamin_k",
  "omega_3",
  "zinc",
  "vitamin_b6",
  "vitamin_c",
] as const;
export type Nutrient = (typeof NUTRIENTS)[number];

export function isMedicationClass(x: string): x is MedicationClass {
  return (MEDICATION_CLASSES as readonly string[]).includes(x);
}
export function isCondition(x: string): x is Condition {
  return (CONDITIONS as readonly string[]).includes(x);
}
export function isNutrient(x: string): x is Nutrient {
  return (NUTRIENTS as readonly string[]).includes(x);
}
