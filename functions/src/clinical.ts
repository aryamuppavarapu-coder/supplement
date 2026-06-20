/**
 * Tier-2 clinical DRAFT generation (SPEC §2.7, §3.8, §5.5, §14).
 *
 * ⛔ HARD-GATED. This function is disabled unless CLINICAL_TIER_ENABLED === "true", which
 * must NOT be set until every §14 prerequisite exists (medical director, CPOM structure,
 * licensing, insurance, live HIPAA program, FDA determination).
 *
 * Even when enabled, it ONLY produces a DRAFT for a clinician queue. It writes to
 * clinicalReviews/{id} with status "pending" and NEVER releases anything to the patient.
 * Release happens only after a licensed clinician edits + signs off in the console (§2.7).
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./firebase.js";
import { makeClient, MODELS } from "./anthropic.js";
import { clinicalDraftTool } from "./tools.js";
import { CLINICAL_DRAFT_SYSTEM } from "./prompts.js";
import { toUserProfile } from "./mappers.js";
import { anthropicKey } from "./secrets.js";

function clinicalTierEnabled(): boolean {
  return process.env.CLINICAL_TIER_ENABLED === "true";
}

export const requestClinicalReview = onCall({ secrets: [anthropicKey], timeoutSeconds: 300 }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  // ⛔ The gate that makes the clinical tier lawful (SPEC §2.7, §14).
  if (!clinicalTierEnabled()) {
    throw new HttpsError(
      "failed-precondition",
      "Clinical review is not available yet. This feature stays disabled until the clinical, legal, and regulatory prerequisites (SPEC §14) are in place.",
    );
  }

  const { reportId } = (req.data ?? {}) as { reportId?: string };
  if (!reportId) throw new HttpsError("invalid-argument", "reportId is required.");

  const reportRef = db.doc(`users/${uid}/reports/${reportId}`);
  const snap = await reportRef.get();
  if (!snap.exists) throw new HttpsError("not-found", "Report not found.");
  const data = snap.data()!;

  const profileSnap = await db.doc(`users/${uid}`).get();
  const profile = toUserProfile(profileSnap.data());

  const client = makeClient(anthropicKey.value());
  const msg = await client.messages.create({
    model: MODELS.clinicalDraft,
    max_tokens: 4096,
    system: CLINICAL_DRAFT_SYSTEM,
    tools: [clinicalDraftTool],
    tool_choice: { type: "tool", name: "draft_clinical_assessment" },
    messages: [
      {
        role: "user",
        content: [
          {
            type: "text",
            text:
              "Draft a clinician-facing assessment for review. This is NOT for the patient.\n\n" +
              JSON.stringify(
                {
                  profile: { age: profile.age, sex: profile.sex, pregnant: profile.pregnant },
                  medications: profile.medications,
                  conditions: profile.conditions,
                  markers: data.extraction?.markersRaw ?? [],
                  analysis: data.analysis ?? null,
                },
                null,
                2,
              ),
          },
        ],
      },
    ],
  });

  // A truncated draft could silently drop a differential or its cited rationale — reject it
  // so a clinician never reviews incomplete AI output (SPEC §2.7).
  if (msg.stop_reason === "max_tokens") {
    throw new HttpsError("internal", "Clinical draft truncated (max_tokens) — input too large; split it before review.");
  }

  const toolUse = msg.content.find((b) => b.type === "tool_use");
  if (!toolUse || toolUse.type !== "tool_use") {
    throw new HttpsError("internal", "Draft generation failed.");
  }

  // PHI — HIPAA scope (SPEC §4, §14). Written to a clinician queue, NOT to the patient.
  const reviewRef = db.collection("clinicalReviews").doc();
  await reviewRef.set({
    uid,
    reportId,
    draftedByModel: MODELS.clinicalDraft,
    draftCreatedAt: FieldValue.serverTimestamp(),
    draft: toolUse.input,
    clinicianId: null,
    status: "pending",
    clinicianNotes: null,
    signedOffAt: null,
    releasedToPatientAt: null,
    // NOTE: a FieldValue.serverTimestamp() sentinel is NOT allowed inside an array element,
    // so use a concrete Timestamp here (matches clinicianConsole.ts auditTrail handling).
    auditTrail: [{ event: "draft_created", at: Timestamp.now(), by: "system" }],
  });

  // The patient sees only that a review was requested — never the AI draft (SPEC §2.7).
  await reportRef.set(
    { status: "clinical_pending", clinicalReviewId: reviewRef.id, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );

  logger.info("Clinical draft queued for review", { uid, reportId, reviewId: reviewRef.id });
  return { status: "clinical_pending", message: "A licensed clinician will review your report." };
});
