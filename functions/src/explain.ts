/**
 * Tier-1 confirmation + explanation (SPEC §3.2, §5.4, §8).
 *
 * Callable invoked after the user confirms/corrects extracted values. Re-runs the
 * DETERMINISTIC engine on the (possibly corrected) values, builds the gated supplement
 * plan, then asks Claude ONLY to explain the already-computed result in wellness language
 * (§2.1) for the nutrients the safety gate cleared. The model cannot change a status and
 * cannot surface a suppressed nutrient.
 */
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import {
  allowedNutrients,
  buildSupplementGate,
  processReport,
  type ExtractedMarker,
  type NutrientGateResult,
  type ProcessedReport,
  type UserProfile,
} from "@supplement/core";
import { db } from "./firebase.js";
import { makeClient, MODELS } from "./anthropic.js";
import { writeExplanationsTool } from "./tools.js";
import { EXPLANATION_SYSTEM } from "./prompts.js";
import { loadSafetyConfig } from "./safetyConfig.js";
import { toUserProfile } from "./mappers.js";
import { anthropicKey } from "./secrets.js";

interface ExplainRequest {
  reportId?: string;
  /** Map of marker index -> corrected fields (value/unit). */
  corrections?: Record<string, Partial<ExtractedMarker>>;
}

interface Explanations {
  overallSummary: string;
  markerExplanations: Array<{ index?: number; nameRaw: string; explanation: string; foodContext?: string }>;
  planItems?: Array<{ nutrient: string; rationaleText: string; foodSources: string[] }>;
}

async function generateExplanations(
  report: ProcessedReport,
  profile: UserProfile,
  cleared: NutrientGateResult[],
  apiKey: string,
): Promise<Explanations> {
  const client = makeClient(apiKey);

  // Only structured, already-computed data is sent to the model — never the raw image again.
  const payload = {
    profile: { age: profile.age, sex: profile.sex, pregnant: profile.pregnant },
    hasCritical: report.hasCritical,
    criticalMarkers: report.criticalMarkers,
    markers: report.markers.map((m, i) => ({
      index: i,
      nameRaw: m.nameRaw,
      nameStd: m.nameStd,
      value: m.value,
      unit: m.unitStd ?? m.unitRaw,
      refLow: m.refLow,
      refHigh: m.refHigh,
      computedStatus: m.computedStatus,
    })),
    clearedNutrients: cleared.map((c) => ({
      nutrient: c.nutrient,
      relatedMarker: c.fromMarker,
      caution: c.decision === "warn",
      interactionNotes: c.interactionNotes,
    })),
  };

  const criticalNote = report.hasCritical
    ? "A CRITICAL value is present. Defer entirely to urgent-care guidance, do not soften it, and do not suggest supplements for that pathway."
    : "No critical values.";

  const msg = await client.messages.create({
    model: MODELS.explanation,
    max_tokens: 3072,
    system: EXPLANATION_SYSTEM,
    tools: [writeExplanationsTool],
    tool_choice: { type: "tool", name: "write_explanations" },
    messages: [
      {
        role: "user",
        content: [
          {
            type: "text",
            text:
              `${criticalNote}\n\nExplain these already-computed results. ` +
              `Only mention nutrients in clearedNutrients. Do not change any status.\n\n` +
              JSON.stringify(payload, null, 2),
          },
        ],
      },
    ],
  });

  if (msg.stop_reason === "max_tokens") {
    throw new Error("Explanation truncated (max_tokens).");
  }
  const toolUse = msg.content.find((b) => b.type === "tool_use");
  if (!toolUse || toolUse.type !== "tool_use") {
    throw new Error("Model did not return write_explanations tool output");
  }
  return toolUse.input as Explanations;
}

export const confirmAndExplain = onCall({ secrets: [anthropicKey], timeoutSeconds: 300 }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const { reportId, corrections } = (req.data ?? {}) as ExplainRequest;
  if (!reportId) throw new HttpsError("invalid-argument", "reportId is required.");

  const reportRef = db.doc(`users/${uid}/reports/${reportId}`);
  const snap = await reportRef.get();
  if (!snap.exists) throw new HttpsError("not-found", "Report not found.");
  const data = snap.data()!;

  const markersRaw: ExtractedMarker[] = data.extraction?.markersRaw ?? [];
  if (markersRaw.length === 0) {
    throw new HttpsError("failed-precondition", "Report has not been extracted yet.");
  }

  // Apply user corrections, then re-flag deterministically.
  const corrected = markersRaw.map((mk, i) => {
    const fix = corrections?.[String(i)];
    return fix ? { ...mk, ...fix } : mk;
  });

  const config = loadSafetyConfig();
  const processed = processReport({ markers: corrected }, config);

  const profileSnap = await db.doc(`users/${uid}`).get();
  const profile = toUserProfile(profileSnap.data());

  const gate = buildSupplementGate(processed, profile, config);
  const cleared = allowedNutrients(gate);

  let explanations: Explanations | null = null;
  try {
    explanations = await generateExplanations(processed, profile, cleared, anthropicKey.value());
  } catch (err) {
    logger.error("Explanation generation failed", { uid, reportId, error: String(err) });
    // Non-fatal: the dashboard can still show deterministic statuses without prose.
  }

  // Persist corrected/flagged markers (+ explanation prose) and the gated plan.
  const batch = db.batch();
  const markersCol = reportRef.collection("markers");
  processed.markers.forEach((mk, i) => {
    // Match by positional index first (unambiguous even with duplicate printed names),
    // falling back to nameRaw if the model omitted the index.
    const exp =
      explanations?.markerExplanations.find((e) => e.index === i) ??
      explanations?.markerExplanations.find((e) => e.index === undefined && e.nameRaw === mk.nameRaw);
    batch.set(
      markersCol.doc(String(i).padStart(3, "0")),
      { ...mk, explanation: exp?.explanation ?? null, foodContext: exp?.foodContext ?? null },
      { merge: true },
    );
  });

  const planRef = reportRef.parent.parent!.collection("plans").doc(reportId);
  batch.set(planRef, {
    reportId,
    generatedAt: FieldValue.serverTimestamp(),
    enabled: gate.enabled,
    withheldReason: gate.withheldReason ?? null,
    items: gate.candidates.map((c) => {
      const prose = explanations?.planItems?.find((p) => p.nutrient === c.nutrient);
      return {
        nutrient: c.nutrient,
        fromMarker: c.fromMarker,
        decision: c.decision,
        suppressedByInteraction: c.decision === "suppress",
        interactionNote: c.interactionNotes.join(" ") || null,
        rationaleText: c.decision === "suppress" ? null : prose?.rationaleText ?? null,
        foodSources: c.decision === "suppress" ? [] : prose?.foodSources ?? [],
      };
    }),
  });

  batch.set(
    reportRef,
    {
      status: "analyzed",
      analysis: {
        hasCritical: processed.hasCritical,
        criticalMarkers: processed.criticalMarkers,
        overallSummary: explanations?.overallSummary ?? null,
        analyzedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await batch.commit();

  return {
    status: "analyzed",
    hasCritical: processed.hasCritical,
    needsHumanReview: processed.needsHumanReview,
    planEnabled: gate.enabled,
  };
});
