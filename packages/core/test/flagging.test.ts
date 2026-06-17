import { describe, expect, it } from "vitest";
import { computeBaseStatus, flagMarker, EMPTY_CONFIG } from "../src/index.js";
import { verifiedConfig } from "./helpers.js";

describe("computeBaseStatus (SPEC §5.3)", () => {
  it("flags below the printed range as low", () => {
    expect(computeBaseStatus(3.0, 3.5, 5.0, null)).toBe("low");
  });
  it("flags above the printed range as high", () => {
    expect(computeBaseStatus(6.0, 3.5, 5.0, null)).toBe("high");
  });
  it("flags within the printed range as in_range", () => {
    expect(computeBaseStatus(4.0, 3.5, 5.0, null)).toBe("in_range");
  });
  it("treats boundary values as in range (inclusive)", () => {
    expect(computeBaseStatus(3.5, 3.5, 5.0, null)).toBe("in_range");
    expect(computeBaseStatus(5.0, 3.5, 5.0, null)).toBe("in_range");
  });
  it("handles a one-sided range (only upper bound)", () => {
    expect(computeBaseStatus(10, null, 5, null)).toBe("high");
    expect(computeBaseStatus(2, null, 5, null)).toBe("in_range");
  });
  it("returns qualitative for a non-numeric result with descriptive text", () => {
    expect(computeBaseStatus(null, null, null, "Negative")).toBe("qualitative");
  });
  it("returns indeterminate when there is no range to compare against", () => {
    expect(computeBaseStatus(4.0, null, null, null)).toBe("indeterminate");
  });
  it("returns indeterminate for a missing value with no text", () => {
    expect(computeBaseStatus(null, 3.5, 5.0, null)).toBe("indeterminate");
  });
});

describe("flagMarker critical escalation (SPEC §2.3, §6.1)", () => {
  const base = {
    nameStd: "potassium",
    unitStd: "mmol/L",
    refLow: 3.5,
    refHigh: 5.0,
    refText: null,
  };

  it("escalates below criticalLow to critical_low when config is verified", () => {
    const r = flagMarker({ ...base, value: 2.0 }, verifiedConfig());
    expect(r.computedStatus).toBe("critical_low");
    expect(r.criticalConfigVerified).toBe(true);
  });

  it("escalates above criticalHigh to critical_high when config is verified", () => {
    const r = flagMarker({ ...base, value: 6.5 }, verifiedConfig());
    expect(r.computedStatus).toBe("critical_high");
  });

  it("does NOT escalate when value is between critical bounds (stays high/low/in_range)", () => {
    expect(flagMarker({ ...base, value: 5.5 }, verifiedConfig()).computedStatus).toBe("high");
    expect(flagMarker({ ...base, value: 4.0 }, verifiedConfig()).computedStatus).toBe("in_range");
  });

  it("does NOT fire criticals on placeholder data when config is unverified (§11 'behind a flag')", () => {
    const r = flagMarker({ ...base, value: 2.0 }, EMPTY_CONFIG);
    expect(r.computedStatus).toBe("low"); // base status only
    expect(r.criticalConfigVerified).toBe(false);
  });

  it("does not escalate when the unit does not match the critical table entry", () => {
    const r = flagMarker({ ...base, unitStd: "mg/dL", value: 2.0 }, verifiedConfig());
    expect(r.computedStatus).toBe("low");
  });

  it("does not escalate an unstandardized marker", () => {
    const r = flagMarker({ ...base, nameStd: null, value: 2.0 }, verifiedConfig());
    expect(r.computedStatus).toBe("low");
  });

  it("never escalates a non-finite value to a false critical", () => {
    expect(flagMarker({ ...base, value: Infinity }, verifiedConfig()).computedStatus).toBe("indeterminate");
    expect(flagMarker({ ...base, value: -Infinity }, verifiedConfig()).computedStatus).toBe("indeterminate");
    expect(flagMarker({ ...base, value: NaN }, verifiedConfig()).computedStatus).toBe("indeterminate");
  });
});
