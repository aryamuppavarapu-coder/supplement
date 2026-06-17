/**
 * Clinician console callables (SPEC §3.8, §7.4, §14). These power the Tier-2 review/sign-off
 * workflow. HARD-GATED three ways:
 *   1) CLINICAL_TIER_ENABLED must be "true" (all §14 prerequisites in place), and
 *   2) the caller must carry a `clinician` custom claim, and
 *   3) nothing reaches a patient except via an explicit clinician approval here (SPEC §2.7).
 */
import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./firebase.js";

function assertClinician(req: CallableRequest): string {
  if (process.env.CLINICAL_TIER_ENABLED !== "true") {
    throw new HttpsError("failed-precondition", "Clinical tier is disabled (SPEC §14 prerequisites not met).");
  }
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  if (req.auth?.token?.clinician !== true) {
    throw new HttpsError("permission-denied", "Clinician access required.");
  }
  return uid;
}

export const listClinicalReviews = onCall(async (req) => {
  assertClinician(req);
  const snap = await db
    .collection("clinicalReviews")
    .where("status", "in", ["pending", "edited"])
    .orderBy("draftCreatedAt")
    .get();
  return { reviews: snap.docs.map((d) => ({ id: d.id, ...d.data() })) };
});

interface SignOffRequest {
  reviewId?: string;
  decision?: "approved" | "declined" | "edited";
  /** Clinician-authored content that REPLACES the AI draft when releasing (SPEC §2.7). */
  editedContent?: unknown;
  clinicianNotes?: string;
}

export const signOffClinicalReview = onCall(async (req) => {
  const clinicianId = assertClinician(req);
  const { reviewId, decision, editedContent, clinicianNotes } = (req.data ?? {}) as SignOffRequest;
  if (!reviewId || !decision || !["approved", "declined", "edited"].includes(decision)) {
    throw new HttpsError("invalid-argument", "reviewId and a valid decision are required.");
  }

  const ref = db.collection("clinicalReviews").doc(reviewId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Review not found.");
  const review = snap.data()!;

  const auditEntry = { event: `clinician_${decision}`, at: Timestamp.now(), by: clinicianId };
  const update: FirebaseFirestore.DocumentData = {
    clinicianId,
    status: decision,
    clinicianNotes: clinicianNotes ?? null,
    auditTrail: FieldValue.arrayUnion(auditEntry),
  };

  if (decision === "approved") {
    // Only here does anything reach the patient — and only the CLINICIAN-AUTHORED content,
    // never the raw AI draft unless the clinician explicitly approved it as-is (SPEC §2.7).
    update.signedOffAt = FieldValue.serverTimestamp();
    update.releasedToPatientAt = FieldValue.serverTimestamp();
    update.releasedContent = editedContent ?? review.draft;

    await db.doc(`users/${review.uid}/reports/${review.reportId}`).set(
      {
        status: "clinical_released",
        clinicianGuidance: editedContent ?? review.draft,
        clinicalReviewId: reviewId,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  await ref.set(update, { merge: true });
  logger.info("Clinical review signed off", { reviewId, decision, clinicianId });
  return { status: decision };
});
