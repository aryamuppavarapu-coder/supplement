/**
 * ⚠️ ILLUSTRATIVE SAFETY CONFIG — NOT CLINICIAN-REVIEWED (SPEC §6, §12).
 *
 * This exists so the supplement-guidance feature is FUNCTIONAL in development/demo. The
 * deployed functions don't ship the repo's /config/*.json, so this embedded config is the
 * fallback the engine uses. Every value here is illustrative and plausible but UNVERIFIED.
 *
 * Before any real launch:
 *   1. A clinician/pharmacist reviews + replaces every entry (and sets real reviewedBy/reviewedAt).
 *   2. Remove the ALLOW_UNPROVENANCED_CONFIG dev flag (functions/.env) so the provenance audit
 *      (safetyConfig.ts) enforces fail-safe again.
 *
 * reviewedBy/reviewedAt are intentionally null so the audit + logs flag this as unverified.
 */
import type { SafetyConfig } from "@supplement/core";

const SRC = "ILLUSTRATIVE — not clinician-reviewed; replace before launch (SPEC §6/§12)";

export const DEFAULT_SAFETY_CONFIG: SafetyConfig = {
  // §6.2 nutrient–drug / nutrient–condition screening. Gates every supplement suggestion.
  interactions: {
    verified: true,
    entries: [
      { nutrient: "vitamin_k", triggerType: "medication", triggerId: "anticoagulant", action: "suppress", note: "Vitamin K can counteract blood-thinner (anticoagulant) medications — don't supplement without your prescriber.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "omega_3", triggerType: "medication", triggerId: "anticoagulant", action: "warn", note: "High-dose omega-3 may add to a blood-thinner's effect — keep doses modest and tell your provider.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "iron", triggerType: "condition", triggerId: "hemochromatosis", action: "suppress", note: "Iron is generally contraindicated in iron-overload conditions.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "iron", triggerType: "medication", triggerId: "ppi", action: "warn", note: "Acid-reducing medications lower iron absorption — discuss timing with your pharmacist.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "potassium", triggerType: "condition", triggerId: "ckd", action: "warn", note: "Potassium needs care with reduced kidney function — discuss with your provider.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "potassium", triggerType: "condition", triggerId: "kidney_disease_advanced", action: "suppress", note: "Supplemental potassium can be dangerous with advanced kidney disease.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "potassium", triggerType: "medication", triggerId: "potassium_sparing_diuretic", action: "warn", note: "Potassium-sparing diuretics already raise potassium — don't add more without your provider.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "magnesium", triggerType: "condition", triggerId: "kidney_disease_advanced", action: "warn", note: "Magnesium can accumulate with advanced kidney disease — discuss first.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "calcium", triggerType: "medication", triggerId: "thiazide_diuretic", action: "warn", note: "Thiazide diuretics can raise calcium — be cautious adding more.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "calcium", triggerType: "medication", triggerId: "levothyroxine", action: "warn", note: "Calcium can reduce thyroid-medication absorption — separate them by several hours.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { nutrient: "iron", triggerType: "medication", triggerId: "levothyroxine", action: "warn", note: "Iron can reduce thyroid-medication absorption — separate them by several hours.", sourceRef: SRC, reviewedBy: null, reviewedAt: null },
    ],
  },
  // §6.1 critical-value escalation (pins the urgent-care banner + suppresses that pathway).
  criticalValues: {
    verified: true,
    entries: [
      { markerStd: "potassium", unitStd: "mmol/L", criticalLow: 2.5, criticalHigh: 6.5, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { markerStd: "sodium", unitStd: "mmol/L", criticalLow: 120, criticalHigh: 160, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { markerStd: "glucose", unitStd: "mg/dL", criticalLow: 40, criticalHigh: 500, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { markerStd: "calcium", unitStd: "mg/dL", criticalLow: 6.0, criticalHigh: 13.0, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { markerStd: "hemoglobin", unitStd: "g/dL", criticalLow: 7.0, criticalHigh: 20.0, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
    ],
  },
  // §5.2 plausibility bounds (catch a misread decimal). Generous, not diagnostic.
  plausibility: {
    verified: true,
    entries: [
      { markerStd: "potassium", unitStd: "mmol/L", min: 1.0, max: 10.0, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { markerStd: "sodium", unitStd: "mmol/L", min: 90, max: 200, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { markerStd: "glucose", unitStd: "mg/dL", min: 10, max: 2000, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
      { markerStd: "hemoglobin", unitStd: "g/dL", min: 2, max: 25, sourceRef: SRC, reviewedBy: null, reviewedAt: null },
    ],
  },
};
