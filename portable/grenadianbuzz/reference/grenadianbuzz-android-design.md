# GrenadianBuzz Android Design Overrides

Apply on top of the generic `mobile-android-design` skill whenever building UI in `grenadianbuzz-android`. These rules override standard Material 3 defaults.

## Tokens

| Token                | Standard M3         | GrenadianBuzz                   |
| -------------------- | ------------------- | ------------------------------- |
| Card corner radius   | 12dp                | **0dp** (`RectangleShape`)      |
| Card elevation       | 1–3dp tonal         | **0dp**                         |
| Button corner radius | shape.small (8dp)   | **4dp**                         |
| Color source         | Dynamic (wallpaper) | **Static tokens** (below)       |
| Primary font         | system default      | **Product Sans Bold / Regular** |
| Metadata font        | system default      | **Source Sans Pro Regular**     |

Static color tokens (`res/values/colors.xml`):

```
colorPrimary        #009688   (Teal 500)
textPrimary         #212121
textSecondary       #757575
surface             #FFFFFF
surface_variant     #F5F5F5
defaultBackground   #FAFAFA
divider_subtle      #E0E0E0
```

## Rules

- Never use `dynamicColorScheme()`. The theme in `ui/theme/` defines static light/dark schemes only.
- Brand color: use `@color/colorPrimary` in XML, or `Color(0xFF009688)` in Compose until the Compose theme maps it to `colorScheme.primary`. Once it does, prefer `MaterialTheme.colorScheme.primary`.
- Buttons: `cornerRadius="4dp"`, `textAllCaps="false"`. See `styles.xml` for `AppTheme.Button.*` variants.
- Cards: `shape = RectangleShape`, `CardDefaults.cardElevation(defaultElevation = 0.dp)`.
- Date strings are uppercased (`.uppercase()`) throughout the app.

## Navigation

The app uses Intent-based navigation today: `MainActivity.kt` hosts the bottom nav and top-level fragments. New Compose screens use Navigation Compose (see `mobile-android-design` → `references/android-navigation.md`); check `docs/ROADMAP.md` for the migration phase before converting existing screens.
