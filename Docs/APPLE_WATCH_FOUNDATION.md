# Apple Watch Foundation

Health Command Center is ready for a future watchOS companion, but the watch target should be added through Xcode with Brian's Apple Developer signing context active.

## Intended Watch Scope

- Today’s Mission
- Readiness category / today’s call
- Start Check In shortcut or limited quick check-in
- Ritual progress
- Open recommended workout handoff to iPhone

## Safety Rules

- Do not duplicate the full iPhone app.
- Keep Apple Health read-only unless a future review explicitly adds workout-session writing.
- Do not add cloud sync or accounts as part of watch setup.
- Use shared model/repository protocols after the cloud-ready architecture milestone.

## Manual Xcode Setup Required

Adding a watchOS target changes signing, bundle identifiers, schemes, and deployment settings. That should be done in Xcode so automatic signing can create:

- Watch App target
- Watch Extension target if required by the selected template
- Bundle identifiers under `com.brian.healthcommandcenter`
- Any required shared app group or keychain access group, if future data sharing needs it

This milestone is intentionally documented instead of hand-editing the project file, because target setup is easy to destabilize without Xcode-managed signing.
