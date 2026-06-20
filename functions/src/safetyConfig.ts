/**
 * Loads the clinician-reviewed safety tables (SPEC §6) and hands them to the engine.
 *
 * Source of truth is /config/*.json at the repo root (clinician-edited). We load them
 * with createRequire so this compiles cleanly under NodeNext without JSON import
 * attribute churn. Locally (emulator, repo checkout) the relative path resolves.
 *
 * PRODUCTION NOTE: a deployed function only ships its own directory, so for production
 * you should either (a) add a predeploy step that copies /config into functions, or
 * (b) store these tables in a Firestore `config` collection edited via the clinician
 * console and load them here instead. Either way, the provenance audit below still runs.
 *
 * Fail-safe: by DEFAULT in every environment, a table claiming verified=true but missing
 * per-entry provenance is forced back to verified=false (SPEC §0, §12). Only an explicit
 * APP_ENV=test or ALLOW_UNPROVENANCED_CONFIG=true bypass (for emulator fixtures) may honor it.
 */
import { createRequire } from "node:module";
import { auditProvenance, type SafetyConfig } from "@supplement/core";
import { logger } from "firebase-functions";
import { DEFAULT_SAFETY_CONFIG } from "./defaultSafetyConfig.js";

const require = createRequire(import.meta.url);

function tryLoad<T>(relPath: string, fallback: T): T {
  try {
    return require(relPath) as T;
  } catch (err) {
    logger.warn(`safetyConfig: could not load ${relPath}; using fail-safe default`, err);
    return fallback;
  }
}

let cached: SafetyConfig | null = null;

export function loadSafetyConfig(): SafetyConfig {
  if (cached) return cached;

  // Deployed functions don't ship the repo's /config, so the fallback is the embedded
  // ILLUSTRATIVE config (DEFAULT_SAFETY_CONFIG). A clinician-reviewed /config or a Firestore
  // source overrides it later (and then ALLOW_UNPROVENANCED_CONFIG should be removed).
  const raw: SafetyConfig = {
    criticalValues: tryLoad("../../config/critical-values.json", DEFAULT_SAFETY_CONFIG.criticalValues),
    interactions: tryLoad("../../config/interactions.json", DEFAULT_SAFETY_CONFIG.interactions),
    plausibility: tryLoad("../../config/plausibility.json", DEFAULT_SAFETY_CONFIG.plausibility),
  };

  // Defense-in-depth: the illustrative-config bypass must NEVER run in a declared production
  // environment, even if the flag leaks into prod secrets (SPEC §6/§12). A real launch must
  // ship clinician-reviewed tables (populated reviewedBy/reviewedAt) instead of relying on this.
  if (process.env.APP_ENV === "production" && process.env.ALLOW_UNPROVENANCED_CONFIG === "true") {
    throw new Error(
      "ALLOW_UNPROVENANCED_CONFIG must never be set when APP_ENV=production (SPEC §6/§12). " +
        "Remove the flag and provide clinician-reviewed /config tables before launch.",
    );
  }

  // Enforce by default everywhere; only an explicit dev/test bypass may skip it.
  const allowUnprovenanced =
    process.env.APP_ENV === "test" || process.env.ALLOW_UNPROVENANCED_CONFIG === "true";
  const problems = auditProvenance(raw);
  if (problems.length > 0) {
    logger.error("safetyConfig: provenance audit failed", { problems });
    if (!allowUnprovenanced) {
      // Fail safe: refuse to honor a "verified" claim that lacks provenance.
      raw.criticalValues = { ...raw.criticalValues, verified: false };
      raw.interactions = { ...raw.interactions, verified: false };
      raw.plausibility = { ...raw.plausibility, verified: false };
    }
  }

  cached = raw;
  return raw;
}

/** For tests / hot-reload. */
export function _resetSafetyConfigCache(): void {
  cached = null;
}
