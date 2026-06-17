# [App Name] — Build Specification

**Product:** Standalone native iOS app. Users upload lab/blood-test results from their own provider; the app extracts the values, explains them in plain language, flags what's low/high, and offers guidance with quality-vetted supplement brands. Includes a sponsored doctor directory.

**Two tiers:**
- **Tier 1 — Wellness / informational** (default, every user, shippable solo now). Educates and contextualizes; food-first plus wellness-framed supplement guidance. Does **not** diagnose disease or prescribe treatment.
- **Tier 2 — AI-assisted clinical** (Phase 2, clinician-reviewed). The AI *drafts* an assessment and treatment options; a **licensed clinician reviews, edits, and signs off** before anything reaches the patient as clinical guidance. The clinician is the decision-maker and is legally responsible. Requires the prerequisites in **§14** before it touches real patients.

**Client:** native iOS, built in **Xcode** (Swift / SwiftUI). Clinician review console (Tier 2): separate web app.

**Differentiator:** closes the loop with food, not just pills — deficiencies are explained against dietary context and addressed with food first, supplements second.

---

## 0. How to use this document with Claude Code

- Drop this file in the repo root and reference it from `CLAUDE.md`: *"This is the authoritative product + technical spec. Follow §2 (Guardrails) as hard, non-negotiable constraints. Tier 2 (clinical) code must never release AI output to a patient without clinician sign-off (§2.7). Do not relax safety rules to satisfy a feature request."*
- Build in the order of §11. Ship the Tier 1 wellness app fully before building the Tier 2 clinical layer, and do not launch Tier 2 to patients until §14's prerequisites exist.
- Anything marked **⚠️ VERIFY** must be populated/confirmed by a human (clinician, attorney, or regulatory consultant) before that code path ships. Use clearly-labeled placeholders until then; do not invent the values.
- Suggested repo layout:

```
/ios                # native iOS app (Swift/SwiftUI), built in Xcode, Firebase via SPM
/functions          # Firebase Cloud Functions (2nd gen), TypeScript — all AI calls live here
/clinician-console  # Tier 2 web app for clinician review + sign-off (Phase 2)
/packages/core      # shared deterministic safety engine + config tables (TS, runs in functions)
/config             # critical-value + interaction tables (⚠️ VERIFY before prod)
CLAUDE.md
SPEC.md             # this file
```

---

## 1. Product overview

A user signs up, completes a short health-profile intake (age, sex, medications, conditions, goals), and uploads a lab report (PDF or photo). The app:

1. Extracts every marker into structured data.
2. Validates the extraction (units, decimals, plausibility).
3. Flags each marker low / in-range / high against **the reference range printed on their report**, and escalates any **critical** value.
4. Screens any potential supplement suggestion against the user's meds/conditions.
5. Generates a plain-language **wellness-tier** breakdown and guidance (Tier 1 — everyone).
6. (Tier 2, optional) Lets the user request a clinical review: the AI drafts an assessment, a licensed clinician signs off, and the patient receives clinician-authored guidance.
7. Tracks markers over time as the user re-uploads.

Monetization: freemium subscription (RevenueCat/StoreKit), supplement affiliate/dispensary, disclosed sponsored doctor directory, and (Tier 2) clinical consults.

---

## 2. ⛔ NON-NEGOTIABLE GUARDRAILS (read first)

Baked into the AI system prompts, UI copy, and pipeline logic. Claude Code must not weaken them.

**2.1 Tier 1 language — wellness, not clinical.** Every Tier-1 explanation and UI string:
- Describes a value as "above/below the typical reference range," never "you have [disease]."
- Explains what a marker *does* and what out-of-range values are *commonly associated with* — as education.
- Always routes the user to a licensed provider for decisions.
- Frames supplements as "general wellness support that many people consider — discuss with your doctor or pharmacist," never as a prescription. Never states a dose as a directive.

**2.2 The LLM never decides high/low.** Flagging is deterministic code comparing the value to the report's reference range (§5.3). The model only *transcribes* values and *explains* the already-computed result.

**2.3 Critical values short-circuit everything.** A critical/panic value (§6.1) pins an urgent-care banner and **suppresses all supplement suggestions** for that pathway. No model discretion.

