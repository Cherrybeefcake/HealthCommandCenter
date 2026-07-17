# Coach Engine Foundation

Health Command Center now has a deterministic coach engine layer for current and future coaching surfaces.

## Current role

- `CoachContext` gathers the same local signals already used by Today, DailyPlan, Train, Recovery, Insights, goals, nutrition, body metrics, Apple Health, and Oura manual/mock context.
- `DeterministicCoachEngine` returns structured `CoachRecommendation` values for Today briefing, primary mission, watchout, next action, workout, recovery, nutrition, sleep, and weekly review wording.
- The engine is local-only and rule-based. It does not call external AI, cloud services, Oura APIs, or Cronometer APIs.

## Safety rules

- Subjective concerns from Check In remain a safety override.
- Pain/problem notes, very low sleep, low energy, high stress, high soreness, poor recovery, or risky Oura supplemental context can downgrade recommendations.
- Oura can add caution when available, but it does not make guidance more aggressive when Apple Health or Brian's Check In suggests caution.
- Apple Health remains the trusted primary source for overlapping metrics in automatic mode.

## Render-time safety

The coach engine is side-effect free. Helpers called from SwiftUI `body` must remain read-only:

- no appending or removing records
- no file saves
- no `@Published` assignment
- no permission prompts
- no implicit creation of missing logs

Future AI coaching can be introduced behind the same `CoachEngine` protocol, but the deterministic engine should stay as the safety baseline.
