/**
 * Core types for the deterministic safety engine.
 *
 * SPEC §4 (data model), §5.2–5.3 (validation/flagging), §6 (safety config).
 *
 * Design rule (SPEC §2.2): the LLM only *transcribes* (ExtractedMarker) and later
 * *explains* an already-computed result. Every field that decides high/low/critical
 * is produced by the deterministic functions in this package, never by a model.
 */

export type Confidence = "high" | "medium" | "low";

/**
 * Status computed by the engine (SPEC §5.3). `qualitative` is for non-numeric
 * results (e.g. "Negative"/"Positive"). `indeterminate` is an engine extension for
 * results we cannot evaluate (missing value or missing reference range) — it always
 * forces human confirmation rather than guessing "in range".
 */
export type ComputedStatus =
  | "low"
  | "in_range"
  | "high"
  | "critical_low"
  | "critical_high"
  | "qualitative"
  | "indeterminate";

/** Biological sex as captured at intake (SPEC §3.1). */
export type BiologicalSex = "male" | "female" | "intersex" | "unknown";

/**
 * Exactly the shape the extraction tool returns (SPEC §5.1 `record_lab_results`).
 * Values are transcribed as printed; nothing here is judged or normalized.
 */
export interface ExtractedMarker {
  nameRaw: string;
  value: number | null;
  unitRaw?: string | null;
  refLow?: number | null;
  refHigh?: number | null;
  refText?: string | null;
  /** The lab's own printed flag, e.g. "H", "L", "HH", "*". Used only to cross-check. */
  labFlag?: string | null;
  panel?: string | null;
  confidence: Confidence;
}

export interface ExtractedReport {
  labName?: string | null;
  reportDate?: string | null;
  collectionDate?: string | null;
  patientAge?: number | null;
  patientSex?: string | null;
  markers: ExtractedMarker[];
}

/**
 * Health profile (SPEC §3.1). `medications` and `conditions` are canonical ids
 * (see taxonomy.ts) used by the interaction engine. `disclosedMeds`/`disclosedConditions`
 * record whether the user actually answered those intake questions — if not, supplement
 * suggestions are withheld and the app explains why (SPEC §3.1).
 */
export interface UserProfile {
  age?: number | null;
  sex?: BiologicalSex | null;
  pregnant?: boolean | null;
  heightCm?: number | null;
  weightKg?: number | null;
  medications: string[];
  conditions: string[];
  disclosedMeds: boolean;
  disclosedConditions: boolean;
}

/** Output of the engine for a single marker. */
export interface ProcessedMarker {
  nameRaw: string;
  nameStd: string | null;
  value: number | null;
  unitRaw: string | null;
  unitStd: string | null;
  refLow: number | null;
  refHigh: number | null;
  refText: string | null;
  labFlag: string | null;
  computedStatus: ComputedStatus;
  confidence: Confidence;
  /** True when the value should be confirmed/corrected by the user before analysis (SPEC §3.2). */
  needsReview: boolean;
  /** Human-readable reasons for needsReview / validation notes. */
  reviewReasons: string[];
  /** Whether the critical decision (if any) was based on a clinician-verified table (SPEC §6.1). */
  criticalConfigVerified: boolean;
}

export interface ProcessedReport {
  markers: ProcessedMarker[];
  /** True if any marker is critical_low/critical_high — pins the urgent banner (SPEC §2.3). */
  hasCritical: boolean;
  /** markerStd values (or nameRaw if unstandardized) in a critical state. */
  criticalMarkers: string[];
  /** True if any marker needs human confirmation (SPEC §3.2). */
  needsHumanReview: boolean;
}

// ── Safety configuration tables (SPEC §6) ───────────────────────────────────

/** SPEC §6.1 critical-value table entry. */
export interface CriticalValueEntry {
  markerStd: string;
  unitStd: string;
  criticalLow: number | null;
  criticalHigh: number | null;
  sourceRef: string;
  reviewedBy: string | null;
  reviewedAt: string | null;
}

/** SPEC §6.2 nutrient–drug / nutrient–condition interaction entry. */
export interface InteractionEntry {
  nutrient: string;
  triggerType: "medication" | "condition";
  /** Canonical medication-class or condition id (see taxonomy.ts). */
  triggerId: string;
  action: "suppress" | "warn";
  note: string;
  sourceRef: string;
  reviewedBy: string | null;
  reviewedAt: string | null;
}

/** Plausibility bounds used to catch a misread decimal (a safety event — SPEC §5.2). */
export interface PlausibilityEntry {
  markerStd: string;
  unitStd: string;
  min: number;
  max: number;
  sourceRef: string;
  reviewedBy: string | null;
  reviewedAt: string | null;
}

/**
 * A safety table plus its provenance. `verified` is false until a qualified human
 * has reviewed the data (SPEC §0, §6, §12). The engine treats unverified tables as
 * fail-safe (see plan.ts / flagging.ts).
 */
export interface SafetyTable<T> {
  verified: boolean;
  entries: T[];
}

export interface SafetyConfig {
  criticalValues: SafetyTable<CriticalValueEntry>;
  interactions: SafetyTable<InteractionEntry>;
  plausibility: SafetyTable<PlausibilityEntry>;
}
