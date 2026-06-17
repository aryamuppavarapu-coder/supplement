import { describe, expect, it } from "vitest";
import { screenInteraction, EMPTY_CONFIG } from "../src/index.js";
import { profile, verifiedConfig } from "./helpers.js";

describe("interaction screening (SPEC §2.4, §6.2)", () => {
  it("FAILS SAFE: suppresses every suggestion when the table is unverified", () => {
    const d = screenInteraction("vitamin_d", profile(), EMPTY_CONFIG);
    expect(d.action).toBe("suppress");
    expect(d.configVerified).toBe(false);
  });

  it("suppresses vitamin K for someone on an anticoagulant", () => {
    const d = screenInteraction(
      "vitamin_k",
      profile({ medications: ["anticoagulant"] }),
      verifiedConfig(),
    );
    expect(d.action).toBe("suppress");
    expect(d.notes.length).toBeGreaterThan(0);
    expect(d.matchedTriggers).toContainEqual({ triggerType: "medication", triggerId: "anticoagulant" });
  });

  it("suppresses iron for someone with hemochromatosis", () => {
    const d = screenInteraction(
      "iron",
      profile({ conditions: ["hemochromatosis"] }),
      verifiedConfig(),
    );
    expect(d.action).toBe("suppress");
  });

  it("warns (not suppresses) magnesium with advanced kidney disease", () => {
    const d = screenInteraction(
      "magnesium",
      profile({ conditions: ["kidney_disease_advanced"] }),
      verifiedConfig(),
    );
    expect(d.action).toBe("warn");
  });

  it("allows a nutrient with no matching trigger", () => {
    const d = screenInteraction("vitamin_d", profile(), verifiedConfig());
    expect(d.action).toBe("allow");
    expect(d.matchedTriggers).toHaveLength(0);
  });
});
