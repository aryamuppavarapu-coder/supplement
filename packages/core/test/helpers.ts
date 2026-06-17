/**
 * Test-only fixtures. The numbers here are TEST DATA (sourceRef "TEST-FIXTURE"), not
 * shipped clinical facts — they exist purely to exercise the engine's logic. Production
 * clinical values come from clinician-reviewed /config files (SPEC §6, §12).
 */
import type { ExtractedMarker, SafetyConfig, UserProfile } from "../src/index.js";

export function verifiedConfig(overrides: Partial<SafetyConfig> = {}): SafetyConfig {
  const base: SafetyConfig = {
    criticalValues: {
      verified: true,
      entries: [
        {
          markerStd: "potassium",
          unitStd: "mmol/L",
          criticalLow: 2.5,
          criticalHigh: 6.0,
          sourceRef: "TEST-FIXTURE",
          reviewedBy: "test",
          reviewedAt: "2026-01-01",
        },
      ],
    },
    interactions: {
      verified: true,
      entries: [
        {
          nutrient: "vitamin_k",
          triggerType: "medication",
          triggerId: "anticoagulant",
          action: "suppress",
          note: "Vitamin K can interfere with anticoagulant medications.",
          sourceRef: "TEST-FIXTURE",
          reviewedBy: "test",
          reviewedAt: "2026-01-01",
        },
        {
          nutrient: "iron",
          triggerType: "condition",
          triggerId: "hemochromatosis",
          action: "suppress",
          note: "Iron supplements are contraindicated in iron-overload conditions.",
          sourceRef: "TEST-FIXTURE",
          reviewedBy: "test",
          reviewedAt: "2026-01-01",
        },
        {
          nutrient: "magnesium",
          triggerType: "condition",
          triggerId: "kidney_disease_advanced",
          action: "warn",
          note: "Discuss magnesium with advanced kidney disease.",
          sourceRef: "TEST-FIXTURE",
          reviewedBy: "test",
          reviewedAt: "2026-01-01",
        },
      ],
    },
    plausibility: {
      verified: true,
      entries: [
        {
          markerStd: "potassium",
          unitStd: "mmol/L",
          min: 1.0,
          max: 10.0,
          sourceRef: "TEST-FIXTURE",
          reviewedBy: "test",
          reviewedAt: "2026-01-01",
        },
      ],
    },
  };
  return { ...base, ...overrides };
}

export function profile(overrides: Partial<UserProfile> = {}): UserProfile {
  return {
    age: 40,
    sex: "female",
    pregnant: false,
    medications: [],
    conditions: [],
    disclosedMeds: true,
    disclosedConditions: true,
    ...overrides,
  };
}

export function marker(overrides: Partial<ExtractedMarker> = {}): ExtractedMarker {
  return {
    nameRaw: "Test Marker",
    value: 1,
    unitRaw: "mmol/L",
    refLow: 0,
    refHigh: 2,
    refText: null,
    labFlag: null,
    panel: null,
    confidence: "high",
    ...overrides,
  };
}
