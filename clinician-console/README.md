# Clinician console (Tier 2 — Phase 2)

Web app for the licensed-clinician review + sign-off workflow (SPEC §3.8, §7.4, §14). Vite + React + TypeScript on the same Firebase backend.

> ⛔ **Disabled by default.** The backend callables it depends on (`listClinicalReviews`, `signOffClinicalReview`) are hard-gated by `CLINICAL_TIER_ENABLED` and a `clinician` custom claim. Do not enable until every SPEC §14 prerequisite exists (medical director, CPOM structure, multi-state licensing, malpractice/product insurance, a live HIPAA program with BAAs, and an FDA determination).

## The guarantee it enforces (SPEC §2.7)

The patient only ever sees **clinician-authored** content. The AI output is a DRAFT for decision support; releasing requires a clinician to edit it and click **Approve & release**, which is the only path that sets a report to `clinical_released`. Every action is appended to the review's `auditTrail`.

## Run locally

```bash
cp .env.example .env.local   # fill in your Firebase web config
npm install
npm run dev                  # http://localhost:5173
```

Sign in with a Firebase account that has a `clinician: true` custom claim (set via the Admin SDK / a setup function). Without the claim, the console refuses access and the callables reject the request.

## Production notes

- Host behind your org's SSO/access controls; enable audit logging (SPEC §14).
- `clinicalReviews` contains PHI — HIPAA scope. Only HIPAA-eligible services + signed BAAs.
