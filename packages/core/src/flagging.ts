/**
 * Deterministic flagging (SPEC §2.2, §5.3).
 *
 * The LLM never runs this. Status is computed purely by comparing the transcribed
 * value to the reference range printed on the report, then (only if a clinician-verified
 * critical table says so) escalated to critical.
 */
import type { ComputedStatus, SafetyConfig, CriticalValueEntry } from "./types.js";

export interface FlagInput {
  value: number | null;
  nameStd: string | null;
  unitStd: string | null;
  refLow: number | null;
  refHigh: number | null;
  refText: string | null;
}

export interface FlagResult {
  computedStatus: ComputedStatus;
  /** Whether the critical decision was based on a clinician-verified table (SPEC §6.1). */
  criticalConfigVerified: boolean;
}

/** Compare value to the report's own reference range. No critical logic here. */
export function computeBaseStatus(
  value: number | null,
  refLow: number | null,
  refHigh: number | null,
  refText: string | null,
): ComputedStatus {
  if (value === null || !Number.isFinite(value)) {
    // Non-numeric result with descriptive text (e.g. "Negative") is qualitative.
    if (refText && refText.trim().length > 0) return "qualitative";
    return "indeterminate";
  }
  const hasLow = typeof refLow === "number" && Number.isFinite(refLow);
  const hasHigh = typeof refHigh === "number" && Number.isFinite(refHigh);
  if (!hasLow && !hasHigh) return "indeterminate"; // nothing to compare against
  if (hasLow && value < (refLow as number)) return "low";
  if (hasHigh && value > (refHigh as number)) return "high";
  return "in_range";
}

export function findCriticalEntry(
  nameStd: string | null,
  unitStd: string | null,
  config: SafetyConfig,
): CriticalValueEntry | null {
  if (!nameStd || !unitStd) return null;
  return (
    config.criticalValues.entries.find(
      (e) => e.markerStd === nameStd && e.unitStd === unitStd,
    ) ?? null
  );
}

export function flagMarker(input: FlagInput, config: SafetyConfig): FlagResult {
  const base = computeBaseStatus(input.value, input.refLow, input.refHigh, input.refText);
  const criticalConfigVerified = config.criticalValues.verified === true;

  // Critical escalation only fires on FINITE numeric values AND only with a clinician-verified
  // table (SPEC §2.3 / §11). We do NOT raise urgent alarms from placeholder numbers, and the
  // finiteness guard mirrors computeBaseStatus so a non-finite value (e.g. ±Infinity) can never
  // be escalated to a false critical while its base status is "indeterminate".
  if (input.value === null || !Number.isFinite(input.value) || !criticalConfigVerified) {
    return { computedStatus: base, criticalConfigVerified };
  }

  const entry = findCriticalEntry(input.nameStd, input.unitStd, config);
  if (!entry) return { computedStatus: base, criticalConfigVerified };

  if (entry.criticalLow !== null && (input.value as number) <= entry.criticalLow) {
    return { computedStatus: "critical_low", criticalConfigVerified };
  }
  if (entry.criticalHigh !== null && (input.value as number) >= entry.criticalHigh) {
    return { computedStatus: "critical_high", criticalConfigVerified };
  }
  return { computedStatus: base, criticalConfigVerified };
}

export function isCriticalStatus(s: ComputedStatus): boolean {
  return s === "critical_low" || s === "critical_high";
}
