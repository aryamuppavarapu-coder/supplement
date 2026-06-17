/**
 * Account deletion / DSAR purge (SPEC §9). Deleting the top-level user doc from the client
 * does NOT remove Firestore subcollections, Storage files, or the out-of-tree clinicalReviews
 * PHI — so deletion runs server-side here, with the Admin SDK, and purges everything before the
 * Auth record is removed (so the user can't be stranded mid-purge).
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { logger } from "firebase-functions";
import { db, storage } from "./firebase.js";

export const deleteAccount = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  // 1) Firestore: user doc + reports/{id}, reports/{id}/markers, plans/{id} subcollections.
  await db.recursiveDelete(db.doc(`users/${uid}`));

  // 2) Storage: every uploaded report file under the user's prefix.
  await storage.bucket().deleteFiles({ prefix: `users/${uid}/` });

  // 3) clinicalReviews PHI keyed to this user (SPEC §4, §14). A real deployment may instead
  //    apply a documented legal-hold/retention exception with audit logging.
  const reviews = await db.collection("clinicalReviews").where("uid", "==", uid).get();
  if (!reviews.empty) {
    const batch = db.batch();
    reviews.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }

  // 4) Delete the Auth record LAST.
  await getAuth().deleteUser(uid);

  logger.info("Account fully deleted (DSAR purge)", { uid, reviewsDeleted: reviews.size });
  return { deleted: true };
});

/**
 * Delete a single report and everything under it: the report doc + its markers subcollection,
 * the matching plan, and the uploaded Storage file. Server-side because the client cannot delete
 * the function-authored markers subcollection (SPEC §2.2) or recurse subcollections.
 */
export const deleteReport = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const { reportId } = (req.data ?? {}) as { reportId?: string };
  if (!reportId) throw new HttpsError("invalid-argument", "reportId is required.");

  await db.recursiveDelete(db.doc(`users/${uid}/reports/${reportId}`));
  await db.doc(`users/${uid}/plans/${reportId}`).delete();
  await storage.bucket().deleteFiles({ prefix: `users/${uid}/reports/${reportId}/` });

  logger.info("Report deleted", { uid, reportId });
  return { deleted: true };
});
