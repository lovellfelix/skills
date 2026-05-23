# GrenadianBuzz Android Integration Guide

Reference for building and maintaining the Android app for GrenadianBuzz.

## Android App Overview

- **Language**: Kotlin (≈85% migrated from Java; all new code must be Kotlin)
- **UI Framework**: ViewBinding (fragments complete; activities in progress) + Jetpack Compose (Phase 7+, new screens)
- **Minimum SDK**: Android 7.0+ (API 24)
- **Architecture**: MVVM with Repository pattern
- **Storage**: Realm (primary, legacy) + Room (strangler-fig replacement, one entity at a time behind `AuditTrailRepository` interface)
- **Networking**: Retrofit + OkHttp with custom interceptors
- **Async**: Coroutines with Flow
- **Analytics**: Firebase Analytics + custom events
- **Build toolchain**: **Java 17 required** — KAPT is incompatible with Java 25; the build enforces `jvmToolchain(17)`. Use `./gradle-java17.sh` if your system JDK is not 17.

---

## Project Structure

```
com.lovellfelix.grenadianbuzzz/   ← package name (3 z's — critical)
├── activities/          # All Activity classes (Kotlin)
├── fragments/           # All Fragment classes (Kotlin, ViewBinding)
├── adapters/            # RecyclerView adapters (legacy Java/Kotlin mix)
├── models/              # Realm model objects + REST response models
├── rest/                # Retrofit: RestClient.kt, RestInterface.kt
├── data/
│   ├── room/            # Room database (strangler-fig Realm replacement)
│   │   ├── GrenadianBuzzDatabase.kt
│   │   ├── DatabaseProvider.kt
│   │   ├── entities/    # AuditTrailEntity, ObituaryEntity, ObituaryBookmarkEntity, …
│   │   ├── daos/        # AuditTrailDao, ObituaryDao, ObituaryBookmarkDao
│   │   └── migration/
│   └── repository/      # AuditTrailRepository (interface) + implementations
│       └── RepositoryProvider.kt  # selects Realm vs Room implementation
├── ui/
│   ├── compose/
│   │   ├── screens/     # NewsScreen, ObituaryListScreen, ObituaryDetailScreen, RadioScreen
│   │   ├── components/  # ObituaryCompactCard, ArticleCard, StationCard, …
│   │   ├── obituary/    # ObituaryViewModel, ObituaryDetailViewModel
│   │   ├── news/
│   │   ├── radio/
│   │   └── theme/
├── services/            # Background services
├── workers/             # WorkManager workers
├── player/              # ExoPlayer integration
├── utils/               # RealmHelper, ObituariesUtils, …
└── views/               # Custom views
```

---

## API Integration Patterns

### Retrofit Service Definition

```kotlin
// Follows API versioning: /v2, /v3
interface ArticlesService {
    @GET("/v2/articles")
    suspend fun listArticles(
        @Query("category") category: String? = null,
        @Query("limit") limit: Int = 20,
        @Query("cursor") cursor: String? = null,
        @Query("sort") sort: String = "published_at"
    ): Response<ArticlesListResponse>

    @GET("/v2/articles/{id}")
    suspend fun getArticle(
        @Path("id") articleId: String
    ): Response<ArticleResponse>
}
```

### Request/Response Models

API responses are wrapped in a `data` envelope. Map to Kotlin data classes:

```kotlin
// Server response: { "data": { "id": "...", "title": "..." } }
data class ArticleResponse(
    @SerializedName("data")
    val data: Article
)

data class Article(
    val id: String,
    val title: String,
    val content: String,
    val image_url: String?,
    val status: String,  // "published", "draft"
    val is_flagged: Boolean = false,
    val comments_count: Int = 0,
    val like_count: Int = 0,
    val created_at: String,
    val updated_at: String
)

// Server list response: { "data": [...], "metadata": { "has_more": true, "next_cursor": "..." } }
data class ArticlesListResponse(
    @SerializedName("data")
    val articles: List<Article>,
    @SerializedName("metadata")
    val metadata: PaginationMetadata
)

data class PaginationMetadata(
    val has_more: Boolean,
    val next_cursor: String?
)
```

