/**
 * @supplement/core — the deterministic safety engine.
 *
 * The LLM never decides high/low (SPEC §2.2). Everything that gates patient-facing
 * output — flagging, critical escalation, interaction screening, plan gating — lives
 * here and is unit-tested.
 */
export * from "./types.js";
export * from "./taxonomy.js";
export * from "./units.js";
export * from "./markers.js";
export * from "./config.js";
export * from "./flagging.js";
export * from "./validation.js";
export * from "./interactions.js";
export * from "./plan.js";
export * from "./pipeline.js";
