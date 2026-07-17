# Accessibility and Localization Readiness

Milestone 17 adds a first pass at accessibility and future localization structure.

## Accessibility improvements

- Shared rating controls now expose selected values to VoiceOver.
- Major icon-only actions have explicit labels and, where useful, hints:
  - refresh health data
  - open profile
  - ritual complete/incomplete
  - expand/collapse exercise and ritual details
  - delete logged set/custom workout/progress photo
  - schedule test reminder
  - save nutrition/body metrics
- Reduce Motion is respected for the most common micro-interactions:
  - tab transitions
  - Check In rating selection
  - ritual completion/expansion
  - exercise card expansion
  - set delete/save feedback

## Localization readiness

- `AppStrings` centralizes repeated action/accessibility strings using `String(localized:)`.
- English remains the only language for now.
- Brian-specific personalization remains intentional and should not be stripped during future localization.

## Remaining manual QA

- VoiceOver pass on a real iPhone
- Dynamic Type pass on a small iPhone
- Contrast checks in bright outdoor conditions
- Keyboard/focus pass for long forms
