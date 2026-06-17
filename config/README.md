# `/config` — clinician-reviewed safety tables (⚠️ VERIFY)

These JSON files are the **authoritative safety data** for the deterministic engine in `packages/core`. They ship **empty and `verified: false`**, and the engine **fails safe** until a qualified human fills them in and flips the flag (SPEC §0, §6, §11, §12).

| File | Spec | Drives | Reviewer |
|------|------|--------|----------|
| `critical-values.json` | §6.1 | Urgent-care banner + pathway suppression (§2.3) | Clinician |
| `interactions.json` | §6.2 | Gating of every supplement suggestion (§2.4) | Clinician / pharmacist |
| `plausibility.json` | §5.2 | Misread-decimal / typo detection | Clinician |

## The rule (do not break it)

- **Never invent these values** — not from memory, not from a model. Populate only from an authoritative, clinician-reviewed source, and cite it in `sourceRef`.
- Each entry must carry `reviewedBy` (name + credential) and `reviewedAt` (ISO date).
- Set the table's `verified: true` **only after** a named reviewer signs off. `functions/src/safetyConfig.ts` runs a provenance audit (via `auditProvenance` in `packages/core/src/config.ts`) and, by default in every environment, refuses to treat a table as verified if any entry lacks provenance.

## Fail-safe behavior while `verified: false`

- **Critical escalation does not fire** — the app shows base low/in-range/high only, and surfaces that critical screening is not yet certified. No urgent alarms are raised from placeholder numbers.
- **All supplement suggestions are withheld** — the plan is disabled with a user-facing explanation.

This is intentional: shipping Milestone 1 (accurate, safe display) does **not** require these tables, but turning on supplement guidance (Milestone 2) does. See `SPEC.md` §11–§12.
