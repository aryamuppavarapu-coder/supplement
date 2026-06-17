/**
 * Storage-triggered extraction (SPEC §5.1, §8).
 *
 * Fires when the iOS app uploads a report file to users/{uid}/reports/{reportId}/<file>.
 * Sends the document/image to Claude with tool_choice pinned to record_lab_results,
 * then runs the DETERMINISTIC engine to validate + flag. The model never decides
 * high/low (§2.2). Writes per-marker results + report status to Firestore.
 */
import { onObjectFinalized } from "firebase-functions/v2/storage";
import { logger } from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import type Anthropic from "@anthropic-ai/sdk";
import { processReport, type ExtractedReport } from "@supplement/core";
import { db, storage } from "./firebase.js";
import { makeClient, MODELS } from "./anthropic.js";
import { recordLabResultsTool } from "./tools.js";
import { EXTRACTION_INSTRUCTIONS } from "./prompts.js";
import { loadSafetyConfig } from "./safetyConfig.js";
import { anthropicKey } from "./secrets.js";

const PATH_RE = /^users\/([^/]+)\/reports\/([^/]+)\/.+/;

function buildSourceBlock(contentType: string, base64: string): Anthropic.ContentBlockParam {
  if (contentType.includes("pdf")) {
    return {
      type: "document",
      source: { type: "base64", media_type: "application/pdf", data: base64 },
    } as Anthropic.ContentBlockParam;
  }
  const media_type = contentType.includes("png") ? "image/png" : "image/jpeg";
  return {
    type: "image",
    source: { type: "base64", media_type, data: base64 },
  } as Anthropic.ContentBlockParam;
}

export const onReportUpload = onObjectFinalized(
  { secrets: [anthropicKey], memory: "1GiB", timeoutSeconds: 540 },
  async (event) => {
    const name = event.data.name;
    if (!name) return;
    const match = PATH_RE.exec(name);
    if (!match) return; // not a report upload — ignore
    const uid = match[1]!;
    const reportId = match[2]!;
    const contentType = event.data.contentType ?? "";
    const reportRef = db.doc(`users/${uid}/reports/${reportId}`);

    try {
      await reportRef.set(
        {
          source: { storagePath: name, fileType: contentType, uploadedAt: FieldValue.serverTimestamp() },
          status: "uploaded",
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      const [buf] = await storage.bucket(event.data.bucket).file(name).download();
      const base64 = buf.toString("base64");

      const client = makeClient(anthropicKey.value());
      const content: Anthropic.ContentBlockParam[] = [
        buildSourceBlock(contentType, base64),
        { type: "text", text: EXTRACTION_INSTRUCTIONS },
      ];

      const msg = await client.messages.create({
        model: MODELS.extraction,
        max_tokens: 4096,
        tools: [recordLabResultsTool],
        tool_choice: { type: "tool", name: "record_lab_results" },
        messages: [{ role: "user", content }],
      });

      // A truncated response can carry a partial markers array — accepting it could silently
      // drop a marker (including a critical one). Fail loudly so the catch sets status "error".
      if (msg.stop_reason === "max_tokens") {
        throw new Error("Extraction truncated (max_tokens) — report too large; split at section boundaries (SPEC §5.1).");
      }

      const toolUse = msg.content.find((b) => b.type === "tool_use");
      if (!toolUse || toolUse.type !== "tool_use") {
        throw new Error("Model did not return record_lab_results tool output");
      }
      const extracted = toolUse.input as ExtractedReport;

      // ── DETERMINISTIC engine — the only thing allowed to decide high/low/critical ──
      const config = loadSafetyConfig();
      const processed = processReport(extracted, config);

      const batch = db.batch();
      const markersCol = reportRef.collection("markers");
      processed.markers.forEach((mk, i) => {
        batch.set(markersCol.doc(String(i).padStart(3, "0")), mk);
      });
      batch.set(
        reportRef,
        {
          lab: {
            labName: extracted.labName ?? null,
            reportDate: extracted.reportDate ?? null,
            collectionDate: extracted.collectionDate ?? null,
          },
          extraction: {
            model: MODELS.extraction,
            completedAt: FieldValue.serverTimestamp(),
            needsHumanReview: processed.needsHumanReview,
            markerCount: processed.markers.length,
            // Keep the raw transcription so corrections can be re-flagged deterministically.
            markersRaw: extracted.markers,
          },
          analysis: { hasCritical: processed.hasCritical, criticalMarkers: processed.criticalMarkers },
          // User confirms/corrects next (SPEC §3.2) before explanations are generated.
          status: "extracted",
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      await batch.commit();

      logger.info("Report extracted", {
        uid,
        reportId,
        markers: processed.markers.length,
        hasCritical: processed.hasCritical,
        needsHumanReview: processed.needsHumanReview,
      });
    } catch (err) {
      logger.error("Extraction failed", { uid, reportId, error: String(err) });
      await reportRef.set(
        { status: "error", error: String(err), updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
  },
);
