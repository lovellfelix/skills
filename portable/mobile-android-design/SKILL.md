---
name: mobile-android-design
description: "Material Design 3 and Jetpack Compose patterns for native Android. Use when designing Android interfaces, implementing Compose UI, building adaptive layouts, or applying M3 theming. Deep-dives in references/: material3-theming.md, compose-components.md, android-navigation.md."
metadata:
  version: 0.1.0
  portable: true
  tags: [android, kotlin, compose, material3, ui, grenadianbuzz]
---

## Personal Machine Activation

This skill is personal-machine only.

- Linked automatically when `~/.overlay/local/.enabled` is absent (no allowlist to maintain).

# Android Mobile Design

## GrenadianBuzz Design Overrides

This project uses **flat design**, not standard M3 defaults. Apply these rules whenever building UI for this repo:

| Token                | Standard M3         | GrenadianBuzz                   |
| -------------------- | ------------------- | ------------------------------- |
| Card corner radius   | 12dp                | **0dp**                         |
| Card elevation       | 1–3dp tonal         | **0dp**                         |
| Button corner radius | shape.small (8dp)   | **4dp**                         |
| Color source         | Dynamic (wallpaper) | **Static tokens** (see below)   |
| Primary font         | system default      | **Product Sans Bold / Regular** |
| Metadata font        | system default      | **Source Sans Pro Regular**     |

**Static color tokens** (defined in `res/values/colors.xml`):

```
colorPrimary        #009688   (Teal 500)
textPrimary         #212121
textSecondary       #757575
surface             #FFFFFF
surface_variant     #F5F5F5
defaultBackground   #FAFAFA
divider_subtle      #E0E0E0
```

Do **not** apply dynamic color (`dynamicColorScheme`) — the app defines its own static palette. Do **not** use `MaterialTheme.colorScheme.primary` for brand color; use `@color/colorPrimary` in XML or define explicit `Color(0xFF009688)` in Compose until the theme is fully wired up.

**Date strings must be `.toUpperCase()`** — design convention throughout the app.

---

## Core Layout Patterns

### Column / Row

```kotlin
Column(
    modifier = Modifier.padding(16.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp),
    horizontalAlignment = Alignment.Start
) {
    Text("Title", style = MaterialTheme.typography.headlineSmall)
    Text(
        "Subtitle",
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}

Row(
    modifier = Modifier.fillMaxWidth(),
    horizontalArrangement = Arrangement.SpaceBetween,
    verticalAlignment = Alignment.CenterVertically
) {
    Icon(Icons.Default.Star, contentDescription = null)
    Text("Featured")
    Spacer(modifier = Modifier.weight(1f))
    TextButton(onClick = {}) { Text("View All") }
}
```

### Lazy Lists

```kotlin
LazyColumn(
    modifier = modifier.fillMaxSize(),
    contentPadding = PaddingValues(16.dp),
    verticalArrangement = Arrangement.spacedBy(8.dp)
) {
    items(items, key = { it.id }) { item ->
        ItemRow(item = item, onClick = { onItemClick(item) })
    }
}

// Adaptive grid
LazyVerticalGrid(
    columns = GridCells.Adaptive(minSize = 150.dp),
    contentPadding = PaddingValues(16.dp),
    horizontalArrangement = Arrangement.spacedBy(12.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp)
) {
    items(items) { item -> ItemCard(item = item) }
}
```

---

## Buttons

```kotlin
// Primary action
Button(onClick = { }) { Text("Continue") }

// Secondary action
FilledTonalButton(onClick = { }) {
    Icon(Icons.Default.Add, null)
    Spacer(Modifier.width(8.dp))
    Text("Add Item")
}

// Outlined
OutlinedButton(onClick = { }) { Text("Cancel") }

// Text
TextButton(onClick = { }) { Text("Learn More") }

// FAB
FloatingActionButton(
    onClick = { },
    containerColor = MaterialTheme.colorScheme.primaryContainer,
    contentColor = MaterialTheme.colorScheme.onPrimaryContainer
) {
    Icon(Icons.Default.Add, contentDescription = "Add")
}
```

> In this repo: all buttons use `cornerRadius="4dp"` and `textAllCaps="false"`. See `styles.xml` for `AppTheme.Button.*` variants.

---

## Cards

```kotlin
// Standard M3 card — override shape to 0dp for this project
Card(
    onClick = onClick,
    modifier = Modifier.fillMaxWidth(),
    shape = RectangleShape,      // flat design: no rounded corners
    elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
) {
    Column {
        AsyncImage(
            model = imageUrl,
            contentDescription = null,
            modifier = Modifier.fillMaxWidth().height(180.dp),
            contentScale = ContentScale.Crop
        )
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
```

---

## Bottom Navigation (current pattern in this app)

The app uses Intent-based navigation today. `MainActivity.kt` hosts the bottom nav and top-level fragments. Compose Navigation is being introduced in Phase 7+.

```kotlin
// Navigation Compose — use for new Compose screens
@Composable
fun MainScreen() {
    val navController = rememberNavController()

    Scaffold(
        bottomBar = {
            NavigationBar {
                val currentDest by navController.currentBackStackEntryAsState()
                NavigationDestination.entries.forEach { dest ->
                    NavigationBarItem(
                        icon = { Icon(dest.icon, contentDescription = null) },
                        label = { Text(dest.label) },
                        selected = currentDest?.destination?.hierarchy
                            ?.any { it.route == dest.route } == true,
                        onClick = {
                            navController.navigate(dest.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = NavigationDestination.Home.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(NavigationDestination.Home.route) { HomeScreen() }
            composable(NavigationDestination.Search.route) { SearchScreen() }
            composable(NavigationDestination.Profile.route) { ProfileScreen() }
        }
    }
}
```

---

## Theming

**Do not use dynamic color in this project.** See `ui/theme/` for the static theme definition.

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    // Static schemes only — no dynamicColorScheme()
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        shapes = AppShapes,
        content = content
    )
}
```

---

## Adaptive Layouts

```kotlin
@Composable
fun AdaptiveLayout() {
    val windowSizeClass = calculateWindowSizeClass(LocalContext.current as Activity)

    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact  -> CompactLayout()   // Phone portrait — bottom nav
        WindowWidthSizeClass.Medium   -> MediumLayout()    // Tablet portrait — nav rail
        WindowWidthSizeClass.Expanded -> ExpandedLayout()  // Tablet landscape — drawer + 2-pane
    }
}
```

---

## Key Rules

- Access colors via `MaterialTheme.colorScheme.*` for dark mode support
- `WindowSizeClass` for responsive breakpoints
- Minimum 48dp touch targets
- Hoist state up; keep composables stateless where possible
- Use `rememberSaveable` (not `remember`) for state that must survive config changes
- `LazyColumn` for any list that can grow; never `Column` with a scroll modifier for long lists
- Cancel coroutines in `DisposableEffect`; don't leak in `LaunchedEffect` without a key

---

## Reference Files

| File                               | Contents                                                                                          |
| ---------------------------------- | ------------------------------------------------------------------------------------------------- |
| `references/material3-theming.md`  | Full color system, typography scale, shape system, elevation, responsive design, foldable support |
| `references/compose-components.md` | Lists, forms, search, dialogs, bottom sheets, date pickers, loading states, animations            |
| `references/android-navigation.md` | Navigation Compose setup, type-safe routes, deep links, nested graphs, back handler, transitions  |
