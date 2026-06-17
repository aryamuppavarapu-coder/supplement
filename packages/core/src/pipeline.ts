/**
 * Orchestrator: turns raw extracted markers into processed, flagged, validated markers
 * (SPEC §5.2–5.3, §8). Pure and deterministic — given the same input + config it always
 * returns the same result, which is what makes it unit-testable and auditable.
 */
import type {
  ExtractedMarker,
  ExtractedReport,
  ProcessedMarker,
  ProcessedReport,
  SafetyConfig,
} from "./types.js";
import { normalizeUnit } from "./units.js";
import { standardizeMarkerName } from "./markers.js";
import { flagMarker, isCriticalStatus } from "./flagging.js";
import {
  confidenceReason,
  indeterminateReason,
  labFlagCrossCheckReason,
  missingValueReason,
  plausibilityReason,
} from "./validation.js";

export function processMarker(extracted: ExtractedMarker, config: SafetyConfig): ProcessedMarker {
  const nameStd = standardizeMarkerName(extracted.nameRaw);
  const unitStd = normalizeUnit(extracted.unitRaw ?? null);
  const value = extracted.value ?? null;
  const refLow = extracted.refLow ?? null;
  const refHigh = extracted.refHigh ?? null;
  const refText = extracted.refText ?? null;
  const labFlag = extracted.labFlag ?? null;

  const { computedStatus, criticalConfigVerified } = flagMarker(
    { value, nameStd, unitStd, refLow, refHigh, refText },
    config,
  );

  const reviewReasons: string[] = [];
  for (const r of [
    confidenceReason(extracted.confidence),
    missingValueReason(value),
    plausibilityReason(nameStd, unitStd, value, config),
    labFlagCrossCheckReason(labFlag, computedStatus),
    indeterminateReason(computedStatus),
  ]) {
    if (r) reviewReasons.push(r);
  }

  return {
    nameRaw: extracted.nameRaw,
    nameStd,
    value,
    unitRaw: extracted.unitRaw ?? null,
    unitStd,
    refLow,
    refHigh,
    refText,
    labFlag,
    computedStatus,
    confidence: extracted.confidence,
    needsReview: reviewReasons.length > 0,
    reviewReasons,
    criticalConfigVerified,
  };
}

export function processReport(extracted: ExtractedReport, config: SafetyConfig): ProcessedReport {
  const markers = extracted.markers.map((m) => processMarker(m, config));
  const criticalMarkers = markers
    .filter((m) => isCriticalStatus(m.computedStatus))
    .map((m) => m.nameStd ?? m.nameRaw);

  return {
    markers,
    hasCritical: criticalMarkers.length > 0,
    criticalMarkers,
    needsHumanReview: markers.some((m) => m.needsReview),
  };
}
