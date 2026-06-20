# Supplement — Claude Code working instructions

**`SPEC.md` in this repo root is the authoritative product + technical spec. Follow it.**

## Hard, non-negotiable constraints (SPEC §2 — Guardrails)

These are baked into AI system prompts, UI copy, and pipeline logic. **Do not weaken them to satisfy a feature request.**

- **§2.1 Tier 1 is wellness, not clinical.** Never "you have [disease]." Say "above/below the typical reference range." Supplements are "general wellness support to discuss with your doctor," never a prescription, never a directive dose.
- **§2.2 The LLM never decides high/low.** Flagging is deterministic code (`/packages/core`) comparing the value to the report's printed reference range. The model only transcribes values and explains an already-computed result.
- **§2.3 Critical values short-circuit everything.** A critical/panic value pins an urgent-care banner and suppresses all supplement suggestions for that pathway. No model discretion.
- **§2.4 Interaction screening gates every suggestion.** Every supplement passes the nutrient–drug / nutrient–condition check against the user's profile before it can be shown.
- **§2.5 Persistent disclaimer + consent.** "Educational information, not medical advice or diagnosis. Always consult a licensed healthcare provider." Explicit opt-in at onboarding.
- **§2.6 No data training / no selling.** Health data is never sold, never used to train models. All AI calls are server-side only.
- **§2.7 Tier 2 clinical sign-off.** No AI-generated diagnosis, treatment, or dosing reaches a patient without a licensed clinician's review and explicit sign-off. Until clinician-approved, the patient sees only Tier-1 wellness framing. There is no autonomous patient-facing diagnosis or prescription. Ever.

## ⚠️ VERIFY rule

Anything marked **⚠️ VERIFY** in the spec (clinical tables in `/config`, regulatory/legal framing, affiliate terms) must be populated/confirmed by a qualified human (clinician, pharmacist, attorney) before that code path ships. **Use clearly-labeled placeholders until then; never invent the values.** The safety engine treats unverified config as fail-safe: supplement suggestions are withheld when the interaction/critical tables are not verified.

### 🚫 LAUNCH BLOCKER — `ALLOW_UNPROVENANCED_CONFIG`

`functions/.env` currently sets `ALLOW_UNPROVENANCED_CONFIG=true`. This is a **dev/demo-only** flag that lets the engine honor the ILLUSTRATIVE `defaultSafetyConfig.ts` (which ships `verified: true` with `reviewedBy/reviewedAt: null`) so the supplement feature is functional before real tables exist. **It bypasses the §6/§12 fail-safe.** Before ANY real-patient launch you MUST:
1. Replace `/config/*.json` (or the embedded default) with clinician-reviewed tables that have populated `reviewedBy`/`reviewedAt`.
2. Remove `ALLOW_UNPROVENANCED_CONFIG` from the deployed functions environment.
3. Set `APP_ENV=production` — `safetyConfig.ts` now hard-throws if the bypass flag is ever combined with `APP_ENV=production` (defense-in-depth), so a production deploy cannot silently ship illustrative tables.

Until then this flag must never be set with `APP_ENV=production`, and the app is **not** cleared for real users.

## Build order (SPEC §11)

Build Tier 1 (Milestones 1→2→3) fully before the Tier 2 clinical layer. Do not enable any patient-facing clinical output until every §14 prerequisite exists. Tier 2 plumbing may be written in parallel but stays disabled.

## Repo layout

```
/ios                # native iOS app (Swift/SwiftUI), built via XcodeGen + Codemagic cloud CI
/functions          # Firebase Cloud Functions (2nd gen), TypeScript — ALL AI calls live here
/clinician-console  # Tier 2 web app for clinician review + sign-off (Phase 2, disabled by default)
/packages/core      # shared deterministic safety engine + config tables (TS)
/config             # critical-value + interaction tables (⚠️ VERIFY before prod)
CLAUDE.md           # this file
SPEC.md             # authoritative spec
```

## Environment notes (important)

- This repo was scaffolded on **Windows**. Xcode cannot run on Windows; the iOS app is built in the cloud via **Codemagic** (`codemagic.yaml` at the repo root) on macOS runners. Apple Developer Program membership is required to sign/distribute.
- `/packages/core` and `/functions` are plain TypeScript and run/test on Windows with Node.
- **Secrets:** the Anthropic API key and any partner keys live only in Cloud Functions secrets (SPEC §7.7). Never put them in the iOS bundle or commit them.
