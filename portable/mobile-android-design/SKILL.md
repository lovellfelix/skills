---
name: mobile-android-design
description: "Use when building, refactoring, or reviewing native Android UI with Jetpack Compose and Material 3: screen layout, components, theming, dark mode, adaptive/tablet layouts, navigation, or accessibility (TalkBack, touch targets, contrast)."
metadata:
  version: 0.2.0
  portable: true
  tags: [android, kotlin, compose, material3, ui, accessibility]
---

# Android UI (Jetpack Compose + Material 3)

Build intentional Compose screens on Material 3 tokens: clear hierarchy, explicit states, accessible by default.

**Project overrides win.** If the repo defines its own design tokens, read them before applying M3 defaults. For GrenadianBuzz (flat design, static palette), load `grenadianbuzz` → `reference/grenadianbuzz-android-design.md`.

Not for: non-Android UI, or Kotlin backend work with no UI impact. Java→Kotlin conversion: `java-to-kotlin-migration`.

## Workflow

1. Define semantic tokens first: `colorScheme`, typography scale, shape scale, spacing constants.
2. Structure the screen in sections (header / content / actions) with responsive constraints.
3. Build components with explicit default, pressed, focused, disabled, loading, empty, and error states.
4. Add motion only for entry, state transitions, and feedback.
5. Validate (below) before calling it done.

## Material 3 guardrails

- Semantic color roles (`primaryContainer`, `onSurfaceVariant`) via `MaterialTheme.colorScheme`, never hardcoded hex in composables. This is what makes dark mode work.
- Consistent typography roles across screens (`headlineSmall`, `titleMedium`, `bodyLarge`).
- One spacing scale (e.g. 4/8/12/16/24dp); no arbitrary per-component values.
- Never rely on color alone to convey state.

## Compose rules

- Hoist state; keep composables stateless where possible. `rememberSaveable` for state that must survive config changes.
- `LazyColumn`/`LazyVerticalGrid` with stable `key`s for any list that can grow; never `Column` + `verticalScroll` for long lists.
- Side effects: `LaunchedEffect` with correct keys, `DisposableEffect` for cleanup.
- Minimum 48dp touch targets; every actionable icon has a `contentDescription`, decorative ones use `null`.
- `WindowSizeClass` for breakpoints: Compact → bottom nav, Medium → nav rail, Expanded → drawer + two-pane.

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true, // set false when the product has a fixed brand palette
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (darkTheme) dynamicDarkColorScheme(LocalContext.current) else dynamicLightColorScheme(LocalContext.current)
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    MaterialTheme(colorScheme = colorScheme, typography = AppTypography, shapes = AppShapes, content = content)
}
```

## Validation

- Phone and tablet breakpoints (Compose previews with `@PreviewScreenSizes`, or emulator).
- Light and dark themes; contrast and readability in both.
- TalkBack labels and focus order.
- `./gradlew lint test assembleDebug` (or the project's equivalent).

## References

| File                               | Contents                                                                                  |
| ---------------------------------- | ----------------------------------------------------------------------------------------- |
| `references/material3-theming.md`  | Color system, typography, shapes, elevation, responsive design, foldables                 |
| `references/compose-components.md` | Layouts, buttons, cards, lists, forms, search, dialogs, bottom sheets, loading, animation |
| `references/android-navigation.md` | Navigation Compose, type-safe routes, deep links, nested graphs, back handling            |

## Personal Machine Activation

This skill is personal-machine only.

- Linked automatically when `~/.overlay/local/.enabled` is absent (no allowlist to maintain).
