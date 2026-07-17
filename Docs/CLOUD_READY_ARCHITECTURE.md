# Cloud-Ready Architecture Without Cloud

Health Command Center remains local-first. This milestone only defines seams for future sync.

## Active Storage

`LocalStorageService` is still the active implementation. It stores JSON files in the app sandbox and preferences in `UserDefaults`.

## Repository Protocols

`HealthCommandCenter/Services/DataRepositories.swift` defines protocols for:

- Check-ins
- Workout logs
- Custom workouts
- Ritual logs
- Nutrition logs
- Body metrics
- Oura manual/mock snapshots
- Progress photo metadata and images
- Goal settings
- Profile preferences

Future iCloud, CloudKit, or backend storage should conform to these protocols while preserving the current local JSON decoding behavior.

## Sync Readiness Rules

- Keep stable IDs for records that already have them.
- Preserve calendar date keys for daily data.
- Preserve source metadata such as Apple Health, manual, smart scale, or mock Oura.
- Add schema/version metadata only when migration is actually needed.
- Keep decoding forgiving so older local JSON files remain readable.
- Never upload data without an explicit future sync feature and privacy review.

## Delete All Local Data

Delete All Local App Data still clears local JSON files, copied progress photos, and UserDefaults-backed settings. It does not delete Apple Health data or any source outside the app sandbox.
