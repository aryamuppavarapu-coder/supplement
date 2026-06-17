/**
 * Marker-name standardization (SPEC §4 `nameStd`).
 *
 * Maps common printed names/aliases to a canonical key so the critical-value table,
 * interaction hints, and trends can line up. Best-effort: an unknown marker returns
 * null and is still flagged against the reference range printed on its own report
 * (which needs no standardization). This dictionary is safe to expand.
 */

const ALIASES: Record<string, string> = {
  // Vitamins
  "vitamin d": "vitamin_d_25oh",
  "vitamin d 25 hydroxy": "vitamin_d_25oh",
  "25 hydroxyvitamin d": "vitamin_d_25oh",
  "25 oh vitamin d": "vitamin_d_25oh",
  "vitamin d 25-hydroxy": "vitamin_d_25oh",
  "vitamin b12": "vitamin_b12",
  b12: "vitamin_b12",
  cobalamin: "vitamin_b12",
  folate: "folate",
  "folic acid": "folate",
  "vitamin b9": "folate",
  "vitamin b6": "vitamin_b6",
  // Iron studies
  ferritin: "ferritin",
  iron: "iron",
  "serum iron": "iron",
  tibc: "tibc",
  transferrin: "transferrin",
  // Electrolytes / minerals
  potassium: "potassium",
  sodium: "sodium",
  magnesium: "magnesium",
  calcium: "calcium",
  zinc: "zinc",
  // Thyroid
  tsh: "tsh",
  "thyroid stimulating hormone": "tsh",
  "free t4": "free_t4",
  "free t3": "free_t3",
  // CBC
  hemoglobin: "hemoglobin",
  haemoglobin: "hemoglobin",
  hgb: "hemoglobin",
  hb: "hemoglobin",
  hematocrit: "hematocrit",
  haematocrit: "hematocrit",
  hct: "hematocrit",
  // Metabolic
  glucose: "glucose",
  "fasting glucose": "glucose",
  hba1c: "hba1c",
  "hemoglobin a1c": "hba1c",
  a1c: "hba1c",
  // Lipids
  "total cholesterol": "total_cholesterol",
  cholesterol: "total_cholesterol",
  ldl: "ldl_cholesterol",
  "ldl cholesterol": "ldl_cholesterol",
  "ldl-c": "ldl_cholesterol",
  hdl: "hdl_cholesterol",
  "hdl cholesterol": "hdl_cholesterol",
  triglycerides: "triglycerides",
  // Renal / hepatic
  creatinine: "creatinine",
  egfr: "egfr",
  "estimated gfr": "egfr",
  alt: "alt",
  sgpt: "alt",
  ast: "ast",
  sgot: "ast",
  // Inflammation
  crp: "crp",
  "c reactive protein": "crp",
  "hs crp": "crp",
};

export function standardizeMarkerName(nameRaw: string | null | undefined): string | null {
  if (!nameRaw) return null;
  const normalized = nameRaw
    .trim()
    .toLowerCase()
    .replace(/[.,()/\\:;*]/g, " ")
    .replace(/[-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  if (normalized.length === 0) return null;
  return ALIASES[normalized] ?? null;
}
