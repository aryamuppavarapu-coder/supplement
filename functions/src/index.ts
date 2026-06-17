/**
 * Cloud Functions entrypoint (SPEC §7.2, §8).
 *
 * - onReportUpload   — storage trigger: extract (Claude) → deterministic flag → Firestore
 * - confirmAndExplain — callable: re-flag corrected values → gated plan → Tier-1 explanations
 * - requestClinicalReview — callable: Tier-2 DRAFT, HARD-GATED + clinician sign-off (§2.7)
 *
 * All Anthropic calls live here, server-side, behind the ANTHROPIC_API_KEY secret (§7.7).
 */
import { setGlobalOptions } from "firebase-functions/v2";

// Region must match the Cloud Storage bucket's region (the onReportUpload trigger
// listens to it). This project's default bucket is us-east1.
setGlobalOptions({ region: "us-east1", maxInstances: 10 });

export { onReportUpload } from "./extract.js";
export { confirmAndExplain } from "./explain.js";
export { requestClinicalReview } from "./clinical.js";
export { listClinicalReviews, signOffClinicalReview } from "./clinicianConsole.js";
export { deleteAccount, deleteReport } from "./account.js";
