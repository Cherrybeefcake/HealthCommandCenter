# Health Command Center

First vertical-slice MVP for Brian's Health Command Center, built as a dark-mode iPhone SwiftUI app.

## What is included

- Personalized greeting for Brian
- Daily Check In flow with energy, soreness, stress, mood, available workout time, and optional pain/problem note
- Calm first-run HealthKit prompt flow: Apple Health is optional and user-initiated
- HealthKit service requesting and reading:
  - Sleep duration
  - Steps
  - Workouts
  - Resting heart rate
  - HRV
  - Active energy
  - Weight
- Oura service protocol plus `MockOuraService` placeholder for future OAuth integration
- Local on-device JSON storage for check-ins and `UserDefaults` for preferences
- Readiness classifier for:
  - Push Day
  - Normal Training Day
  - Light Training Day
  - Recovery Day
  - Bare-Minimum Day
- Result screen with Today's Mission
- Hidden-by-default "Why this category?" explanation on the result screen
- Home dashboard plus a readiness-aware weekly Plan foundation
- Plan includes Full Body A, B, and C with full, short, bare-minimum, and recovery versions
- Local on-device exercise logs with last-time recall for repeated exercises
- Ritual tab with daily readiness-aware routines and local completion logs
- Progress tab with workout sessions, ritual history, streaks, and readiness history
- Profile settings, storage/debug disclosure, reset controls, and MVP info

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
13. Launch the app. On a fresh install, complete the greeting and confirm the app lands on Home.
14. Tap `Start Check In` from Home.
15. Tap `Connect Apple Health` from the Check In screen.
16. Approve the requested Health permissions.
17. Complete the daily Check In flow and confirm a readiness category appears.

## Real Device Test Checklist

- App launches.
- Greeting screen appears on a fresh install, full data reset, or after `Reset opening screen only`.
- Greeting completion routes to Home.
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

## MVP QA Checklist

- First launch:
  - App opens into the greeting on a fresh install or after deleting all local app data.
  - Greeting language feels personal to Brian and routes cleanly into Home.
  - Home shows `Start Check In` when no check-in exists today.
  - Check In starts from the Home mission button.
- Normal relaunch:
  - App opens to Home after the greeting has been completed.
  - Home owns the no-check-in state and does not force Check In on launch.
  - Use Profile -> Reset Controls -> `Reset opening screen only` to test the greeting again without deleting check-ins, workout logs, ritual logs, or settings.
- Check In:
  - `Connect Apple Health` is user-initiated.
  - Check In can be completed with no HealthKit data.
  - Denied or unavailable HealthKit permissions show calm unavailable/empty states and do not block classification.
  - Readiness result shows a category only, not a numeric score.
  - `Why this category?` is hidden by default and expands.
- Home mission:
  - Today's Mission leads with the recommended action.
  - If no check-in exists today, the next action starts Check In.
  - Training days route to Plan; Recovery and Bare-Minimum days route to Ritual.
  - Missing HealthKit data reads as optional context, not an error.
- Plan:
  - Before Check In, Plan shows a `Classify today before training` prompt and does not imply a full workout is unlocked.
  - Recommendation changes with readiness category.
  - Exercise cards show written cues and a clear logging action.
  - Log multiple sets for the same exercise and confirm Today's sets update immediately.
  - Delete a mistaken logged set and confirm the session summary updates.
  - Last-time data stays separate from today's logs.
- Ritual:
  - Toggle ritual items and confirm the progress count updates.
  - Relaunch the app and confirm today's ritual completions persist.
  - Reset today's ritual from Profile and confirm only today's ritual checkmarks clear.
- Progress:
  - Empty history sections explain what Brian should do next.
  - Weekly overview reflects check-ins, workout logs, ritual completions, and consistency.
  - Recent workout, ritual, and readiness rows populate after using those flows.
- Profile:
  - Program Phase, Training Location, and Workout Time persist after relaunch.
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

## Plan Tab Test Checklist

