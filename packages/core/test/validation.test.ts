import { describe, expect, it } from "vitest";
import {
  confidenceReason,
  indeterminateReason,
  labFlagCrossCheckReason,
  missingValueReason,
  plausibilityReason,
  EMPTY_CONFIG,
} from "../src/index.js";
import { verifiedConfig } from "./helpers.js";

describe("validation reasons (SPEC §5.2)", () => {
  it("flags low extraction confidence for review", () => {
    expect(confidenceReason("low")).toBeTruthy();
    expect(confidenceReason("high")).toBeNull();
  });

  it("flags a missing value for manual entry", () => {
    expect(missingValueReason(null)).toBeTruthy();
    expect(missingValueReason(4.2)).toBeNull();
  });

  it("flags indeterminate status for confirmation", () => {
    expect(indeterminateReason("indeterminate")).toBeTruthy();
    expect(indeterminateReason("in_range")).toBeNull();
  });

  it("flags an implausible value (misread decimal) only with a verified bounds table", () => {
    // 55 mmol/L potassium is wildly out of the plausible 1–10 band → safety event.
    expect(plausibilityReason("potassium", "mmol/L", 55, verifiedConfig())).toBeTruthy();
    expect(plausibilityReason("potassium", "mmol/L", 4.2, verifiedConfig())).toBeNull();
    // Without a verified table we can't claim implausibility.
    expect(plausibilityReason("potassium", "mmol/L", 55, EMPTY_CONFIG)).toBeNull();
  });

  it("flags a disagreement between the lab's printed flag and computed status", () => {
    expect(labFlagCrossCheckReason("H", "in_range")).toBeTruthy();
    expect(labFlagCrossCheckReason("L", "in_range")).toBeTruthy();
    expect(labFlagCrossCheckReason("H", "high")).toBeNull();
    expect(labFlagCrossCheckReason("H", "critical_high")).toBeNull();
    expect(labFlagCrossCheckReason(null, "in_range")).toBeNull();
  });
});