**2.4 Interaction screening gates every suggestion.** Before any supplement is shown it passes the nutrient–drug / nutrient–condition check (§6.2) against the user's profile. A hit suppresses or downgrades the suggestion.

**2.5 Persistent medical disclaimer + consent.** "Educational information, not medical advice or diagnosis. Always consult a licensed healthcare provider." Visible on results and the supplement plan; explicit opt-in at onboarding.

**2.6 No data training / no selling.** Health data is never sold and never used to train models. Calls are server-side only (§7.6).

**2.7 Tier 2 clinical sign-off (the rule that makes clinical lawful).** No AI-generated diagnosis, treatment, or dosing reaches a patient without a **licensed clinician's review and explicit sign-off**. The AI is decision *support*; the clinician is the decision *maker*. Until a value is clinician-approved, the patient sees only the Tier-1 wellness framing. There is no autonomous, patient-facing diagnosis or prescription. Ever.

---

## 3. User flows & screens

**3.1 Onboarding + consent** — Firebase Auth (email + Sign in with Apple + Google). Consent screen (data use, "educational not medical," explicit opt-in). Health-profile intake: age, biological sex, pregnancy status, height/weight (optional), **current medications**, **diagnosed conditions** (e.g., CKD, thyroid disorder, hemochromatosis), goals. Meds + conditions feed the interaction engine; if skipped, supplement suggestions are withheld and the app says why.

**3.2 Upload** — PDF or photo(s), multi-page. Use VisionKit's document scanner for camera capture of paper printouts, PhotosUI/PHPicker for photos, and `.fileImporter`/UIDocumentPicker for PDFs. Show extraction progress; let the user confirm/correct extracted values before analysis.

**3.3 Results dashboard (Tier 1)** — per-marker rows grouped by panel; status chip (Low / In range / High / **Needs attention** / Qualitative); one-line meaning, tap for detail; critical banner pinned when present.

**3.4 Supplement plan (Tier 1, gated by §2.4)** — suggestions tied to out-of-range markers + dietary context; each item shows what it is, why it's relevant (wellness-framed), food sources first, then optional supplement with quality-cert badges (§10.2) and a "discuss with your provider" CTA.

**3.5 Trends** — re-upload over time; Swift Charts line graphs per marker with reference-range bands. Retention driver.

**3.6 Doctor directory** — browse/match practitioners; sponsored listings labeled "Sponsored" (legal model in §10.3).

**3.7 Paywall** — free: first report analysis + basic breakdown; paid: ongoing analyses, trends, full plans.

**3.8 Request clinical review (Tier 2, Phase 2)** — user escalates a report for clinical review. Backend generates an AI **draft** (§5.5); a licensed clinician reviews/edits/signs in the console (§14); the patient then receives the **clinician-authored** assessment and (optionally) an async or live telehealth consult. Nothing AI-generated is shown as clinical guidance pre-sign-off.

---

## 4. Data model (Firestore + Storage)

```
users/{uid}
  profile, medications[], conditions[], consent, subscription   // subscription mirrored from RevenueCat

users/{uid}/reports/{reportId}
  source { storagePath, fileType, pageCount, uploadedAt }
  lab { labName?, reportDate?, collectionDate? }
  extraction { model, completedAt, needsHumanReview, confidenceOverall }
  status: uploaded | extracted | confirmed | analyzed | clinical_pending | clinical_released | error

users/{uid}/reports/{reportId}/markers/{markerId}
  nameRaw, nameStd, value, unitRaw, unitStd
  refLow?, refHigh?, refText?          // from the report (source of truth)
  labFlag?, computedStatus             // computedStatus set by deterministic engine, NOT the LLM
  confidence, needsReview, explanation?

users/{uid}/plans/{planId}
  reportId, generatedAt, items[ { nutrient, rationaleText, foodSources[],
    supplement?{ form, certifications[], brandLinks[] }, suppressedByInteraction?, interactionNote? } ]

clinicalReviews/{reviewId}            // Tier 2 (PHI — HIPAA scope, see §14)
  uid, reportId, draftedByModel, draftCreatedAt
  clinicianId, status: pending | edited | approved | declined
  clinicianNotes, signedOffAt, releasedToPatientAt, auditTrail[]

doctors/{doctorId}                    // directory; see §10.3
  name, specialty, location, bio, sponsored, sponsorTierExpiresAt?
```