### Authentication

JWT tokens cached locally with refresh logic:

```kotlin
class AuthManager(private val context: Context) {
    private val prefs = context.getSharedPreferences("auth", Context.MODE_PRIVATE)
    private val tokenKey = "jwt_token"
    private val expiryKey = "jwt_expiry"

    fun setToken(token: String, expiresIn: Long = 86400L) {
        val expiry = System.currentTimeMillis() + (expiresIn * 1000)
        prefs.edit().apply {
            putString(tokenKey, token)
            putLong(expiryKey, expiry)
        }.apply()
    }

    fun getToken(): String? {
        val token = prefs.getString(tokenKey, null)
        val expiry = prefs.getLong(expiryKey, 0L)

        return if (token != null && System.currentTimeMillis() < expiry) {
            token
        } else {
            clearToken()
            null
        }
    }

    fun clearToken() {
        prefs.edit().remove(tokenKey).remove(expiryKey).apply()
    }
}

// Retrofit interceptor adds token to all requests
class AuthInterceptor(private val authManager: AuthManager) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val token = authManager.getToken()
        val request = if (token != null) {
            chain.request().newBuilder()
                .addHeader("Authorization", "Bearer $token")
                .build()
        } else {
            chain.request()
        }
        return chain.proceed(request)
    }
}
```

### Network Resilience

Exponential backoff for retries (diaspora users on spotty networks):

```kotlin
class RetryInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        var attempt = 0
        var request = chain.request()
        var response: Response? = null
        var exception: IOException? = null

        while (attempt < 3) {
            try {
                response = chain.proceed(request)
                if (response.isSuccessful) return response
                // Don't retry if 4xx (except 429)
                if (response.code !in 500..599 && response.code != 429) return response
            } catch (e: IOException) {
                exception = e
            }

            val delay = (Math.pow(2.0, attempt.toDouble()) * 100).toLong() + Random.nextLong(50)
            Thread.sleep(delay)
            attempt++
        }

        return response ?: throw exception ?: IOException("Failed after retries")
    }
}
```

### Error Handling

```kotlin
sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val code: Int, val message: String) : ApiResult<Nothing>()
    object Loading : ApiResult<Nothing>()
}

// ViewModel usage
val articles = MutableStateFlow<ApiResult<List<Article>>>(ApiResult.Loading)

viewModelScope.launch {
    articles.value = try {
        val response = articleService.listArticles(category = "news")
        if (response.isSuccessful) {
            ApiResult.Success(response.body()?.articles ?: emptyList())
        } else {
            ApiResult.Error(response.code(), response.message())
        }
    } catch (e: IOException) {
        ApiResult.Error(-1, "Network error: ${e.message}")
    }
}
```

---

## Local Storage & Offline-First

**Current state**: Realm is the primary local database. Room is being introduced as a strangler-fig replacement — entities migrate one at a time behind the `AuditTrailRepository` interface. `RepositoryProvider.kt` selects the active implementation. Room schema snapshots are committed under `app/schemas/` and tracked in diffs.

Example Room entity pattern (for new entities being migrated):

```kotlin
@Entity(tableName = "articles")
data class CachedArticle(
    @PrimaryKey val id: String,
    val title: String,
    val content: String,
    val image_url: String?,
    val status: String,
    val is_flagged: Boolean,
    val cached_at: Long = System.currentTimeMillis()
)

@Dao
interface ArticleDao {
    @Query("SELECT * FROM articles WHERE is_flagged = 0 ORDER BY cached_at DESC")
    fun getArticles(): Flow<List<CachedArticle>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(article: CachedArticle)

    @Query("DELETE FROM articles WHERE cached_at < :beforeTime")
    suspend fun deleteOlderThan(beforeTime: Long)
}
```

### Repository Pattern (Local + Remote)

