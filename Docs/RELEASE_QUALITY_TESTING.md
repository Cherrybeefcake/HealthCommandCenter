# Release Quality Tests

Milestone 16 adds a hosted iOS XCTest target: `HealthCommandCenterTests`.

## Current automated coverage

`ReleaseQualityTests` covers deterministic, local-only logic:

- readiness classification and conservative pain/low-recovery outcomes
- no-check-in DailyPlan behavior
- deterministic coach engine safety constraints
- dynamic workout downgrade behavior
- adaptive program scheduling basics
- nutrition source priority, with manual HCC entries overriding Apple Health display for today
- Daily Win completion behavior
- backward-compatible ritual decoding
- body metrics encode/decode round trip
- explicit sleep source labels

The tests avoid HealthKit, notifications, real app sandbox storage, photos, network calls, and user data.

## Manual audits still required

- Real-device HealthKit authorization and refresh
- Local notification permission and delivery behavior
- Real-device keyboard/focus behavior
- Full reset and persistence flows in the installed app
- Small-iPhone layout and VoiceOver checks
- TestFlight/archive validation in Xcode

## Safety notes

The app still keeps Apple Health read-only, stores data locally, and keeps render-time helpers side-effect free. Any future test fixtures should use in-memory values or temporary files, never Brian's real app container.
