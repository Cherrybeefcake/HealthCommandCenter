# Nutrition Integration Architecture

Health Command Center does not connect directly to Cronometer or any external food database.

## Active Sources

1. Manual HCC daily nutrition summary in Recovery.
2. Apple Health nutrition samples when another app writes them to Apple Health.
3. Placeholder external provider interfaces for future supported integrations.

## Source Priority

For today's display:

1. Manual HCC entry wins if Brian explicitly saved nutrition anchors today.
2. Apple Health nutrition is used automatically when readable samples exist.
3. External provider support is a placeholder only.
4. If no source exists, the app explains that Apple Health nutrition samples were not found.

## Provider Interfaces

`NutritionDataProvider` is the common interface. Current providers:

- `ManualNutritionProvider`
- `AppleHealthNutritionProvider`
- `PlaceholderExternalNutritionProvider`

`NutritionSourceResolver` centralizes source decisions and labels.

## Cronometer Boundary

Cronometer remains the detailed tracker for now. HCC can read nutrition automatically only if Cronometer or another app writes nutrition values into Apple Health and the user grants read permission.

No scraping, private automation, credential storage, or unsupported API access should be added.
