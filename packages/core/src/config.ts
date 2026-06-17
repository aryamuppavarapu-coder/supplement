/**
 * Default safety configuration.
 *
 * ⚠️ Ships EMPTY and UNVERIFIED. Per SPEC §0/§6/§12 we never invent clinical values.
 * Production loads clinician-reviewed tables from /config/*.json (see functions) and
 * passes them in. Until a table is `verified`, the engine fails safe:
 *   - supplement suggestions are withheld (SPEC §2.4),
 *   - critical-value escalation is treated as "not certified" and does not fire on
 *     placeholder numbers (SPEC §2.3 / §11 "behind a flag").
 *
 * Unit tests construct their own verified tables to exercise the logic — they never
 * depend on real clinical data living in this file.
 */
import type { SafetyConfig, SafetyTable } from "./types.js";

export const EMPTY_CONFIG: SafetyConfig = {
  criticalValues: { verified: false, entries: [] },
  interactions: { verified: false, entries: [] },
  plausibility: { verified: false, entries: [] },
};

export function isVerified<T>(table: SafetyTable<T>): boolean {
  return table.verified === true;
}

/**
 * Validate that a config object claiming to be verified actually carries provenance on
 * every entry (reviewedBy + reviewedAt). Returns the list of problems; an empty array
 * means the table is internally consistent. Functions should refuse to mark a table
 * `verified: true` in production if this returns anything.
 */
export function auditProvenance(config: SafetyConfig): string[] {
  const problems: string[] = [];
  const check = (name: string, table: SafetyTable<{ reviewedBy: string | null; reviewedAt: string | null; sourceRef?: string }>) => {
    if (!table.verified) return;
    table.entries.forEach((e, i) => {
      if (!e.reviewedBy) problems.push(`${name}[${i}]: verified table but reviewedBy is missing`);
      if (!e.reviewedAt) problems.push(`${name}[${i}]: verified table but reviewedAt is missing`);
    });
  };
  check("criticalValues", config.criticalValues);
  check("interactions", config.interactions);
  check("plausibility", config.plausibility);
  return problems;
}