```kotlin
class ArticleRepository(
    private val apiService: ArticlesService,
    private val articleDao: ArticleDao
) {
    fun getArticles(category: String?): Flow<ApiResult<List<Article>>> = flow {
        // Emit cached data immediately
        emit(ApiResult.Loading)
        articleDao.getArticles().collect { cached ->
            emit(ApiResult.Success(cached.map { it.toArticle() }))
        }

        // Fetch fresh data and update cache
        try {
            val response = apiService.listArticles(category = category)
            if (response.isSuccessful) {
                val articles = response.body()?.articles ?: emptyList()
                articles.forEach { article ->
                    articleDao.insert(article.toCached())
                }
                emit(ApiResult.Success(articles))
            } else {
                emit(ApiResult.Error(response.code(), response.message()))
            }
        } catch (e: IOException) {
            emit(ApiResult.Error(-1, "Network error: ${e.message}"))
        }
    }
}
```

---

## UI Patterns with JetpackCompose

Actual Compose screens live in `ui/compose/screens/`: `NewsScreen`, `ObituaryListScreen`, `ObituaryDetailScreen`, `RadioScreen`. Reusable components are in `ui/compose/components/`.

### News Screen (example pattern)

```kotlin
@Composable
fun NewsScreen(
    viewModel: NewsViewModel,
    modifier: Modifier = Modifier
) {
    val articles by viewModel.articles.collectAsState()

    LazyColumn(modifier = modifier) {
        when (articles) {
            is ApiResult.Loading -> {
                item { CircularProgressIndicator() }
            }
            is ApiResult.Success -> {
                items(articles.data) { article ->
                    ArticleCard(
                        article = article,
                        onArticleClick = { viewModel.navigateToArticle(article.id) },
                        onReactionClick = { emoji -> viewModel.addReaction(article.id, emoji) }
                    )
                }
                // Load more when reaching end
                item {
                    LaunchedEffect(Unit) {
                        viewModel.loadMore()
                    }
                }
            }
            is ApiResult.Error -> {
                item {
                    Text("Error loading articles: ${(articles as ApiResult.Error).message}")
                }
            }
        }
    }
}
```

### Engagement Component (Reactions)

```kotlin
@Composable
fun ReactionBar(
    article: Article,
    onReactionClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val reactions = listOf("👍", "❤️", "🕯️", "💖", "🌹", "🙏")

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        reactions.forEach { emoji ->
            Button(
                onClick = { onReactionClick(emoji) },
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(4.dp)
            ) {
                Text(emoji)
            }
        }
    }
}
```

### Article Detail Screen with Offline Fallback

```kotlin
@Composable
fun ArticleDetailScreen(
    articleId: String,
    viewModel: ArticleDetailViewModel,
    modifier: Modifier = Modifier
) {
    val article by viewModel.article.collectAsState()
    val isOnline by viewModel.isOnline.collectAsState()

    LaunchedEffect(articleId) {
        viewModel.loadArticle(articleId)
    }

    when (val state = article) {
        is ApiResult.Loading -> CircularProgressIndicator()
        is ApiResult.Success -> {
            Column(
                modifier = modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp)
            ) {
                if (!isOnline) {
                    Surface(
                        color = Color.Yellow,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Offline - showing cached content", Modifier.padding(8.dp))
                    }
                }

                ArticleContent(article = state.data)
                ReactionBar(
                    article = state.data,
                    onReactionClick = { emoji -> viewModel.addReaction(articleId, emoji) }
                )
                CommentThread(comments = state.data.comments)
            }
        }
        is ApiResult.Error -> Text("Error: ${state.message}")
    }
}
```

---

## Analytics Events

Firebase Analytics + custom event tracking:

```kotlin
class AnalyticsManager(private val context: Context) {
    private val firebaseAnalytics = FirebaseAnalytics.getInstance(context)

    fun trackArticleView(articleId: String, category: String) {
        firebaseAnalytics.logEvent("article_view", bundleOf(
            "article_id" to articleId,
            "category" to category,
            "timestamp" to System.currentTimeMillis()
        ))
    }

    fun trackReaction(articleId: String, emoji: String) {
        firebaseAnalytics.logEvent("reaction_added", bundleOf(
            "article_id" to articleId,
            "emoji" to emoji
        ))
    }

    fun trackCommentAdded(articleId: String, commentLength: Int) {
        firebaseAnalytics.logEvent("comment_added", bundleOf(
            "article_id" to articleId,
            "comment_length" to commentLength
        ))
    }

    fun trackNewsletterOptIn(segment: String) {
        firebaseAnalytics.logEvent("newsletter_optin", bundleOf(
            "segment" to segment
        ))
    }
}
```