**Storage:** files at `users/{uid}/reports/{reportId}/<file>`; encrypted at rest; access via signed URLs from Cloud Functions only; retention/auto-delete policy; honor user deletion (§9).

---

## 5. AI pipeline — extraction & analysis

All AI calls run **server-side in Cloud Functions**. The API key is never in the client (§7.6).

### 5.1 Extraction (Claude API, vision/PDF → structured JSON)
- **Model:** `claude-sonnet-4-6` (multimodal, cost-effective, tool use). Escalate to `claude-opus-4-8` for low-quality scans (higher-resolution vision). `claude-haiku-4-5-20251001` for the cheap "is this a lab report?" classifier.
- **Input:** PDF via a `document` block (base64 or Files API); photos via `image` blocks (`image/jpeg`/`image/png`). Native PDF/vision means no separate OCR step required.
- **Reliability:** force structured output via **tool use** (`tool_choice` pinned to the extraction tool) or Structured Outputs; Files API for files >20MB or reused (base64 inflates ~33%; 32MB / 100-page request limits — split larger docs at section boundaries); prompt caching for re-queries; on poor text-layer (`pdftotext -layout` check) or low confidence, escalate model and/or set `needsHumanReview` for manual confirmation.

**Extraction tool schema (record_lab_results):**
```json
{
  "name": "record_lab_results",
  "description": "Transcribe lab values exactly as printed. Do not infer, normalize, or judge whether a value is high or low. If a value is illegible, set value to null and confidence to low.",
  "input_schema": {
    "type": "object",
    "properties": {
      "labName": { "type": ["string","null"] },
      "reportDate": { "type": ["string","null"] },
      "collectionDate": { "type": ["string","null"] },
      "patientAge": { "type": ["number","null"] },
      "patientSex": { "type": ["string","null"] },
      "markers": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "nameRaw": { "type": "string" },
            "value": { "type": ["number","null"] },
            "unitRaw": { "type": ["string","null"] },
            "refLow": { "type": ["number","null"] },
            "refHigh": { "type": ["number","null"] },
            "refText": { "type": ["string","null"] },
            "labFlag": { "type": ["string","null"] },
            "panel": { "type": ["string","null"] },
            "confidence": { "type": "string", "enum": ["high","medium","low"] }
          },
          "required": ["nameRaw","value","confidence"]
        }
      }
    },
    "required": ["markers"]
  }
}
```

**Representative Cloud Function call (TypeScript, `@anthropic-ai/sdk`):**
```ts
import Anthropic from "@anthropic-ai/sdk";
const client = new Anthropic(); // ANTHROPIC_API_KEY from server env only

const msg = await client.messages.create({
  model: "claude-sonnet-4-6",
  max_tokens: 4096,
  tools: [recordLabResultsTool],
  tool_choice: { type: "tool", name: "record_lab_results" },
  messages: [{
    role: "user",
    content: [
      { type: "document", source: { type: "base64", media_type: "application/pdf", data: pdfBase64 } },
      { type: "text", text: EXTRACTION_INSTRUCTIONS } // "Transcribe only. Never decide high/low."
    ],
  }],
});
const toolUse = msg.content.find(b => b.type === "tool_use");
const extracted = toolUse?.input;
```

### 5.2 Validation (deterministic, no LLM)
Normalize units; plausibility-check values against a physiological bounds table (a misread decimal is a safety event); cross-check the lab's printed flag vs. computed; low confidence/failed checks → user confirmation (§3.2).

### 5.3 Flagging (deterministic, no LLM)
Compare `value` to `refLow`/`refHigh` **from the report**. `computedStatus` ∈ { low, in_range, high, critical_low, critical_high, qualitative }. Critical status comes from the separate critical-value table (§6.1).

