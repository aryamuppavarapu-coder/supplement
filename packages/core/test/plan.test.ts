import { describe, expect, it } from "vitest";
import {
  allowedNutrients,
  buildSupplementGate,
  processReport,
  EMPTY_CONFIG,
} from "../src/index.js";
import { marker, profile, verifiedConfig } from "./helpers.js";

const lowVitaminD = marker({
  nameRaw: "Vitamin D, 25-Hydroxy",
  value: 18,
  unitRaw: "ng/mL",
  refLow: 30,
  refHigh: 100,
});
const lowFerritin = marker({
  nameRaw: "Ferritin",
  value: 8,
  unitRaw: "ng/mL",
  refLow: 30,
  refHigh: 400,
});
const highTrig = marker({
  nameRaw: "Triglycerides",
  value: 320,
  unitRaw: "mg/dL",
  refLow: 0,
  refHigh: 150,
});
const criticalPotassium = marker({
  nameRaw: "Potassium",
  value: 6.8,
  unitRaw: "mmol/L",
  refLow: 3.5,
  refHigh: 5.0,
});

describe("supplement gate (SPEC §2.3, §2.4, §3.1, §3.4)", () => {
  it("withholds the whole plan if meds/conditions are not disclosed", () => {
    const report = processReport({ markers: [lowVitaminD] }, verifiedConfig());
    const gate = buildSupplementGate(report, profile({ disclosedMeds: false }), verifiedConfig());
    expect(gate.enabled).toBe(false);
    expect(gate.withheldReason).toMatch(/medications and diagnosed conditions/i);
  });

  it("withholds the whole plan when the interaction table is unverified", () => {
    const report = processReport({ markers: [lowVitaminD] }, EMPTY_CONFIG);
    const gate = buildSupplementGate(report, profile(), EMPTY_CONFIG);
    expect(gate.enabled).toBe(false);
    expect(gate.withheldReason).toMatch(/certified/i);
  });

  it("suggests (allow) vitamin D for a low vitamin D marker", () => {
    const report = processReport({ markers: [lowVitaminD] }, verifiedConfig());
    const gate = buildSupplementGate(report, profile(), verifiedConfig());
    expect(gate.enabled).toBe(true);
    const vd = gate.candidates.find((c) => c.nutrient === "vitamin_d");
    expect(vd?.decision).toBe("allow");
  });

  it("suggests omega-3 for high triglycerides", () => {
    const report = processReport({ markers: [highTrig] }, verifiedConfig());
    const gate = buildSupplementGate(report, profile(), verifiedConfig());
    expect(gate.candidates.find((c) => c.nutrient === "omega_3")?.decision).toBe("allow");
  });

  it("suppresses iron for low ferritin when the user has hemochromatosis (§2.4)", () => {
    const report = processReport({ markers: [lowFerritin] }, verifiedConfig());
    const gate = buildSupplementGate(
      report,
      profile({ conditions: ["hemochromatosis"] }),
      verifiedConfig(),
    );
    const iron = gate.candidates.find((c) => c.nutrient === "iron");
    expect(iron?.decision).toBe("suppress");
    expect(allowedNutrients(gate).find((c) => c.nutrient === "iron")).toBeUndefined();
  });

  it("suppresses suggestions for a critical marker pathway (§2.3)", () => {
    const report = processReport({ markers: [criticalPotassium] }, verifiedConfig());
    expect(report.hasCritical).toBe(true);
    const gate = buildSupplementGate(report, profile(), verifiedConfig());
    // potassium has no deficiency hint, but if a hinted marker were critical it must suppress.
    // Verify the rule directly with a critical vitamin D scenario:
    const critVitD = processReport(
      {
        markers: [
          marker({
            nameRaw: "Vitamin D, 25-Hydroxy",
            value: 18,
            unitRaw: "ng/mL",
            refLow: 30,
            refHigh: 100,
          }),
        ],
      },
      verifiedConfig({
        criticalValues: {
          verified: true,
          entries: [
            {
              markerStd: "vitamin_d_25oh",
              unitStd: "ng/mL",
              criticalLow: 20,
              criticalHigh: null,
              sourceRef: "TEST-FIXTURE",
              reviewedBy: "test",
              reviewedAt: "2026-01-01",
            },
          ],
        },
      }),
    );
    const critGate = buildSupplementGate(
      critVitD,
      profile(),
      verifiedConfig({
        criticalValues: {
          verified: true,
          entries: [
            {
              markerStd: "vitamin_d_25oh",
              unitStd: "ng/mL",
              criticalLow: 20,
              criticalHigh: null,
              sourceRef: "TEST-FIXTURE",
              reviewedBy: "test",
              reviewedAt: "2026-01-01",
            },
          ],
        },
      }),
    );
    expect(critVitD.hasCritical).toBe(true);
    expect(critGate.candidates.find((c) => c.nutrient === "vitamin_d")?.decision).toBe("suppress");
    // and the gate result for the unrelated critical potassium report is still enabled
    expect(gate.enabled).toBe(true);
  });
});
