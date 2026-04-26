GrenadianBuzz Android Test Matrix

Purpose
- Define essential Android test coverage across device types, OS versions, and network conditions to reduce release risk.

Matrix Dimensions
- Platforms: Android
- Test types: unit, instrumentation (UI), integration (network), e2e
- OS versions: minSupported .. latest (recommend: API 24, 26, 29, 31, 33)
- Form factors: phone (small, normal), large (phablet/tablet)
- Networks: 3G, 4G, LTE, offline, high-latency

Recommended Matrix
1. Unit tests (CI every PR)
   - JVM unit tests covering view models, business logic, serialization, and mapping.

2. Instrumented UI tests (daily/PR)
   - Espresso/Compose tests for critical flows: sign-in, publish, feed scroll, moderation actions.
   - Run on emulators for API 29 and API 33.

3. Integration tests (nightly)
   - Mock backend or use dedicated staging that supports test accounts. Cover sync, retry, offline queue draining.

4. Real-device matrix (pre-release)
   - Smoke on a small set of real devices (one each: Android 11, 12, 13) for performance and UI correctness.

5. Network resilience
   - Simulate flaky networks, high latency, and offline behavior in tests. Validate exponential backoff and retries.

6. Crash & ANR monitoring
   - Integrate crash reporting (Sentry/Firebase) and ensure releases have <x crashes per 1000 users threshold.

Test Automation Recommendations
- Use Firebase Test Lab or device farm for broader device coverage pre-release.
- Parallelize tests by shard to keep CI time reasonable.
- Tag slow/integration tests separately from fast unit tests.

Release Criteria
- All critical smoke tests pass on staging devices.
- No regressions in crash rate or increased ANRs in canary cohort.

Ownership
- Mobile engineering to maintain matrix; QA aligns with release manager on pre-release device list.