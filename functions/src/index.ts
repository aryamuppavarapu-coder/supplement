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

// NOTE: in ESM, the re-exports below evaluate BEFORE this statement, so setGlobalOptions
// does NOT change the callables' region — they use the firebase default (us-central1), which
// is where they're live and what the iOS app targets (AppConfig.functionsRegion). The
// onReportUpload storage trigger is pinned to the bucket region (us-east1) automatically.
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

export { onReportUpload } from "./extract.js";
export { confirmAndExplain } from "./explain.js";
export { requestClinicalReview } from "./clinical.js";
export { listClinicalReviews, signOffClinicalReview } from "./clinicianConsole.js";
export { deleteAccount, deleteReport } from "./account.js";
