# Health Command Center

First vertical-slice MVP for Brian's Health Command Center, built as a dark-mode iPhone SwiftUI app.

## What is included

- Personalized onboarding/setup for Brian's baseline and preferences
- Daily Check In flow with energy, soreness, stress, mood, available workout time, and optional pain/problem note
- Calm first-run HealthKit prompt flow: Apple Health is optional and user-initiated
- HealthKit service requesting and reading:
  - Sleep duration
  - Steps
  - Workouts
  - Exercise time, stand time, flights climbed, and walking/running distance
  - Resting heart rate
  - HRV
  - Heart rate, respiratory rate, blood oxygen, and body temperature when available
  - Active energy
  - Weight
  - Body fat percentage, lean body mass, and waist circumference when available
  - Apple Health nutrition summaries when another app writes samples there
- Oura foundation with manual/mock snapshots for supplemental recovery context; OAuth is not connected yet
- Local on-device JSON storage for app data and `UserDefaults` for preferences
- Readiness classifier for:
  - Push Day
  - Normal Training Day
  - Light Training Day
  - Recovery Day
  - Bare-Minimum Day
- Result screen with Today's Mission
- Hidden-by-default "Why this category?" explanation on the result screen
- Home Today Mission dashboard plus readiness-aware Workouts
- Train includes a Starter Program, Workout Library, and Custom Workouts
- Starter Program includes Full Body A, B, and C with full, short, bare-minimum, and recovery versions
- Workout Library includes local built-in sessions for full-body strength, bands/bodyweight, dumbbells, work-shift quick sessions, recovery/mobility, conditioning, and bare-minimum days
- Local on-device exercise logs with last-time recall for repeated exercises
- Custom workout templates are stored locally for changed workout days and can be edited or deleted without removing existing logs
- Ritual tab with daily readiness-aware routines and local completion logs
- Progress tab with charts, workout sessions, ritual history, streaks, recovery, nutrition, exercise progress, and body metrics
- Weekly Coach Report in Insights with local rule-based wins, watchouts, next-week focus, and Daily Win review
- Profile settings, storage/debug disclosure, reset controls, reminders, Oura foundation, body metrics, and MVP info

## Design / Polish Notes

- Premium redesign milestone 1 refreshed the shared design system, Today, Check In, and Readiness Result surfaces.
- Premium redesign milestone 2 extends the same graphite/dark system, restrained readiness accents, clearer card hierarchy, and calmer coaching language across Train, Recovery, Insights, You, custom workout forms, and dense settings/debug sections.
- Premium redesign milestone 3 adds subtle micro-interactions, inline action feedback, improved empty/loading/error states, and real-use polish for saves, refreshes, reminders, ritual toggles, and workout logging.
- Visual identity foundation adds an original graphite AppIcon with a restrained readiness glow, command-center ring, and health signal mark. The same mark appears in onboarding/About and can be replaced later with final brand artwork.
- Real-device QA should be repeated after design changes, especially HealthKit refresh, local reminder testing, keyboard dismissal, and persistence after relaunch.

## Train / Workout Library Notes