- Open the `Plan` tab after completing or skipping a Check In.
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
- Relaunch the app and confirm the last-time log persists.

## Workout Log Storage

Workout logs are stored locally in the app sandbox as `workout_logs.json`. In the simulator, this file lives inside the simulator app container, not in the project folder. Future versions should add in-app history, export, and cloud sync once the workout logging loop is stable.

## Smart Workout Progression

Plan exercise cards show local, rule-based Coach Suggestions from recent logs, today's logged sets, readiness, and the DailyPlan recommendation. Suggestions are conservative by design: repeat clean work, add reps before load, back off after high-effort sets, and avoid pushing strength on Recovery or Bare-Minimum days. This is coaching guidance for training consistency, not medical advice.

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

Nutrition tracking is manual for now. Cronometer remains the source of detailed food logging; HealthCommandCenter stores only daily summary values locally: calories, protein, water, fiber, Cronometer completion, target flags, and notes.

## Meal Templates

Meal templates are flexible examples for body recomposition, not a rigid meal plan. They use the formula protein + carb + fruit/vegetable + healthy fat, avoid seafood and mushrooms, and are meant to make Cronometer logging and shift-friendly meals easier.

## Sleep and Recovery Guidance

Sleep and recovery guidance is rule-based and uses available Check In and Apple Health sleep data when present. It is meant to help Brian adjust training, caffeine, wind-down, and naps around night shift, day shift, new-baby, or normal routine phases; it is not medical advice or diagnosis.

## Progress Charts

Progress charts are local-only weekly views built from Check In, Ritual, workout, nutrition, and sleep data already stored on device. They are lightweight visibility tools, not analytics, predictions, or performance scoring.

## Local Development Notes

This project is now tracked with local git history. Make a commit before major feature changes so the MVP can be rolled back to a known working checkpoint. Known simulator warning notes below still apply when builds succeed and the app opens.

## Project Configuration

- App target: `HealthCommandCenter`
- Shared scheme: `HealthCommandCenter`
- Bundle identifier: `com.brian.healthcommandcenter`
- Signing: automatic, with `DEVELOPMENT_TEAM` intentionally blank until selected locally in Xcode
- Platform: iPhone only, iOS 17.0+
- HealthKit entitlement: `com.apple.developer.healthkit`
- Health privacy string: `NSHealthShareUsageDescription`
- Health update privacy string: not included because the app currently reads Health data only and does not write Health samples
- HealthKit read types requested:
  - Sleep analysis
  - Step count
  - Workouts
  - Resting heart rate
  - Heart rate variability SDNN
  - Active energy burned
  - Body mass

## Local Storage Reference

- JSON files in the app sandbox:
  - `checkins.json`: Daily Check In and readiness history.
  - `workout_logs.json`: Strength set logs.
  - `daily_ritual_logs.json`: Ritual completions by calendar day.
  - `daily_nutrition_logs.json`: Manual nutrition summaries by calendar day.
- UserDefaults keys:
  - `hasSeenGreeting`: controls whether the opening/greeting screen appears on launch.
  - `userName`: Brian's display name.
  - `programPhase`: selected Program Phase.
  - `trainingLocation`: selected Training Location.
  - `workoutTimePreference`: selected Workout Time.
- Profile -> Reset Controls -> `Reset opening screen only` clears only `hasSeenGreeting`.

## Validation

The project plist, scheme, and entitlements lint cleanly, the Swift sources parse cleanly, and the app sources type-check with a writable module cache. A simulator build also succeeds with:

```sh
xcodebuild -project HealthCommandCenter.xcodeproj -scheme HealthCommandCenter -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/HealthCommandCenterDerivedData build
```

The explicit `-derivedDataPath` keeps build output in a writable location for sandboxed/local automation.

## Next integration point

Real Oura OAuth should replace `MockOuraService` in `HealthCommandCenter/Services/OuraService.swift` while preserving the `OuraService` protocol used by `AppViewModel`.
