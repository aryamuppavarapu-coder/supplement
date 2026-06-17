/**
 * Unit canonicalization (SPEC §5.2 "Normalize units").
 *
 * IMPORTANT: flagging compares a value to the reference range printed on the SAME
 * report (SPEC §5.3), so the value and its range are already in the same unit — no
 * numeric conversion is needed to decide low/in-range/high. We only canonicalize the
 * unit *string* so it can be matched against the critical-value table (which is keyed
 * by a fixed `unitStd`) and so trends line up across labs. We deliberately do NOT do
 * cross-unit numeric conversion here: a wrong conversion factor is a safety event, and
 * any such table must be clinician-reviewed before use.
 */

const UNIT_CANONICAL: Record<string, string> = {
  "mg/dl": "mg/dL",
  "g/dl": "g/dL",
  "mcg/dl": "µg/dL",
  "ug/dl": "µg/dL",
  "ng/dl": "ng/dL",
  "ng/ml": "ng/mL",
  "pg/ml": "pg/mL",
  "mmol/l": "mmol/L",
  "umol/l": "µmol/L",
  "µmol/l": "µmol/L",
  "nmol/l": "nmol/L",
  "pmol/l": "pmol/L",
  "meq/l": "mEq/L",
  "miu/l": "mIU/L",
  "uiu/ml": "µIU/mL",
  "µiu/ml": "µIU/mL",
  "iu/l": "IU/L",
  "u/l": "U/L",
  "k/ul": "K/µL",
  "x10e3/ul": "K/µL",
  "10*3/ul": "K/µL",
  "m/ul": "M/µL",
  "x10e6/ul": "M/µL",
  "10*6/ul": "M/µL",
  "g/l": "g/L",
  "mg/l": "mg/L",
  "%": "%",
  "fl": "fL",
  "pg": "pg",
};

export function normalizeUnit(raw: string | null | undefined): string | null {
  if (raw === null || raw === undefined) return null;
  const trimmed = raw.trim();
  if (trimmed.length === 0) return null;
  const key = trimmed.toLowerCase().replace(/\s+/g, "");
  return UNIT_CANONICAL[key] ?? trimmed;
}