- Train shows today's recommended workout first, using readiness, program phase, and workout timing to choose a conservative local option.
- Starter Program remains the backbone: Full Body A, Full Body B, and Full Body C.
- Workout Library adds deterministic, local-only options for short work-shift sessions, bands/bodyweight, dumbbell strength, recovery mobility, bike/stairs conditioning, and bare-minimum movement.
- Exercise Library adds a full premium browser from Train with search, result counts, category/filter chips, a filter sheet, favorites, recently used filters, and detail sheets with setup, execution steps, cues, caution guidance, substitutions, and source/license disclosure.
- Custom workouts can add exercises directly from the full Exercise Library or use manual entries. Editing a custom template does not rewrite historical workout logs.
- Exercise Library now bundles a normalized offline import from `yuhonas/free-exercise-db` plus HCC-curated band and mobility extensions. Attribution and license details are documented in `Docs/EXERCISE_LIBRARY_IMPORT.md`.
- Imported exercise metadata is searchable and browseable, but automatic workout generation uses a conservative HCC-curated/allowlisted subset so obscure imported records do not become prescribed sessions by accident.
- Recovery includes access to the Exercise Library filtered toward mobility/stretch/recovery movements. Brian can add movements to today's recovery routine and save the selected IDs as a simple local recovery flow.
- Dynamic Workout Generator creates a local, rule-based workout option from readiness, recovery, sleep/stress/soreness context, available time, program phase, location, equipment, recent logs, and the DailyPlan. Generated workouts are selectable in Train and can be copied into Custom Workouts before logging.
- Adaptive Program Scheduler shows a local weekly structure with three full-body strength sessions and optional recovery/conditioning days. Readiness and recovery can downgrade today's session, and manual reschedules are stored locally without marking skipped days as failure.
- Goals & Targets add editable local guardrails for recomposition, strength, workout frequency, protein, hydration, sleep, meditation, mobility, and consistency. These targets shape Today, DailyPlan nutrition guidance, Insights, and Weekly Coach Report copy without aggressive weight-loss prescriptions.
- Progress Photos are optional and local-only. The app copies selected front/side/back photos into its sandbox for simple recent comparison; photos are not uploaded and can be deleted from Insights.
- Local exports are user-initiated from You/Profile. The app can create a JSON backup, workout CSV, nutrition CSV, body metrics CSV, and a plain-text weekly coach report in a temporary local export folder for sharing through iOS.
- Smart Reminders remain local and optional. Check-in, workout, recovery, nutrition, sleep, ritual, and weekly review reminders can be controlled separately; phase and workout timing adjust reminder copy/times conservatively.
- Shortcuts foundation adds App Intents for opening Today, starting Check In, opening Train, logging Daily Win, and opening Health refresh. A widget target is deferred because adding an extension target safely requires Xcode-managed signing/App Group review on Brian's machine.
- Apple Watch foundation is documented in `Docs/APPLE_WATCH_FOUNDATION.md`. The watch target is deferred until it can be added through Xcode with Brian's signing context active.
- Cloud-ready architecture is documented in `Docs/CLOUD_READY_ARCHITECTURE.md`. Repository protocols now wrap the current local JSON/UserDefaults storage without enabling sync, accounts, or cloud upload.
- Coach engine architecture is documented in `Docs/COACH_ENGINE.md`. The current engine is deterministic and local-only, unifying Today, recovery, nutrition, workout, and weekly review wording behind conservative safety rules.
- Release quality testing is documented in `Docs/RELEASE_QUALITY_TESTING.md`. A hosted XCTest target covers key deterministic rules and backward-compatible decoding without touching Brian's real device data.
- Accessibility and localization readiness is documented in `Docs/ACCESSIBILITY_LOCALIZATION_READINESS.md`. The app now has Reduce Motion guards for common micro-interactions, clearer icon-button labels, and a lightweight `AppStrings` namespace for repeated user-facing strings.
- Built-in library workouts use the same local ExerciseLog flow as starter workouts, so Progress session detail and exercise summaries continue to work.
- Custom Workouts are local templates in `custom_workouts.json`; editing a template does not rewrite past workout logs.
- Favorites, recently viewed exercises, recently used exercises, and saved recovery flow exercise IDs are local UserDefaults preferences and are cleared by Delete All Local App Data.
- Imported exercise metadata is bundled locally in `ImportedExerciseLibrary.json`; the app does not need the internet for exercise search. Images from the source dataset are deferred pending a separate image-license/app-size audit and are not bundled in this pass.

## Weekly Review Notes

- Insights includes a local, rule-based Weekly Coach Report.
- The report uses stored check-ins, workout logs, ritual logs, nutrition anchors, sleep from check-ins, body metrics, and Daily Win answers.
- It is not AI yet and does not call external APIs; recommendations are deterministic coaching rules for next-week focus.

## Run

Open `HealthCommandCenter.xcodeproj` in Xcode, select an iPhone simulator or device, and run the `HealthCommandCenter` scheme.

HealthKit readings are best tested on a real iPhone with Health data available. The app still supports completing a check-in when HealthKit is unavailable.

## Run on Real iPhone

1. Install full Xcode from the Mac App Store or Apple Developer downloads, then open it once so it can finish installing components.
2. In Terminal, check the selected developer directory:

   ```sh
   xcode-select -p
   ```

