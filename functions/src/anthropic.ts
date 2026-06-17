/**
 * Anthropic client + model selection (SPEC §5, §7.3).
 *
 * The API key is provided as a Cloud Functions secret (SPEC §7.7) and passed in per call;
 * it is never read from the client and never logged.
 */
import Anthropic from "@anthropic-ai/sdk";

/** Model ids per SPEC §5.1. */
export const MODELS = {
  /** Cheap "is this a lab report?" classifier. */
  classifier: "claude-haiku-4-5-20251001",
  /** Default multimodal extraction. */
  extraction: "claude-sonnet-4-6",
  /** Higher-resolution vision for low-quality scans. */
  extractionHiRes: "claude-opus-4-8",
  /** Tier 1 constrained explanations. */
  explanation: "claude-sonnet-4-6",
  /** Tier 2 clinician-facing DRAFT (gated, never patient-facing without sign-off). */
  clinicalDraft: "claude-opus-4-8",
} as const;

export function makeClient(apiKey: string): Anthropic {
  return new Anthropic({ apiKey });
}
