import { build } from "esbuild";

// Bundles src/index.ts into a single self-contained dist/index.js so Firebase's cloud
// build doesn't need the unpublished @supplement/core workspace package (it gets inlined).
// The real npm dependencies stay external — the cloud installs them from package.json.
await build({
  entryPoints: ["src/index.ts"],
  bundle: true,
  platform: "node",
  format: "esm",
  target: "node20",
  outfile: "dist/index.js",
  sourcemap: true,
  external: [
    "firebase-admin",
    "firebase-admin/*",
    "firebase-functions",
    "firebase-functions/*",
    "@anthropic-ai/sdk",
    "@anthropic-ai/sdk/*",
  ],
});

console.log("functions bundled -> dist/index.js");