3. If it prints `/Library/Developer/CommandLineTools`, switch to full Xcode:

   ```sh
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

4. Open `HealthCommandCenter.xcodeproj` in Xcode.
5. Select the `HealthCommandCenter` scheme in the toolbar.
6. Connect and unlock a real iPhone, then select that iPhone as the run destination.
7. In the `HealthCommandCenter` target settings, open `Signing & Capabilities`.
8. Choose your Apple Developer Team. Xcode should keep automatic signing enabled.
9. Confirm the bundle identifier is unique for your account. The default is `com.brian.healthcommandcenter`; change it if Xcode reports that it is unavailable.
10. Confirm HealthKit appears under `Signing & Capabilities`.
11. Press Run.
12. On the iPhone, approve any developer trust prompt if iOS asks for it.
13. Launch the app. On a fresh install, complete the greeting/setup flow and confirm the app lands on Home.
14. Tap `Start Check In` from Home.
15. Tap `Connect Apple Health` from the Check In screen.
16. Approve the requested Health permissions.
17. Complete the daily Check In flow and confirm a readiness category appears.

## Real Device Test Checklist

- App launches.
- Greeting/setup appears on a fresh install, full data reset, or after `Reset opening screen only`.
- Setup completion routes to Home.
- Home shows `Start Check In` when no check-in exists today.
- Check In starts from Home.
- HealthKit connection is user-initiated.
- Permissions appear.
- Denied permissions do not crash app.
- Missing metrics show empty states.
- Check-in completes.
- Readiness category appears without numeric score.
- `Why this category?` is hidden by default and expands.
- Home dashboard reflects latest check-in.
- Local storage persists after app relaunch.
- Debug section shows raw inputs/logs.

## Real iPhone QA Checklist

- Enable Developer Mode on the iPhone if iOS requires it.
- Trust the developer certificate if the first real-device launch asks for trust.
- Launch Health Command Center and complete the greeting if this is a fresh install.
- From Home, confirm `Start Check In` appears when no check-in exists today.
- Start Check In, tap `Connect Apple Health`, and approve or deny HealthKit permissions deliberately.
- Use Home or Profile -> `Refresh Health Data` and confirm the HealthKit status, last refresh time, and returned metric values update calmly.
- Confirm Home's Health context matches Profile's Real iPhone HealthKit status.
- Log one workout set in Workouts and confirm it appears in today's sets and Progress.
- Toggle one Ritual item and confirm the completion count updates.
- Save Nutrition anchors in Ritual and confirm Profile/Data counts reflect the local log.
- In Profile -> Reminders, enable reminders if desired and use `Schedule Test Reminder in 10 Seconds`.
- Close and reopen the app, then confirm check-ins, workout logs, ritual logs, nutrition logs, reminder settings, and Profile preferences persist.
- Known setup issues: Xcode may require Developer Mode, certificate trust, a selected signing team, or a unique bundle identifier before real-device launch succeeds.

## Real-device HealthKit Troubleshooting

- Sleep uses the Apple Health latest sleep summary when available, not a raw multi-hour total.
- A wider HealthKit lookup may be used internally only to find overnight sleep and nap samples; readiness uses the latest sleep-day summary.
- Oura integration will eventually use Oura's own latest sleep/readiness values directly.
- Weekly recovery averages currently depend on stored check-ins unless historical sleep summaries are added later.
- Steps and active energy can be zero or empty shortly after midnight; Profile shows whether the query returned a value, zero, no sample, or an error.
- Workouts only appear if Apple Health has workout samples; Profile checks a recent workout window for debugging.
- Resting heart rate, HRV, and body weight use the most recent readable sample.
- Verify permissions in the Health app and iOS Settings if a metric consistently shows unavailable, denied, or query error.

## Notification Test Troubleshooting

- Allow notifications when iOS asks, or enable them later in Settings -> Notifications -> Health Command Center.
- Use Profile -> Reminders -> `Schedule Test Reminder in 10 Seconds`, then watch the pending test reminder status.
- If no alert appears, lock the phone or leave the app and test again; foreground banners, Focus mode, Silent mode, and notification summary settings can affect presentation.
- Profile shows permission status, pending HCC notification count, and whether the test reminder is currently pending.

## MVP QA Checklist

- First launch:
  - App opens into the greeting/setup flow on a fresh install or after deleting all local app data.
  - Brian can confirm defaults quickly: name, goal, height, starting weight, program phase, training location, workout time, equipment, nutrition anchors, and recovery source.
  - Setup routes cleanly into Home.
  - Home shows `Start Check In` when no check-in exists today.
  - Check In starts from the Home mission button.
- Normal relaunch:
  - App opens to Home after the greeting has been completed.
  - Home owns the no-check-in state and does not force Check In on launch.
  - Use Profile -> Reset Controls -> `Reset opening screen only` to test greeting/setup again without deleting check-ins, workout logs, ritual logs, or settings.
  - Reset opening screen only should show current saved settings as setup defaults.
- Check In:
  - `Connect Apple Health` is user-initiated.
  - Check In can be completed with no HealthKit data.
  - Denied or unavailable HealthKit permissions show calm unavailable/empty states and do not block classification.
  - Readiness result shows a category only, not a numeric score.
  - `Why this category?` is hidden by default and expands.
- Home mission:
  - Today's Mission leads with the recommended action.
  - If no check-in exists today, the next action starts Check In.
  - Training days route to Workouts; Recovery and Bare-Minimum days route to Ritual.
  - Missing HealthKit data reads as optional context, not an error.
- Workouts:
  - Before Check In, Workouts shows a `Classify today before training` prompt and does not imply a full workout is unlocked.
  - Recommendation changes with readiness category.
  - Exercise cards show written cues and a clear logging action.
  - Log multiple sets for the same exercise and confirm Today's sets update immediately.
  - Delete a mistaken logged set and confirm the session summary updates.
  - Last-time data stays separate from today's logs.
  - Add a custom workout, log one custom exercise, and confirm Progress shows the custom workout name.
- Ritual:
  - Toggle ritual items and confirm the progress count updates.
  - Enter a Daily Win answer and confirm it counts as completion and appears in Progress detail.
  - Relaunch the app and confirm today's ritual completions persist.
  - Reset today's ritual from Profile and confirm today's checkmarks and Daily Win clear.
- Progress:
  - Empty history sections explain what Brian should do next.
  - Weekly overview reflects check-ins, workout logs, ritual completions, and consistency.
  - Recent workout, ritual, and readiness rows populate after using those flows.
- Profile:
  - Program Phase, Training Location, Workout Time, nutrition anchors, and baseline personalization persist after relaunch.
  - Storage/debug disclosures open cleanly.
  - `Reset opening screen only` requires confirmation and resets only the greeting/onboarding flag.
  - Destructive reset controls require confirmation before deleting data.
- Simulator notes:
  - CoreSimulator, HealthKit, and haptic warning noise can appear in simulator logs and can be ignored when the app builds/runs.
  - Real HealthKit permission behavior should be verified later on a real iPhone with Health data available.

## Known Simulator Issues

- Xcode or `xcodebuild` may print CoreSimulator, `FBSOpenApplication`, or "Busy" warnings while simulator services restart or lag.
- These warnings are usually safe to ignore when the app builds successfully and opens in Simulator.
- If Simulator refuses to launch the app, quit Simulator, reopen it from Xcode, and run again. This is simulator state noise, not HealthCommandCenter app state.

## MVP Release Candidate QA Checklist

- Onboarding/setup:
  - Fresh install or Delete All Local App Data opens greeting/setup.
  - Setup defaults are Brian-specific and can be accepted quickly with `Start Command Center`.
  - Reset opening screen only reopens setup with current saved settings and does not delete logs.
  - Normal relaunch opens Home.
- Home:
  - No-check-in state shows `Start Check In`.
  - Today Mission, Workouts, Ritual, Nutrition, Sleep & Recovery, and Body Metrics copy agree with the same DailyPlan/context.
  - HealthKit missing or partial data reads as optional context.
- Check In:
  - Completion updates Home, Workouts, Ritual, Progress, DailyPlan, and Recovery.
  - Missing Apple Health/Oura data does not block readiness.
  - Subjective low energy, high stress/soreness, or pain notes keep guidance conservative.
- Workouts:
  - Before Check In, Workouts asks Brian to classify the day before training.
  - Logging multiple sets updates Today's rows, session summary, Home, and Progress.
  - Coach suggestions and progress summaries remain read-only during rendering.
  - Custom workouts can be created, selected, logged, and deleted without deleting old workout logs.
- Ritual:
  - Toggles persist and reset-today only clears today's ritual.
  - Nutrition target flags use onboarding/Profile protein and water targets.
  - Sleep Prep responds to Program Phase.
- Progress:
  - Charts and histories handle no data and partial data with helpful empty states.
  - Workout session detail, ritual day detail, Oura test snapshots, nutrition, recovery, exercise progress, and body metrics sections render without fake readiness.
- Profile:
  - Personalization, phase, training preferences, reminders, Oura settings, and storage/debug counts reflect current state.
  - Test reminder, HealthKit refresh, body metrics save, reset opening, reset ritual, delete workout logs, and delete all local data all require the expected user action/confirmation.
- Storage:
  - Local JSON files and UserDefaults keys match the Local Storage Reference below.
  - Delete All Local App Data clears local app files/preferences and returns to setup; it does not delete Apple Health data.
- Render-time safety:
  - SwiftUI body helpers are read-only; mutations happen from app startup, lifecycle hooks, buttons, toggles, sheets, or explicit save/reset actions.

## Known Limitations

- Oura OAuth is not connected yet; Oura support is manual/mock only and no real tokens are stored.
- Cronometer API is not connected; HealthCommandCenter reads Apple Health nutrition summaries when available and stores only manual daily nutrition anchors locally.
- Apple Health exact per-type authorization status is best-effort; Profile diagnostics show readable values, query windows, no-sample states, and errors where available.
- Local storage only; there is no account login, cloud sync, export, or backup inside the app.
- Smart-scale body composition values are trend data, not exact medical measurements.
- The app is coaching and personal organization software, not medical advice, diagnosis, treatment, or clinical decision support.

## Workouts Tab Test Checklist

- Open the `Workouts` tab after completing or skipping a Check In.
- Confirm the top recommendation changes from the latest readiness category:
  - Push Day: Full Version with "push intelligently" language
  - Normal Training Day: Full Version
  - Light Training Day: Short Version
  - Recovery Day: Recovery and mobility
  - Bare-Minimum Day: Bare-Minimum Version
- Select `Full Body A`, `Full Body B`, and `Full Body C` from the weekly structure.
- Expand exercise cards and confirm form cues, common mistakes, muscles, and feel notes appear.
- Tap `Log Exercise` on a strength exercise.
- Enter weight, reps, sets completed, effort, and optional notes.
- Save the log.
- Reopen the same exercise and confirm `Last time` appears.
- Add a custom workout, add at least one exercise, save it, select it, and log a set.
- Delete the custom workout template and confirm old logged sets remain in Progress history.
- Relaunch the app and confirm the last-time log persists.

## Workout Log Storage

Workout logs are stored locally in the app sandbox as `workout_logs.json`. In the simulator, this file lives inside the simulator app container, not in the project folder. Future versions should add in-app history, export, and cloud sync once the workout logging loop is stable.

## Smart Workout Progression

Workouts exercise cards show local, rule-based Coach Suggestions from recent logs, today's logged sets, readiness, and the DailyPlan recommendation. Suggestions are conservative by design: repeat clean work, add reps before load, back off after high-effort sets, and avoid pushing strength on Recovery or Bare-Minimum days. This is coaching guidance for training consistency, not medical advice.

## Exercise Progress Summaries

Exercise records are local "best so far" summaries calculated from `workout_logs.json`: heaviest weight used, most reps in one set, best daily set volume, recent best, and total times logged. They are not medical guidance, performance testing, or true max-strength claims; they are lightweight references to help Brian see consistency and gradual improvement.

## Ritual Tab Test Checklist

- Open the `Ritual` tab after completing or skipping Check In.
- Confirm the summary shows the current readiness category.
- Toggle a few ritual cards and confirm the completed count/progress updates.
- Expand mobility and meditation cards and confirm the text options appear.
- Switch readiness categories by doing a new Check In and confirm the ritual emphasis changes.
- Relaunch the app on the same calendar day and confirm today's completed items persist.
- Test on a new calendar day and confirm a fresh ritual appears while previous days remain stored.

## Ritual Log Storage

Ritual completions are stored locally in the app sandbox as `daily_ritual_logs.json`, keyed by calendar day. The ritual resets automatically when the date changes; previous days are kept in the local JSON file. In the simulator, this file lives inside the simulator app container, not the project folder.

## Nutrition Tracking

Nutrition tracking is manual plus Apple Health read-only summaries. Cronometer remains the source of detailed food logging; if Cronometer or another app writes nutrition samples to Apple Health, HealthCommandCenter can surface those daily totals. HCC stores only manual daily summary values locally: calories, protein, water, fiber, Cronometer completion, target flags, and notes.

### Cronometer via Apple Health

Health Command Center does not use or scrape a Cronometer API. Automatic Cronometer nutrition works only when Cronometer writes supported nutrition samples into Apple Health and Brian grants HCC read permission for those Health fields.

Setup path on iPhone:

1. Open Cronometer.
2. Go to `More -> Connect Apps & Devices -> Apple Health`.
3. Enable available nutrition write permissions in Apple Health.
4. Open HCC -> You -> HealthKit -> Refresh Health Data.
5. Check `Nutrition Source Diagnostics` in You/Profile.

When HealthKit source metadata identifies Cronometer, HCC labels the source as `Cronometer via Apple Health`. If source metadata is unavailable or mixed, HCC labels it `Apple Health nutrition`. If no samples exist, HCC shows `No Apple Health nutrition samples found` and manual nutrition remains the fallback. HCC does not double count manual HCC entries with Apple Health totals; one daily nutrition source is chosen for coaching/display.

## Body Metrics MVP

Apple Health body weight may be shown when available, but it is used as read-only context unless Brian explicitly saves a local entry. Manual and smart-scale body metrics are stored locally in `body_metrics_entries.json`. Body fat, muscle mass, visceral fat, and waist values are treated as trend data for body recomposition, not exact medical measurements.

## Custom Workouts

Custom workout templates are stored locally in `custom_workouts.json`. They are meant for first-test flexibility when Brian changes the planned workout but still wants the session logged in the same Workouts and Progress flow. Deleting a custom workout removes the template only; existing workout logs remain in `workout_logs.json`.

## Daily Win

Daily Win is an answerable Ritual prompt. A saved answer counts the item complete and appears in Ritual history/detail. Older ritual logs without a Daily Win answer still decode safely.

## Meal Templates

Meal templates are flexible examples for body recomposition, not a rigid meal plan. They use the formula protein + carb + fruit/vegetable + healthy fat, avoid seafood and mushrooms, and are meant to make Cronometer logging and shift-friendly meals easier.

## Sleep and Recovery Guidance

Sleep and recovery guidance is rule-based and uses Apple Health latest sleep when available, with Oura structured for a future latest-sleep/readiness source. Wider HealthKit lookup windows are only used to find relevant sleep samples, not as the user-facing sleep total. Weekly recovery history currently depends on stored check-ins unless historical sleep summaries are added later.

## Oura Foundation

Oura OAuth is not connected yet, and the app does not call Oura's real API or store real Oura tokens. Apple Health is the default trusted source for overlapping metrics such as sleep duration, resting heart rate, HRV, steps, active energy, workouts, and body weight. Oura supplements Apple Health with recovery context Apple Health does not provide directly, such as readiness score, sleep score, body temperature trend, and notes.

Automatic recovery mode uses Apple Health primary plus Oura supplemental context when both exist. Oura can make guidance more conservative when readiness, sleep score, or temperature trend suggests risk, but it should not make the app more aggressive when Apple Health or Brian's check-in suggests caution. Explicit Oura mode can still be selected in Profile for testing manual/mock Oura snapshots. Future Oura integration should use the secure interfaces documented in `Docs/OURA_OAUTH_READINESS.md`; no client ID, secret, redirect URI, access token, or network call is active yet.

## Progress Charts

Progress charts are local-only weekly views built from Check In, Ritual, workout, nutrition, and sleep data already stored on device. They are lightweight visibility tools, not analytics, predictions, or performance scoring.

## Local Notifications MVP

Reminders are optional and local-only. Health Command Center does not request notification permission on first launch and does not schedule reminders unless Brian enables them in Profile. Scheduled reminders use stable local identifiers for Check In, Ritual, Sleep Prep, and Nutrition/Cronometer prompts.

Notification permission is requested through `UserNotifications` when reminders are enabled or a test reminder is scheduled. iOS does not require an Info.plist usage string for local notification permission, but the app explains reminders in Profile before requesting access.

## Long-Term App Replacement Direction

Health Command Center is moving toward being Brian's daily dashboard and coaching layer over the apps he already uses. Apple Health is the automatic data layer; Cronometer remains the detailed food log for now; Oura is supplemental recovery context until real OAuth is added; Workouts owns training, logging, and custom workout templates. Future versions can deepen integrations, automate imports, expand the custom workout library, and make guidance smarter without adding cloud sync or accounts before they are needed.

## Local Development Notes

This project is now tracked with local git history. Make a commit before major feature changes so the MVP can be rolled back to a known working checkpoint. Known simulator warning notes below still apply when builds succeed and the app opens.

Repo-local git identity is configured for Brian Cady.

## Release Candidate Audit

- Current release-candidate version is `0.2` build `2`.
- Active Xcode targets are the iPhone app and `HealthCommandCenterTests`.
- Widget and Apple Watch foundations are documented, but the actual targets remain intentionally deferred until Xcode-managed signing/App Group setup can be done on Brian's machine.
- Apple Health remains read-only. The app requests no Apple Health write permissions and does not delete or modify Apple Health data.
- Oura real OAuth is not active. Secure token storage and integration protocols exist, but no client ID, secret, redirect URI, access token, or network call is committed.
- Cronometer direct integration is not active. Nutrition is manual in HCC or automatic only when another app writes nutrition samples to Apple Health.
- Exports and progress photos are user-initiated and local. `.gitignore` excludes generated local debug/export artifacts; do not commit personal exports or photo files.
- Guidance is personal coaching organization, not medical advice, diagnosis, treatment, or clinical decision support.

## Project Configuration

- App target: `HealthCommandCenter`
- Test target: `HealthCommandCenterTests`
- Shared scheme: `HealthCommandCenter`
- Bundle identifier: `com.brian.healthcommandcenter`
- Display name: `Health Command Center`
- Version: `0.2`
- Build: `2`
- Signing: automatic, currently configured with development team `43V4UB543R`; update the team locally in Xcode if App Store Connect requires a different account
- Platform: iPhone only, iOS 17.0+
- HealthKit entitlement: `com.apple.developer.healthkit`
- Health privacy string: `NSHealthShareUsageDescription`
- Health update privacy string: not included because the app currently reads Health data only and does not write Health samples
- Notification privacy string: not required by iOS for local notification permission; reminder copy lives in Profile
- Launch screen: generated by Xcode with forced dark appearance for launch/app consistency
- App icon: `AppIcon` asset catalog is included with original generated graphite/readiness artwork; replace with final brand art before broad public release if desired
- HealthKit read types requested:
  - Sleep analysis
  - Step count
  - Workouts
  - Exercise time
  - Stand time
  - Flights climbed
  - Walking/running distance
  - Resting heart rate
  - Heart rate variability SDNN
  - Heart rate
  - Respiratory rate
  - Blood oxygen
  - Body temperature
  - Active energy burned
  - Body mass
  - Body fat percentage
  - Lean body mass
  - Waist circumference
  - Dietary energy, protein, carbohydrates, fat, fiber, sugar, sodium, water, and caffeine
  - Calcium, iron, magnesium, potassium, zinc, vitamin D, and cholesterol when available

## TestFlight Readiness Checklist

- Apple Developer Program membership is required for App Store Connect and TestFlight distribution.
- Confirm the bundle identifier is available for the Apple Developer account: `com.brian.healthcommandcenter`.
- Confirm the signing team in Xcode under `Signing & Capabilities`.
- Confirm `Version` and `Build` are set before each archive. Current MVP values are `0.2` and `2`.
- Confirm HealthKit appears under `Signing & Capabilities`.
- Confirm Apple Health permission wording explains read-only sleep, activity, workout, heart, body, and nutrition access.
- Confirm notification reminders are described as optional local reminders.
- Confirm the included `AppIcon` asset catalog has no missing-slot warnings. Final brand artwork can replace the generated icon before broad public release.
- In Xcode, choose `Product -> Archive` with a real signing team selected.
- Upload the archive to App Store Connect from Xcode Organizer.
- Add beta app information, contact details, and testing notes in App Store Connect.
- Add health data privacy wording to beta review notes, including that the app reads Apple Health and does not write Health samples.
- Start with internal testing first.
- Use external testing later after real-device HealthKit, reminders, onboarding, persistence, and reset flows are checked.
- Known limitations before public release: Oura OAuth is not connected, Cronometer is manual/Apple Health only, storage is local-only, there is no account/cloud sync, and guidance is not medical advice.

## App Privacy Draft Notes

- Health and fitness data: Apple Health data is read-only and used for readiness, recovery, activity, nutrition, and body metrics context.
- User-entered data: check-ins, workout logs, custom workouts, ritual completions, nutrition anchors, body metrics, Daily Win answers, Oura manual/mock snapshots, and preferences are stored locally on device.
- Notifications: optional local reminders can be scheduled for Check In, Recovery/Ritual, Sleep Prep, and Nutrition/Cronometer.
- Local storage: current MVP data is stored in local JSON files and UserDefaults in the app sandbox.
- Oura/Cronometer: Oura OAuth and Cronometer API are not connected yet; no real Oura tokens are stored.
- Nutrition provider architecture is documented in `Docs/NUTRITION_INTEGRATION_ARCHITECTURE.md`. Manual HCC entries can override today's display, Apple Health nutrition is automatic when samples exist, and external provider access remains a placeholder until supported vendor access exists.
- Cloud/backend: no account login, backend, cloud sync, or server upload exists in this MVP.
- Medical posture: the app provides personal coaching organization and is not medical advice, diagnosis, treatment, or clinical decision support.

## Local Storage Reference

- JSON files in the app sandbox:
  - `checkins.json`: Daily Check In and readiness history.
  - `workout_logs.json`: Strength set logs.
  - `daily_ritual_logs.json`: Ritual completions by calendar day.
  - `daily_nutrition_logs.json`: Manual nutrition summaries by calendar day.
  - `oura_manual_snapshots.json`: Manual/mock Oura recovery test snapshots.
  - `body_metrics_entries.json`: Manual body metrics and smart-scale trend entries.
  - `custom_workouts.json`: Brian-built custom workout templates.
  - `progress_photos.json`: Local progress photo metadata.
  - `ProgressPhotos/`: Local copied progress photo images.
- UserDefaults keys:
  - `hasSeenGreeting`: controls whether the opening/greeting screen appears on launch.
  - `userName`: Brian's display name.
  - `programPhase`: selected Program Phase.
  - `trainingLocation`: selected Training Location.
  - `workoutTimePreference`: selected Workout Time.
  - `personalizationSettings`: onboarding baseline, goal, equipment confirmation, avoidances, and nutrition anchors.
  - `favoriteExerciseIDs`: local Exercise Library favorites.
  - `recentlyViewedExerciseIDs`: local Exercise Library recently viewed IDs.
  - `recentlyUsedExerciseIDs`: local Exercise Library recently logged/used IDs.
  - `savedRecoveryFlowExerciseIDs`: local saved Recovery movement flow IDs.
  - `reminderSettings`: optional local reminder toggles and daily reminder times.
  - `ouraConnectionSettings`: Oura foundation mode and preferred recovery source.
  - `programScheduleOverrides`: local manual program reschedules.
  - `goalSettings`: editable goals and target guardrails.
- Profile -> Reset Controls -> `Reset opening screen only` clears only `hasSeenGreeting`; saved personalization and logs remain available as setup defaults.

## Validation

The project plist, scheme, and entitlements lint cleanly, the Swift sources parse cleanly, and the app sources type-check with a writable module cache. A simulator build also succeeds with:

```sh
xcodebuild -project HealthCommandCenter.xcodeproj -scheme HealthCommandCenter -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/HealthCommandCenterDerivedData build
```

The explicit `-derivedDataPath` keeps build output in a writable location for sandboxed/local automation.

The hosted XCTest target can be run with:

```sh
xcodebuild -project HealthCommandCenter.xcodeproj -scheme HealthCommandCenter -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/HealthCommandCenterDerivedData test
```

Current release-candidate automated suite: `ReleaseQualityTests`, 10 tests.

## Next integration point

Real Oura OAuth should replace `MockOuraService` in `HealthCommandCenter/Services/OuraService.swift` while preserving the `OuraService` protocol used by `AppViewModel`.
