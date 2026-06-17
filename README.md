# Supplement

A native iOS app where people upload their own lab/blood-test results and get a **plain-language, wellness-framed** breakdown: what each marker means, what's outside the reference range printed on *their* report, and food-first guidance with quality-vetted supplements as a secondary option. Tracks markers over time. A separate, clinician-in-the-loop clinical tier (Tier 2) is built but stays disabled until medical/legal/regulatory prerequisites exist.

> **Supplement gives educational information, not medical advice or diagnosis. Always consult a licensed healthcare provider.** This is the product's core promise and is enforced in code, not just copy — see `CLAUDE.md` and `SPEC.md` §2.

`SPEC.md` is the authoritative product + technical spec. This README is the practical "how do I build/run it" guide.

---

## Why the build is split (Windows + no Mac)

This repo was scaffolded on Windows. **Xcode is macOS-only**, so the iOS app is compiled, signed, and shipped on **Codemagic** cloud macOS runners (`codemagic.yaml` at the repo root) — no Mac hardware required on your end. Everything else (the deterministic safety engine and the Firebase Cloud Functions) is plain TypeScript and runs/tests directly on Windows.

| Part | Language | Runs on Windows? | How it ships |
|------|----------|------------------|--------------|
| `packages/core` | TypeScript | ✅ build + unit tests | bundled into `functions` |
| `functions` | TypeScript (Node 20) | ✅ build + emulator | `firebase deploy` |
| `clinician-console` | TypeScript (web) | ✅ | static/Cloud Run (Phase 2) |
| `ios` | Swift / SwiftUI | ❌ (write only) | Codemagic → TestFlight |

---

## Quick start (Windows-friendly)

Prereqs: **Node ≥ 20**, npm. (For deploy: a Firebase project + the Firebase CLI; an Anthropic API key; for iOS: a Codemagic account + Apple Developer Program membership.)

```bash
# from repo root
npm install

# the safety-critical core — builds and unit-tests on Windows
npm run test:core

# the Cloud Functions
npm run build:functions
```

### Run the backend locally (optional)

```bash
cd functions
cp .env.example .env          # put your ANTHROPIC_API_KEY here for local testing only
npm run build
npm run serve                 # Firebase emulators (Functions/Firestore/Storage)
```

### Build the iOS app (cloud, no Mac)

1. Push this repo to GitHub/GitLab/Bitbucket.
2. Create a Codemagic app pointed at the repo; it reads `codemagic.yaml` from the repo root.
3. Add your Apple Developer credentials (App Store Connect API key) in Codemagic.
4. Trigger a build → it runs `xcodegen generate`, builds, signs, and uploads to TestFlight.

There is no iOS Simulator on Windows; you run the app on your iPhone via TestFlight.

---

## What still needs a *human* before launch (do not skip)

The spec marks these **⚠️ VERIFY**. The code ships with clearly-labeled placeholders and **fails safe** (e.g., supplement suggestions are withheld) until they're confirmed:

- [ ] **Critical-value table** (`config/critical-values.json`, SPEC §6.1) — populate from a clinician-reviewed source. *Do not fill from memory or model output.*
- [ ] **Interaction table** (`config/interactions.json`, SPEC §6.2) — confirmed by a clinician or pharmacist.
- [ ] **Plausibility bounds** (`config/plausibility.json`) — sanity bounds that catch a misread decimal (a safety event); clinician-reviewed.
- [ ] **Wellness-tier framing** (SPEC §2.1) — reviewed by a regulatory attorney.
- [ ] **Privacy** (SPEC §9) — FTC Health Breach Notification Rule + state laws (e.g., WA My Health My Data); export/delete (DSAR) working.
- [ ] **Affiliate/dispensary terms** (SPEC §10.2) — confirmed and disclosed in-app.
- [ ] **API keys absent from the app bundle** (SPEC §7.7) — the app only calls your Cloud Functions.

**Tier 2 (clinical)** additionally requires everything in SPEC §14 (medical director + clinician network, CPOM structure, multi-state licensing, malpractice/product insurance, a live HIPAA program with BAAs, an FDA determination). It is a separate, well-resourced build, not a feature toggle, and stays disabled until then.

---

## Architecture (SPEC §8)

```
[iOS] --upload--> [Cloud Storage] --(trigger)--> [Fn: extract] --doc/image--> [Claude: record_lab_results]
                                                       |  <-- structured JSON --
                                                       v
                              [Validation + Flagging engine]  (deterministic, packages/core)
                                                       |
                              [Critical check] --critical?--> pin urgent banner, suppress pathway
                                                       |
[iOS] <--confirm values--------------------------------+
                                                       v
                              [Interaction screen] (meds/conditions) -> gate suggestions
                                                       v
                              [Fn: explain — Tier 1] --structured data+profile--> [Claude: explanations]
                                                       v
[iOS] <--- Tier-1 dashboard + gated supplement plan + trends ---
```

The LLM **transcribes and explains**; it never decides high/low and never sees a path around the critical/interaction gates. That logic lives in `packages/core` and is unit-tested.

## Repo layout

See `CLAUDE.md`. Start in `packages/core` (the safety engine), then `functions`, then `ios`.
