# iOS app (`Supplement`)

Native SwiftUI app (SPEC §7.1). Built **in the cloud on Codemagic** because Xcode can't run on Windows — see `../codemagic.yaml`.

## Structure

```
ios/
  project.yml                 # XcodeGen project (the .xcodeproj is generated, not committed)
  Supplement/
    SupplementApp.swift        # entry; configures Firebase + RevenueCat
    App/                       # RootView routing, AppConfig
    Theme/                     # colors + the persistent DisclaimerBanner (§2.5)
    Components/                # StatusChip, etc.
    Models/                    # Codable mirrors of Firestore shapes (status is read-only, §2.2)
    Services/                  # Firebase bootstrap, SessionStore (auth), ReportService, listeners
    Features/
      Onboarding/              # Auth (email + Sign in with Apple), Consent (§2.5), Intake (§3.1)
      Upload/                  # VisionKit scanner, Photos/PDF import, value confirmation (§3.2)
      Results/                 # dashboard + marker detail + pinned critical banner (§2.3, §3.3)
      Plan/                    # gated supplement + food plan (§2.4, §3.4)
      Trends/                  # Swift Charts over time (§3.5)
      Doctors/                 # disclosed sponsored directory (§3.6, §10.3)
      Paywall/                 # RevenueCat freemium (§3.7, §10.1)
    Assets.xcassets/
```

## What you must add before a build succeeds

1. **`GoogleService-Info.plist`** — download from your Firebase project and place at `ios/Supplement/GoogleService-Info.plist` (gitignored). On Codemagic, provide it as the base64 env var `GOOGLE_SERVICE_INFO_PLIST` (the CI decodes it).
2. **App icon** — `Assets.xcassets/AppIcon.appiconset` ships with an empty 1024px slot so it compiles; add a real PNG before submitting to TestFlight.
3. **RevenueCat key** — set `AppConfig.revenueCatAPIKey` to your public SDK key.
4. **Signing** — configure an App Store Connect API key + bundle id `com.supplement.app` in Codemagic.

## Build locally (only on a Mac)

```bash
brew install xcodegen
cd ios && xcodegen generate
open Supplement.xcodeproj
```

On Windows there is no iOS Simulator — push to Git and let Codemagic build → TestFlight.

## Follow-ups (intentionally left as TODOs)

- **Google Sign-In** (§3.1): add the `GoogleSignIn` SPM package + URL scheme. Email + Apple are implemented.
- **Affiliate deep links** (§10.2): the plan's "shop" CTA is disabled pending a confirmed Fullscript/affiliate partner.
- **Cascade delete** (§9): account deletion should trigger a Cloud Function to purge Storage files + subcollections; the app currently deletes the user doc + auth record.
