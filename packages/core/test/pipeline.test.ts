import { describe, expect, it } from "vitest";
import { processReport, standardizeMarkerName, normalizeUnit, EMPTY_CONFIG } from "../src/index.js";
import { marker, verifiedConfig } from "./helpers.js";

describe("standardization", () => {
  it("standardizes common marker aliases", () => {
    expect(standardizeMarkerName("Vitamin D, 25-Hydroxy")).toBe("vitamin_d_25oh");
    expect(standardizeMarkerName("HbA1c")).toBe("hba1c");
    expect(standardizeMarkerName("Hgb")).toBe("hemoglobin");
    expect(standardizeMarkerName("totally unknown marker")).toBeNull();
  });
  it("canonicalizes unit strings", () => {
    expect(normalizeUnit("mmol/l")).toBe("mmol/L");
    expect(normalizeUnit("MG/DL")).toBe("mg/dL");
    expect(normalizeUnit("  ng/ml ")).toBe("ng/mL");
    expect(normalizeUnit(null)).toBeNull();
  });
});

describe("processReport (SPEC §8 orchestration)", () => {
  it("computes per-marker status and report-level flags", () => {
    const report = processReport(
      {
        markers: [
          marker({ nameRaw: "Potassium", value: 6.8, unitRaw: "mmol/L", refLow: 3.5, refHigh: 5.0 }),
          marker({ nameRaw: "Vitamin D, 25-Hydroxy", value: 45, unitRaw: "ng/mL", refLow: 30, refHigh: 100 }),
        ],
      },
      verifiedConfig(),
    );
    expect(report.hasCritical).toBe(true);
    expect(report.criticalMarkers).toContain("potassium");
    const vd = report.markers.find((m) => m.nameStd === "vitamin_d_25oh");
    expect(vd?.computedStatus).toBe("in_range");
  });

  it("marks low-confidence and unreadable values as needing human review (SPEC §3.2)", () => {
    const report = processReport(
      {
        markers: [
          marker({ nameRaw: "Glucose", value: null, unitRaw: "mg/dL", confidence: "low" }),
        ],
      },
      EMPTY_CONFIG,
    );
    expect(report.needsHumanReview).toBe(true);
    expect(report.markers[0]!.needsReview).toBe(true);
    expect(report.markers[0]!.reviewReasons.length).toBeGreaterThan(0);
  });

  it("never produces a critical when the critical config is unverified", () => {
    const report = processReport(
      {
        markers: [
          marker({ nameRaw: "Potassium", value: 6.8, unitRaw: "mmol/L", refLow: 3.5, refHigh: 5.0 }),
        ],
      },
      EMPTY_CONFIG,
    );
    expect(report.hasCritical).toBe(false);
    expect(report.markers[0]!.computedStatus).toBe("high"); // base status only
  });
});