### 5.4 Explanation generation — Tier 1 (LLM, constrained)
`claude-sonnet-4-6` (or `claude-opus-4-8` for warmer copy). Input: validated + flagged markers + profile + (optional) dietary context — never the raw image again. System prompt enforces §2.1 (wellness framing, no diagnosis, no directive dosing, respects critical + interaction suppression).

### 5.5 Clinical draft generation — Tier 2 (LLM, gated)
`claude-opus-4-8`. Generates a structured **draft** clinical assessment + options with cited rationale, **written for clinician review, not the patient**, and explicitly labeled DRAFT. Output is stored in `clinicalReviews` and is **never released without clinician sign-off (§2.7)**. The clinician edits/approves in the console (§14).

---

## 6. ⚠️ VERIFY — Safety configuration tables

Schemas are ready; **values must come from authoritative, clinician-reviewed references** before the related path ships. Ship with labeled placeholders behind a flag.

**6.1 Critical-value table** — `{ markerStd, unitStd, criticalLow?, criticalHigh?, sourceRef, reviewedBy, reviewedAt }`. Drives §2.3. Do not populate from memory or model output.

**6.2 Nutrient–drug / nutrient–condition interaction table** — `{ nutrient, triggerType: medication|condition, triggerId, action: suppress|warn, note, sourceRef, reviewedBy, reviewedAt }`. Drives §2.4. Illustrative categories a clinician/pharmacist must confirm (placeholders, not facts): potassium with certain BP medications or reduced kidney function; magnesium with advanced kidney disease; vitamin K with anticoagulants; iron with iron-overload conditions; mineral/thyroid-med absorption timing. The mechanism is the point: no supplement shows without passing this gate.

---

## 7. Tech stack (committed)

**7.1 Patient app — native iOS (Xcode).** Swift + SwiftUI; Observation/MVVM. Firebase iOS SDK via Swift Package Manager (Auth, Firestore, Storage, Functions, Crashlytics, Analytics). Swift Charts for trends; VisionKit document scanner + PhotosUI + `.fileImporter` for capture/upload; Keychain for sensitive tokens; call backend via Firebase callable Cloud Functions.

**7.2 Backend — Firebase.** Auth; Cloud Firestore (§4); Cloud Storage (encrypted, signed-URL access); Cloud Functions (2nd gen, Node/TypeScript) — orchestrates the pipeline and holds all AI calls. Cloud Run for steps that risk function timeouts on large docs.

**7.3 AI — Anthropic Claude API.** Models per §5. Structured output via tool use; Files API + prompt caching + Batch API as cost/scale tools. (Tier 2 adds HIPAA constraints on this — §14.)

**7.4 Clinician console — web (Phase 2).** Separate app for the review/edit/sign-off workflow (§3.8, §14); same Firebase backend; role-based access; audit logging.

**7.5 Optional extraction robustness** — a managed document-AI OCR fallback for poor scans, behind the §5.1 confidence gate. Optional given native vision.

**7.6 Payments — RevenueCat** wrapping StoreKit 2; subscription status synced to Firestore via webhook. (StoreKit 2 directly is viable since iOS-only; RevenueCat still simplifies entitlements and a future Android port.)

**7.7 ⛔ Security — keys server-side only.** The Anthropic key (and any partner keys) live in Cloud Functions secrets, never in the app bundle. The iOS app calls *your* callable functions; the functions call Claude. Mandatory.

**7.8 Monitoring** — Crashlytics + Analytics; Sentry optional.

---

## 8. Architecture / system flow

```
[iOS app] --upload--> [Cloud Storage]
   |                        | (trigger)
   |                        v
   |                 [Fn: extract] --document/image--> [Claude: record_lab_results]
   |                        |  <-- structured JSON --
   |                        v
   |                 [Validation + Flagging engine]  (deterministic, /packages/core)
   |                        |
   |                 [Critical check] --critical?--> pin urgent banner, suppress pathway
   |                        |
[iOS] <--confirm values-----+
   |                        v
   |                 [Interaction screen] (meds/conditions) -> gate suggestions
   |                        v
   |                 [Fn: explain — Tier 1] --structured data+profile--> [Claude: explanations]
   |                        v
[iOS] <--- Tier-1 dashboard + gated supplement plan + trends ---

   ...request clinical review (Tier 2)...
[iOS] --escalate--> [Fn: clinical draft] --> [Claude: DRAFT assessment]
                          |
                          v
                 [clinicalReviews: pending]  --> [Clinician console: review/edit/sign-off]
                          |  (NO release without sign-off — §2.7)
                          v
[iOS] <--- clinician-authored guidance (+ optional telehealth consult) ---
```

