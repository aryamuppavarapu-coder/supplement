/**
 * Anthropic tool schemas for structured output (SPEC §5.1, §5.4, §5.5).
 *
 * `tool_choice` is pinned to these so the model is forced to return structured data.
 */
import type Anthropic from "@anthropic-ai/sdk";

/**
 * SPEC §5.1 extraction tool. The model transcribes values EXACTLY as printed and never
 * judges high/low (that is done deterministically by @supplement/core afterwards).
 */
export const recordLabResultsTool: Anthropic.Tool = {
  name: "record_lab_results",
  description:
    "Transcribe lab values exactly as printed. Do not infer, normalize, or judge whether a value is high or low. If a value is illegible, set value to null and confidence to low.",
  input_schema: {
    type: "object",
    properties: {
      labName: { type: ["string", "null"] },
      reportDate: { type: ["string", "null"] },
      collectionDate: { type: ["string", "null"] },
      patientAge: { type: ["number", "null"] },
      patientSex: { type: ["string", "null"] },
      markers: {
        type: "array",
        items: {
          type: "object",
          properties: {
            nameRaw: { type: "string" },
            value: { type: ["number", "null"] },
            unitRaw: { type: ["string", "null"] },
            refLow: { type: ["number", "null"] },
            refHigh: { type: ["number", "null"] },
            refText: { type: ["string", "null"] },
            labFlag: { type: ["string", "null"] },
            panel: { type: ["string", "null"] },
            confidence: { type: "string", enum: ["high", "medium", "low"] },
          },
          required: ["nameRaw", "value", "confidence"],
        },
      },
    },
    required: ["markers"],
  } as Anthropic.Tool.InputSchema,
};

/**
 * SPEC §5.4 Tier-1 explanation tool. The model EXPLAINS an already-computed result in
 * wellness language. It must never restate/change a status, never diagnose, never dose.
 */
export const writeExplanationsTool: Anthropic.Tool = {
  name: "write_explanations",
  description:
    "Write plain-language, wellness-framed explanations for marker statuses that have ALREADY been computed deterministically. Never change or restate a status as a judgment. Never name a disease the user 'has'. Never state a supplement dose. Frame supplements as 'general wellness support to discuss with your doctor or pharmacist'.",
  input_schema: {
    type: "object",
    properties: {
      overallSummary: {
        type: "string",
        description: "2-4 sentence wellness-framed overview. No diagnosis. Routes to a provider.",
      },
      markerExplanations: {
        type: "array",
        items: {
          type: "object",
          properties: {
            index: {
              type: "number",
              description: "Echo back the exact index you were given for this marker (used to match unambiguously).",
            },
            nameRaw: { type: "string" },
            explanation: {
              type: "string",
              description:
                "What this marker does and what out-of-range values are commonly associated with, as education. 'Above/below the typical reference range', never 'you have X'.",
            },
            foodContext: {
              type: "string",
              description: "Food-first dietary context for this marker (the differentiator). Optional.",
            },
          },
          required: ["index", "nameRaw", "explanation"],
        },
      },
      planItems: {
        type: "array",
        description:
          "Only for nutrients explicitly passed in as cleared by the safety gate. Food sources first, supplement second. No dose.",
        items: {
          type: "object",
          properties: {
            nutrient: { type: "string" },
            rationaleText: {
              type: "string",
              description: "Why this nutrient is relevant, wellness-framed. Ends by routing to a provider.",
            },
            foodSources: { type: "array", items: { type: "string" } },
          },
          required: ["nutrient", "rationaleText", "foodSources"],
        },
      },
    },
    required: ["overallSummary", "markerExplanations"],
  } as Anthropic.Tool.InputSchema,
};

/**
 * SPEC §5.5 Tier-2 clinical DRAFT tool. Output is written FOR A CLINICIAN TO REVIEW,
 * explicitly labeled DRAFT, and is NEVER released to a patient without sign-off (§2.7).
 */
export const clinicalDraftTool: Anthropic.Tool = {
  name: "draft_clinical_assessment",
  description:
    "Draft a structured clinical assessment and options WITH CITED RATIONALE for a licensed clinician to review, edit, and sign. This is decision SUPPORT, not a decision. It is explicitly a DRAFT and must never be shown to a patient without clinician sign-off.",
  input_schema: {
    type: "object",
    properties: {
      draftAssessment: { type: "string" },
      differentialConsiderations: { type: "array", items: { type: "string" } },
      options: {
        type: "array",
        items: {
          type: "object",
          properties: {
            option: { type: "string" },
            rationale: { type: "string" },
            citations: { type: "array", items: { type: "string" } },
          },
          required: ["option", "rationale"],
        },
      },
      uncertaintiesForClinician: { type: "array", items: { type: "string" } },
    },
    required: ["draftAssessment", "options"],
  } as Anthropic.Tool.InputSchema,
};
