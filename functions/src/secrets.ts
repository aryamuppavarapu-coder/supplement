/** Server-side secret (SPEC §7.7). Set via: firebase functions:secrets:set ANTHROPIC_API_KEY */
import { defineSecret } from "firebase-functions/params";

export const anthropicKey = defineSecret("ANTHROPIC_API_KEY");
