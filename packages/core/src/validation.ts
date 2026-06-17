/**
 * Deterministic validation (SPEC §5.2). Produces human-readable reasons that flip a
 * marker to `needsReview` so the user confirms/corrects it before analysis (SPEC §3.2).
 * Never auto-corrects a value — a misread decimal is a safety event, so we ask, we
 * don't guess.
 */
import type { ComputedStatus, Confidence, SafetyConfig } from "./types.js";

export function confidenceReason(confidence: Confidence): string | null {
  if (confidence === "low") {
    return "Low extraction confidence — please confirm this value matches your report.";
  }
  return null;
}

export function missingValueReason(value: number | null): string | null {
  if (value === null) return "This value couldn't be read — please enter it from your report.";
  return null;
}

export function indeterminateReason(status: ComputedStatus): string | null {
  if (status === "indeterminate") {
    return "No usable reference range was found for this marker — status can't be computed; please confirm the value and range.";
  }
  return null;
}

/**
 * Plausibility check (SPEC §5.2). Requires a clinician-verified bounds table; without
 * one we can't claim a value is implausible, so we skip silently.
 */
export function plausibilityReason(
  nameStd: string | null,
  unitStd: string | null,
  value: number | null,
  config: SafetyConfig,
): string | null {
  if (value === null || !nameStd || !unitStd) return null;
  if (!config.plausibility.verified) return null;
  const entry = config.plausibility.entries.find(
    (p) => p.markerStd === nameStd && p.unitStd === unitStd,
  );
  if (!entry) return null;
  if (value < entry.min || value > entry.max) {
    return "This value looks outside the physiologically plausible range — it may be a typo or a misread decimal. Please re-check it.";
  }
  return null;
}

/**
 * Cross-check the lab's own printed flag against our computed status (SPEC §5.2).
 * A disagreement doesn't override anything — it just asks the user to confirm.
 */
export function labFlagCrossCheckReason(
  labFlag: string | null,
  computed: ComputedStatus,
): string | null {
  if (!labFlag) return null;
  const f = labFlag.trim().toUpperCase();
  const HIGH = new Set(["H", "HH", "H*", "*H", "HIGH", "ABNORMAL HIGH"]);
  const LOW = new Set(["L", "LL", "L*", "*L", "LOW", "ABNORMAL LOW"]);
  const computedHigh = computed === "high" || computed === "critical_high";
  const computedLow = computed === "low" || computed === "critical_low";
  if (HIGH.has(f) && !computedHigh) {
    return "The lab marked this High, but the computed status differs — please confirm the value and reference range.";
  }
  if (LOW.has(f) && !computedLow) {
    return "The lab marked this Low, but the computed status differs — please confirm the value and reference range.";
  }
  return null;
}