---

## 9. Privacy & compliance

**Tier 1 (DTC):** even non-HIPAA health apps are subject to the **FTC Health Breach Notification Rule** and state health-privacy laws — notably **Washington's My Health My Data Act** (broad; private right of action). Build: encryption in transit + at rest; versioned consent capture; in-app data **export and delete** (DSAR) that purges Storage; clear no-sell/no-train privacy policy; regional handling.

**Tier 2 activates HIPAA.** Once licensed clinicians deliver care through the platform, you're a covered entity / business associate — see **§14** for the full program (BAAs, HIPAA-eligible services, audit logging, etc.). ⚠️ VERIFY structure with counsel.

---

## 10. Monetization & integrations

**10.1 Subscription** — freemium via RevenueCat/StoreKit. First analysis free; subscription for ongoing analyses, trends, full plans. Price under testing-based incumbents (your upload-first model has far lower cost-to-serve).

**10.2 Supplement commerce** — recommend on **third-party-tested quality** (USP Verified, NSF Certified, Informed Sport) with cert badges; monetize via **Fullscript** (practitioner dispensary; also bridges the clinical/doctor features) or a general affiliate program. ⚠️ VERIFY current API/partner access. **Disclose** all affiliate relationships in-app.

**10.3 Doctor directory — disclosed sponsored listings, NOT pay-per-referral.** ⚠️ VERIFY with a healthcare attorney. Paying for *referrals of patients* can implicate anti-kickback / fee-splitting rules; a labeled advertising/listing model is the defensible structure.

**10.4 Clinical consults (Tier 2)** — telehealth/async review fees, gated by §14's prerequisites.

---

## 11. Phased build roadmap (build in this order)

**Milestone 1 — Accurate, safe core (Tier 1).** Auth + consent + intake → upload (VisionKit/PhotosUI/file importer) → extraction (§5.1) → user confirmation → validation + flagging (§5.2–5.3) → critical escalation (§2.3, §6.1 placeholders behind a flag) → Tier-1 results dashboard. **No supplement suggestions yet.** Prove extraction accuracy and safe display.

**Milestone 2 — Guidance, gated (Tier 1).** Interaction engine (§2.4, §6.2) → Tier-1 explanations (§5.4) → supplement plan (food-first, cert badges, affiliate) → paywall + RevenueCat.

**Milestone 3 — Retention + growth (Tier 1).** Trends (Swift Charts) → dietary-context integration (the differentiator) → polish, analytics. **Tier 1 is fully shippable solo after this.**

**Clinical Phase (Tier 2) — gated; do NOT launch to patients until §14 prerequisites exist.** Build the clinician console (§7.4), the draft-generation pipeline (§5.5), the review/sign-off workflow (§2.7, §3.8), and the HIPAA program (§9, §14). Engineering can proceed in parallel, but patient-facing clinical output stays disabled until the medical, legal, and regulatory prerequisites are met.

**Marketplace.** Doctor directory + sponsored listings (after legal sign-off, §10.3).

**Cross-cutting (every milestone):** privacy/consent/delete (§9), the §2 guardrails, server-side-only keys (§7.7).

---

## 12. Must-verify-before-launch checklist (human-in-the-loop)

**Tier 1:**
- [ ] ⚠️ Critical-value table (§6.1) populated from a clinician-reviewed source.
- [ ] ⚠️ Interaction table (§6.2) populated/confirmed by a clinician or pharmacist.
- [ ] ⚠️ Wellness-tier framing (§2.1) confirmed by a regulatory attorney.
- [ ] ⚠️ Privacy (§9): FTC HBNR + state-law obligations covered; export/delete working.
- [ ] ⚠️ Affiliate/dispensary terms (§10.2) confirmed and disclosed.
- [ ] API keys confirmed absent from the app bundle (§7.7).