---

---

## Build & Deployment

### Build Configuration

Key build facts (see `app/build.gradle` for full config):

```
applicationId:  com.lovellfelix.grenadianbuzzz   ← 3 z's
minSdk:         24 (Android 7.0)
targetSdk:      35
compileSdk:     35
jvmToolchain:   17 (enforced; KAPT fails on Java 25)
```

Build types:

- `debug` — `applicationIdSuffix ".debug"`, points at `API_HOST_IP` (local dev)
- `release` — minify + shrink enabled, points at `GBUZZ_API_HOST_URL` (production)

Version code is derived from `git rev-list --count HEAD` + offset 8930. Version name from latest git tag.

No product flavors / no admin app variant in this repo.

### Release Checklist

- [ ] Update version tag (version name derived from git tag)
- [ ] Test on Android 7.0+ devices (min SDK 24)
- [ ] Run `./gradlew test` and `./gradlew connectedAndroidTest`
- [ ] Check auth flow: login, token expiry, token refresh
- [ ] Analytics: verify Firebase events firing
- [ ] Performance: check ANR logs in Android Studio Profiler
- [ ] Battery/memory: profile with Android Studio Profiler
- [ ] Play Store release: `./gradlew publishBundle --track=beta`; staged rollout to production via `promoteArtifact`

---

## ADB Local Verification (Emulator)

Use ADB to verify builds on the connected emulator without relying on build success alone.

**ADB path**: `export PATH="$PATH:/Users/lovellfelix/Library/Android/sdk/platform-tools"`

**Package names** (verified via `adb shell pm list packages | grep grenadian`):

- Debug: `com.lovellfelix.grenadianbuzzz.debug`
- Release: `com.lovellfelix.grenadianbuzz`

**Launcher activity**: `com.lovellfelix.grenadianbuzzz.activities.HomeActivity` (NOT `MainActivity`)

**APK filename**: Debug output is NOT `app-debug.apk` — it follows `grenadianbuzz-v{version}(debug)-{hash}-{date}.apk`

```bash
find app/build/outputs/apk/debug -name "*.apk"  # always locate before installing
```

**Emulator display**: 1280×2856 @ 480dpi — always use UI dump for tap coordinates, never guess from screenshots.

```bash
# Install
adb -s emulator-5554 install -r "app/build/outputs/apk/debug/<name>.apk"

# Launch
adb -s emulator-5554 shell am start -n \
  "com.lovellfelix.grenadianbuzzz.debug/com.lovellfelix.grenadianbuzzz.activities.HomeActivity"

# Screenshot
adb -s emulator-5554 shell screencap -p /sdcard/s.png && adb -s emulator-5554 pull /sdcard/s.png /tmp/s.png

# Exact element coordinates (never guess)
adb -s emulator-5554 shell uiautomator dump /sdcard/ui.xml && adb -s emulator-5554 pull /sdcard/ui.xml /tmp/ui.xml
grep -o 'text="<label>"[^>]*>' /tmp/ui.xml  # extract bounds="[x1,y1][x2,y2]", tap center

# App-only logcat (no system noise)
adb -s emulator-5554 logcat -d --pid=$(adb -s emulator-5554 shell pidof com.lovellfelix.grenadianbuzzz.debug)
```

**Worktree setup**: Worktrees do NOT inherit `local.properties` or `google-services.json` from the main repo.

```bash
cp /path/to/main/repo/local.properties .
cp /path/to/main/repo/app/google-services.json app/
```

---

## Radio Architecture & EventBus Patterns

The radio feature uses ExoPlayer inside a `MediaBrowserServiceCompat` (`RadioService`) with EventBus for cross-component status updates.

### Status flow

