# GrenadianBuzz Android Integration Guide

Reference for building and maintaining the Android app for GrenadianBuzz.

## Android App Overview

- **Language**: Kotlin
- **UI Framework**: JetpackCompose
- **Minimum SDK**: Android 10+
- **Architecture**: MVVM with Repository pattern
- **Storage**: SQLite for local cache, encrypted SharedPreferences for auth
- **Networking**: Retrofit + OkHttp with custom interceptors
- **Async**: Coroutines with Flow
- **Analytics**: Firebase Analytics + custom events
- **Moderation**: Admin variant with moderation queue interface

---

## Project Structure

```
GrenadianBuzz/
├── app/                        # Main app module
│   ├── src/main/kotlin/
│   │   ├── ui/
│   │   │   ├── screens/        # Composables: Feed, Article, Events, Settings
│   │   │   ├── components/     # Reusable: ArticleCard, CommentThread, ReactionPicker
│   │   │   └── theme/          # Colors, typography, spacing
│   │   ├── viewmodels/         # ViewModel: FeedViewModel, ArticleViewModel, etc.
│   │   ├── data/
│   │   │   ├── api/            # Retrofit services, interceptors, error handling
│   │   │   ├── db/             # Room database, DAOs
│   │   │   ├── repository/     # Repository pattern (local + remote)
│   │   │   └── models/         # Data classes mirroring API payloads
│   │   ├── utils/              # Helpers, date parsing, analytics
│   │   └── App.kt              # Application entry point
│   └── AndroidManifest.xml     # Permissions, app configuration
├── admin/                      # Admin app variant (moderation queue)
└── build.gradle                # Dependencies, build config
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

SQLite + Room for local cache:

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

### Feed Screen

```kotlin
@Composable
fun FeedScreen(
    viewModel: FeedViewModel,
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

## Admin App Variant

Separate admin variant with moderation queue interface:

```
admin/
├── src/main/AndroidManifest.xml  # Different app ID: com.grenadianbuzz.admin
├── src/main/kotlin/
│   ├── ui/screens/
│   │   ├── ModerationQueueScreen.kt   # Flagged content list
│   │   ├── ReviewDetailScreen.kt      # Single item review, approve/remove buttons
│   │   └── StatsScreen.kt             # Moderation SLA, queue depth
│   ├── viewmodels/
│   │   └── ModerationQueueViewModel.kt
│   └── data/
│       └── api/ModerationService.kt
└── build.gradle                        # Extends app/, additional dependencies
```

Example moderation endpoints consumed by admin app:

```kotlin
interface ModerationService {
    @GET("/moderation/queue")
    suspend fun getQueue(
        @Query("status") status: String = "flagged",
        @Query("limit") limit: Int = 50,
        @Query("cursor") cursor: String? = null
    ): Response<ModerationQueueResponse>

    @GET("/moderation/{resource}/{id}")
    suspend fun getReviewItem(
        @Path("resource") resource: String,
        @Path("id") id: String
    ): Response<ReviewItemResponse>

    @PATCH("/moderation/{resource}/{id}")
    suspend fun updateReviewStatus(
        @Path("resource") resource: String,
        @Path("id") id: String,
        @Body update: ModerationStatusUpdate
    ): Response<ReviewItemResponse>
}

data class ModerationStatusUpdate(
    val moderation_status: String,  // "approved", "removed", "needs_revision"
    val reviewer_notes: String? = null
)
```

---

## Build & Deployment

### Build Configuration

```gradle
android {
    compileSdk 34
    defaultConfig {
        applicationId "com.grenadianbuzz"
        minSdk 30
        targetSdk 34
        versionCode 42
        versionName "2.1.0"
    }

    flavorDimensions "variant"
    productFlavors {
        user {
            dimension "variant"
            applicationId "com.grenadianbuzz"
        }
        admin {
            dimension "variant"
            applicationId "com.grenadianbuzz.admin"
        }
    }
}

dependencies {
    // Kotlin
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.9.10"
    
    // Compose
    implementation "androidx.compose.ui:ui:1.5.4"
    implementation "androidx.compose.material3:material3:1.1.2"
    
    // Networking
    implementation "com.squareup.retrofit2:retrofit:2.9.0"
    implementation "com.squareup.okhttp3:okhttp:4.11.0"
    
    // Persistence
    implementation "androidx.room:room-runtime:2.5.2"
    
    // Coroutines
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3"
    
    // Analytics
    implementation "com.google.firebase:firebase-analytics:21.3.0"
}
```

### Release Checklist

- [ ] Update version code and version name
- [ ] Test on Android 10+ devices (emulator + real devices if possible)
- [ ] Verify offline-first: kill network, check cached articles display
- [ ] Check auth flow: login, token expiry, token refresh
- [ ] Test moderation flow: verify is_flagged is respected in feed
- [ ] Analytics: verify Firebase events firing
- [ ] Admin app: test moderation queue, approve/remove actions
- [ ] Performance: check ANR (Application Not Responding) logs
- [ ] Battery/memory: profile with Android Studio Profiler
- [ ] Play Store release: upload APK/AAB, staged rollout (5% → 25% → 100%)

---

## Troubleshooting

**App crashes on launch**
- Check logcat: `adb logcat | grep FATAL`
- Verify API key/auth in Retrofit configuration
- Check Room database initialization

**Offline feed not showing cached articles**
- Verify ArticleDao queries return data: debug with `adb shell`
- Check cache expiration logic (deleteOlderThan timing)
- Ensure Room database file exists: `adb shell ls /data/data/com.grenadianbuzz/databases/`

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

---

## References

- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Room Database](https://developer.android.com/training/data-storage/room)
- [Retrofit](https://square.github.io/retrofit/)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)