**Tier 2 (all of §14 before any clinical feature reaches a patient):**
- [ ] ⚠️ Medical director + licensed clinician network in place.
- [ ] ⚠️ CPOM-compliant corporate structure (PC/MSO).
- [ ] ⚠️ Multi-state licensing + telehealth compliance.
- [ ] ⚠️ Malpractice / professional + product liability insurance.
- [ ] ⚠️ HIPAA program live (BAAs incl. cloud + AI vendor, HIPAA-eligible services, audit logging).
- [ ] ⚠️ FDA regulatory determination completed (CDS exemption vs. clearance — §14).
- [ ] Sign-off workflow (§2.7) verified: no AI clinical output releases without a clinician.

---

## 13. Open decisions to fill in
- App name + branding.
- Affiliate partner: Fullscript vs. general affiliate (§10.2).
- Subscription price points and free-tier limit.
- Launch geography (drives §9 / §14 obligations).
- Tier 2 timing: build the clinical layer now (disabled until §14 is met) vs. defer until the clinical org exists.

---

## 14. Clinical tier (Tier 2) — architecture & prerequisites

> ⚠️ This section is the general regulatory/operational landscape, **not legal, regulatory, or medical advice.** Engage a healthcare attorney, a regulatory consultant, and a medical director early. The items below are prerequisites, not nice-to-haves.

**Why it's built clinician-in-the-loop.** Software that autonomously *diagnoses or treats* disease for a patient is, in the US, both (a) a regulated **medical device** (FDA — Software as a Medical Device) and (b) the **practice of medicine**, which only licensed clinicians may do. Putting a licensed clinician as the decision-maker (AI drafts, human reviews and signs) is the defensible architecture: the human is accountable, and clinician-facing decision support has a path (the Cures Act CDS criteria) that patient-facing autonomous diagnosis does not. Hence §2.7.

**The workflow.** AI generates a draft assessment + options with cited rationale (§5.5) → lands in a clinician queue → a licensed clinician reviews, edits, and e-signs in the console → only then is clinician-authored guidance released to the patient, optionally with an async or live telehealth consult. Full audit trail on every step.

**Prerequisites before any clinical feature reaches real patients:**
1. **Medical director + licensed clinician network** (employed or contracted) to own clinical decisions.
2. **CPOM-compliant corporate structure** — many states bar lay-owned companies from employing physicians to practice medicine; the common answer is a physician-owned professional corporation (PC) with a management services organization (MSO). Healthcare attorney required.
3. **Multi-state licensing + telehealth compliance** — clinicians must be licensed in each patient's state; telehealth and standard-of-care rules vary (the "50-state problem").
4. **Insurance** — medical malpractice / professional liability, plus product liability.
5. **HIPAA compliance program** (now active because clinicians deliver care through the platform): Business Associate Agreement with Google Cloud and use of only HIPAA-eligible services; a HIPAA-compliant configuration with your AI provider (e.g., a BAA + zero-data-retention, or access via a HIPAA-eligible cloud platform); audit logging, access controls, breach-notification procedures, workforce training.
6. **FDA regulatory determination** — with counsel/a regulatory consultant, determine whether your clinician-facing AI qualifies as **non-device Clinical Decision Support** under the 21st Century Cures Act criteria (clinician is the user; the clinician can independently review the basis of the recommendation; not for time-critical decisions) or whether it requires clearance (510(k) / De Novo). Patient-facing autonomous diagnosis generally does **not** qualify and would be a regulated device with a substantial submission and timeline.
7. **Risk + quality management** appropriate to the path (e.g., ISO 14971 risk management; a quality system if it's a device).

**Reality check.** Tier 2 is a separate, well-resourced build — clinical staff, lawyers, insurance, a HIPAA program, and possibly an FDA timeline measured in months. It is not a feature toggle. Recommended sequence: ship Tier 1 now (fully solo-buildable in Xcode), build the Tier 2 plumbing in parallel with patient-facing output disabled, and switch it on only once the prerequisites above are in place.