```
User tap → RadioFragment.itemClicked() → RadioManager.playOrPause()
  → RadioService.playOrPause() → ExoPlayer.prepare() + playWhenReady=true
  → RadioService.onPlayerStateChanged() → EventBus.post(status)
  → MiniPlayerController.onPlaybackStatusChanged() → show/hide mini player
  → RadioFragment.onEvent() → handle ERROR only
```

### EventBus + `bindService` gotcha

`bindService()` is async — `service` is **always `null`** immediately after calling it. Any `EventBus.post()` that reads `service` in `bind()` is a silent no-op.

```kotlin
// WRONG — service is null, post never fires
fun bind() {
    context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    service?.let { EventBus.getDefault().post(it.getStatus()) }  // silent no-op
}

// CORRECT
fun bind() {
    if (serviceBound) {
        service?.let { EventBus.getDefault().post(it.getStatus()) }
        return
    }
    context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
}

override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
    service = (binder as? RadioService.LocalBinder)?.getService()
    serviceBound = true
    service?.let { EventBus.getDefault().post(it.getStatus()) }  // service is live here
}
```

The `serviceBound` short-circuit lets `RadioFragment.onResume()` re-trigger a status post without re-binding (e.g., when returning to the Radio tab mid-playback).

### Mini player visibility

`MiniPlayerController` is attached in `MainActivity.onCreate()`. Its container (`R.id.mini_player_container`) is in `content_main.xml` — a sibling to `fragment_layout`, **not** inside any fragment. It persists across all tab switches.

Visibility is entirely driven by EventBus:

- `PLAYING` / `LOADING` / `PAUSED` → show
- `IDLE` / `STOPPED` / `ERROR` → hide

If the mini player disappears unexpectedly: first check `onPlayerStateChanged` logs — it may be a genuine STOPPED/ERROR from a failed stream, not a layout bug.

### Companion object `MutableList` in Fragment

Static lists in `companion object` survive Fragment destruction. If a list is populated in a lifecycle method called on every Fragment creation, it **accumulates** entries across tab navigations.

```kotlin
// WRONG — accumulates across navigations
companion object {
    val stationList: MutableList<MediaMetaData> = ArrayList()
}
private fun setUpRecyclerView() {
    for (station in stations) { stationList.add(...) }  // doubles on every navigate
}

// CORRECT
private fun setUpRecyclerView() {
    stationList.clear()  // reset before repopulating
    for (station in stations) { stationList.add(...) }
}
```

---

## Troubleshooting

**App crashes on launch**

- Check logcat: `adb logcat | grep FATAL`
- Verify API key/auth in Retrofit configuration
- Check Room database initialization

**Offline feed not showing cached articles**

- Verify ArticleDao queries return data: debug with `adb shell`
- Check cache expiration logic (deleteOlderThan timing)
- Ensure Room database file exists: `adb shell ls /data/data/com.lovellfelix.grenadianbuzzz.debug/databases/`

**Token expired in middle of session**

- Verify token refresh in AuthInterceptor
- Check JWT exp claim parsing
- Ensure Retrofit retries failed requests after token refresh

**Moderation status showing in user feed (should be hidden)**

- Verify is_flagged check in ArticleCard Composable
- Add safety filter: `articles.filter { !it.is_flagged }`

**Rate limiting errors (429) on image loading**

- Check image size optimization (ImageUrl compression on server)
- Implement caching in OkHttp: `CacheControl.FORCE_CACHE` for images
- Use ETag/conditional requests to reduce bandwidth

**Radio mini player doesn't appear after tapping a station**

- Check logcat for `onServiceConnected` — if missing, service failed to bind
- Confirm EventBus post is in `onServiceConnected`, not in `bind()` (async timing)
- Check `stationList` for stale entries — `itemClicked(position)` may reference wrong station

**Radio stream stops immediately after starting**

- Stream URL may be expired (check for old timestamps in URL params)
- STOPPED/ERROR EventBus event will correctly hide the mini player — this is expected behavior
- Test with a known-live stream URL to isolate service vs. stream issues

---

## References

- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Room Database](https://developer.android.com/training/data-storage/room)
- [Retrofit](https://square.github.io/retrofit/)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)
