# Oura OAuth Readiness

Health Command Center does not connect to Oura's real API yet. Manual/mock Oura mode remains the active test path.

## Added Interfaces

- `OuraOAuthCoordinating`
- `OuraAPIProviding`
- `OuraTokenStoring`
- `OuraCredentialState`
- `OuraSyncResult`
- `OuraAPIReadinessPayload`
- `KeychainOuraTokenStore`

These are foundations only. No real credentials are included.

## Manual Requirements Before Real OAuth

- Create an Oura developer application.
- Configure an approved redirect URI.
- Decide where client configuration lives without committing secrets.
- Add OAuth callback handling in the iOS app.
- Store tokens only through Keychain-backed storage.
- Add privacy disclosures for any real Oura data access.
- Preserve Apple Health as the primary source for overlapping metrics unless Brian explicitly selects Oura.

## Source Priority

Automatic recovery mode should continue to use:

1. Apple Health for overlapping metrics such as sleep duration, resting HR, HRV, steps, active energy, workouts, and body weight.
2. Oura as supplemental context for readiness score, sleep score, body temperature trend, and Oura-specific notes.
3. Manual Check In as a fallback and subjective safety override.

Oura may make coaching more conservative when it shows risk. It should not make the app more aggressive when Apple Health or Brian's subjective Check In suggests caution.
