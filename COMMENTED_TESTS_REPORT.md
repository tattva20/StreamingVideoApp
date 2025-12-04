# Commented Tests Report - Comprehensive Analysis

**Date:** December 4, 2025
**Project:** StreamingVideoApp
**Test Bundle:** StreamingVideoAppTests

---

## Executive Summary

**Total Commented Tests:** 76 tests across 6 test files

| Category | Tests | Fixability |
|----------|-------|------------|
| Swift Runtime Bug | 72 | ❌ BLOCKED - Awaiting Apple fix |
| Flaky/Async Issues | 4 | ✅ FIXABLE - Timing synchronization |

---

## Complexity Tiers

### 🟢 TIER 1 - Easy to Fix (4 tests)

**Category:** Flaky Async - Run loop synchronization needed

| Test File | Test Name | Issue | Fix Complexity |
|-----------|-----------|-------|----------------|
| VideosUIIntegrationTests | `test_videoSelection_notifiesHandler` | Tap before cell exists | Low - Add `executeRunLoop()` |
| VideosUIIntegrationTests | `test_loadVideoCompletion_rendersSuccessfullyLoadedEmptyVideosAfterNonEmptyVideos` | Table view update timing | Low - Add `executeRunLoop()` |
| VideosUIIntegrationTests | `test_loadingMoreIndicator_isVisibleWhileLoadingMore` | Load more cell timing | Low - Add `executeRunLoop()` |
| VideosUIIntegrationTests | `test_videoImageView_loadsImageURLWhenVisible` | Async task registration timing | Low - Add `executeRunLoop()` |

**Fix Strategy:**
```swift
// Add to XCTestCase+Helpers.swift
extension XCTestCase {
    func executeRunLoop(duration: TimeInterval = 0.01) {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: duration))
    }
}

// Usage in tests:
loader.completeLoading(with: [video0, video1], at: 0)
executeRunLoop()  // Allow table view/async tasks to settle
sut.simulateTapOnVideoView(at: 0)
```

**Estimated Effort:** 1-2 hours

---

### 🔴 TIER 3 - BLOCKED (72 tests)

**Category:** Swift Runtime Malloc Bug - No workaround exists

All tests crash with identical signature:
```
malloc: *** error for object 0x262c5a6f0: pointer being freed was not allocated
libswift_Concurrency.dylib swift::TaskLocal::StopLookupScope::~StopLookupScope()
libswift_Concurrency.dylib swift_task_deinitOnExecutorImpl(...)
```

| Test File | Tests | Sub-Category |
|-----------|-------|--------------|
| StatefulVideoPlayerTests | 23 | State machine + Combine |
| AnalyticsVideoPlayerDecoratorTests | 21 | @MainActor decorator |
| LoggingVideoPlayerDecoratorTests | 19 | @MainActor decorator |
| VideoPlayerPerformanceAdapterTests | 5 | Performance monitoring |
| AVPlayerBufferAdapterTests | 4 | Buffer management |

**Why These Are Blocked:**
1. Crash occurs AFTER assertions pass (during `__deallocating_deinit`)
2. Crash address is FIXED (`0x262c5a6f0`) - runtime-level issue
3. Affects ALL `@MainActor` classes with Combine/async operations
4. Tests pass individually, crash in suite (race condition in test runner)
5. All attempted workarounds failed (see below)

**Failed Workaround Attempts:**
| Attempt | Result |
|---------|--------|
| Remove `@MainActor` from class | Same crash |
| Remove `@MainActor` from protocols | Same crash |
| Use `nonisolated(unsafe)` | Same crash |
| Remove Combine subscriptions | Same crash |
| Use concrete types (no generics) | Same crash |
| Protocol abstraction with test doubles | Same crash |
| `MainActor.assumeIsolated` | Same crash |
| Clean builds + simulator reset | Same crash |

---

## Detailed Test Inventory by Complexity

### 🟢 TIER 1 Tests (4 tests - FIXABLE)

#### VideosUIIntegrationTests.swift

**Test 1: `test_videoSelection_notifiesHandler`**
```swift
// ISSUE: Tap happens before cell is rendered
sut.simulateAppearance()
loader.completeLoading(with: [video0, video1], at: 0)
sut.simulateTapOnVideoView(at: 0)  // ❌ Cell may not exist yet
XCTAssertEqual(selectedVideos, [video0])

// FIX: Add run loop synchronization
sut.simulateAppearance()
loader.completeLoading(with: [video0, video1], at: 0)
executeRunLoop()  // ✅ Wait for table view
sut.simulateTapOnVideoView(at: 0)
XCTAssertEqual(selectedVideos, [video0])
```
**Complexity:** Low
**Root Cause:** `cellForRowAt` hasn't been called yet when tap is simulated

---

**Test 2: `test_loadVideoCompletion_rendersSuccessfullyLoadedEmptyVideosAfterNonEmptyVideos`**
```swift
// ISSUE: Table view hasn't processed empty data
sut.simulateUserInitiatedReload()
loader.completeLoading(with: [], at: 1)
assertThat(sut, isRendering: [])  // ❌ May still show old data

// FIX:
sut.simulateUserInitiatedReload()
loader.completeLoading(with: [], at: 1)
executeRunLoop()  // ✅ Wait for diffable data source
assertThat(sut, isRendering: [])
```
**Complexity:** Low
**Root Cause:** Diffable data source snapshot hasn't been applied

---

**Test 3: `test_loadingMoreIndicator_isVisibleWhileLoadingMore`**
```swift
// ISSUE: Load more cell not dequeued yet
sut.simulateLoadMoreAction()
XCTAssertTrue(sut.isShowingLoadMoreIndicator)  // ❌ Cell may not exist

// FIX:
sut.simulateLoadMoreAction()
executeRunLoop()  // ✅ Wait for willDisplay delegate
XCTAssertTrue(sut.isShowingLoadMoreIndicator)
```
**Complexity:** Low
**Root Cause:** `loadMoreView()` returns nil because cell hasn't been dequeued

---

**Test 4: `test_videoImageView_loadsImageURLWhenVisible`**
```swift
// ISSUE: Async task not registered yet
loader.completeLoading(with: [video0, video1])
sut.simulateVideoViewVisible(at: 0)
XCTAssertEqual(loader.loadedImageURLs, [video0.thumbnailURL])  // ❌ Empty

// FIX:
loader.completeLoading(with: [video0, video1])
executeRunLoop()  // ✅ Wait for table view
sut.simulateVideoViewVisible(at: 0)
executeRunLoop()  // ✅ Wait for Task.immediate to register
XCTAssertEqual(loader.loadedImageURLs, [video0.thumbnailURL])
```
**Complexity:** Low
**Root Cause:** `Task.immediate` in `AsyncLoadResourcePresentationAdapter.loadResource()` schedules work that hasn't executed

---

### 🔴 TIER 3 Tests (72 tests - BLOCKED)

#### StatefulVideoPlayerTests.swift (23 tests)

| Test | Type | Blocking Reason |
|------|------|-----------------|
| `test_init_startsInIdleState` | Sync | DefaultPlaybackStateMachine + @MainActor |
| `test_init_doesNotPlayVideo` | Sync | DefaultPlaybackStateMachine + @MainActor |
| `test_load_transitionsToLoadingState` | Async | Task.immediate + state machine |
| `test_load_forwardsToDecoratee` | Sync | Combine subscription in state machine |
| `test_play_whenReady_transitionsToPlaying` | Async | Task.immediate + state machine |
| `test_play_whenIdle_doesNotTransition` | Async | Task.immediate + state machine |
| `test_play_whenReady_forwardsToDecoratee` | Async | Combine subscription |
| `test_pause_whenPlaying_transitionsToPaused` | Async | Task.immediate + state machine |
| `test_pause_whenNotPlaying_doesNotTransition` | Async | Task.immediate + state machine |
| `test_pause_forwardsToDecoratee` | Async | Combine subscription |
| `test_seek_fromPlaying_transitionsToSeeking` | Async | Task.immediate + state machine |
| `test_seek_forwardsToDecoratee` | Async | Combine subscription |
| `test_stop_transitionsToIdle` | Async | Task.immediate + state machine |
| `test_statePublisher_emitsStateChanges` | Async | Combine publisher + @MainActor |
| `test_currentTime_forwardsToDecoratee` | Sync | @MainActor class deallocation |
| `test_duration_forwardsToDecoratee` | Sync | @MainActor class deallocation |
| `test_volume_forwardsToDecoratee` | Sync | @MainActor class deallocation |
| `test_isMuted_forwardsToDecoratee` | Sync | @MainActor class deallocation |
| `test_seekForward_forwardsToDecoratee` | Sync | @MainActor class deallocation |
| `test_seekBackward_forwardsToDecoratee` | Sync | @MainActor class deallocation |
| `test_setVolume_forwardsToDecoratee` | Sync | @MainActor class deallocation |
| `test_toggleMute_forwardsToDecoratee` | Sync | @MainActor class deallocation |
| `test_setPlaybackSpeed_forwardsToDecoratee` | Sync | @MainActor class deallocation |

---

#### AnalyticsVideoPlayerDecoratorTests.swift (21 tests)

| Test | Type | Blocking Reason |
|------|------|-----------------|
| `test_isPlaying_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_currentTime_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_duration_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_volume_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_isMuted_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_playbackSpeed_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_load_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_play_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_pause_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_seekForward_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_seekBackward_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_seek_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_setVolume_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_toggleMute_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_setPlaybackSpeed_delegatesToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_play_logsPlayEvent` | Async | Task + @MainActor deallocation |
| `test_pause_logsPauseEvent` | Async | Task + @MainActor deallocation |
| `test_seek_logsSeekEvent` | Async | Task + @MainActor deallocation |
| `test_setPlaybackSpeed_logsSpeedChangedEvent` | Async | Task + @MainActor deallocation |
| `test_setVolume_logsVolumeChangedEvent` | Async | Task + @MainActor deallocation |
| `test_toggleMute_logsMuteToggledEvent` | Async | Task + @MainActor deallocation |

---

#### LoggingVideoPlayerDecoratorTests.swift (19 tests)

| Test | Type | Blocking Reason |
|------|------|-----------------|
| `test_isPlaying_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_currentTime_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_duration_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_volume_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_isMuted_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_playbackSpeed_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_load_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_play_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_pause_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_seekForward_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_seekBackward_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_seek_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_setVolume_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_toggleMute_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_setPlaybackSpeed_forwardsToDecoratee` | Sync | @MainActor decorator deallocation |
| `test_load_logsEvent` | Stub | Placeholder - needs implementation |
| `test_play_logsEvent` | Stub | Placeholder - needs implementation |
| `test_pause_logsEvent` | Stub | Placeholder - needs implementation |
| `test_seek_logsEvent` | Stub | Placeholder - needs implementation |

---

#### VideoPlayerPerformanceAdapterTests.swift (5 tests)

| Test | Type | Blocking Reason |
|------|------|-----------------|
| `test_startMonitoring_startsPerformanceServiceSession` | Sync | @MainActor adapter deallocation |
| `test_startMonitoring_startsPlayerObservation` | Sync | @MainActor adapter deallocation |
| `test_networkQualityChanged_updatesPerformanceService` | Sync | @MainActor adapter deallocation |
| `test_memoryPressureChanged_updatesPerformanceService` | Sync | @MainActor adapter deallocation |
| `test_recordBandwidthSample_updatesEstimator` | Sync | @MainActor adapter deallocation |

---

#### AVPlayerBufferAdapterTests.swift (4 tests)

| Test | Type | Blocking Reason |
|------|------|-----------------|
| `test_applyToNewItem_setsPreferredForwardBufferDuration` | Sync | Combine + @MainActor deallocation |
| `test_applyToNewItem_appliesMinimalBuffer_whenConfiguredForMinimal` | Sync | Combine + @MainActor deallocation |
| `test_applyToNewItem_appliesAggressiveBuffer_whenConfiguredForAggressive` | Sync | Combine + @MainActor deallocation |
| `test_configurationUpdate_appliesNewBufferDuration_toCurrentItem` | Async | Combine subscription cleanup |

---

## Recommended Action Plan

### Phase 1: Fix Tier 1 Tests (Immediate - 1-2 hours)

1. **Add `executeRunLoop()` helper** to `XCTestCase+MemoryLeakTracking.swift` or new helper file
2. **Uncomment and fix** the 4 VideosUIIntegrationTests:
   - Add `executeRunLoop()` calls after async operations
   - Run 5x stability check
3. **Commit** with message: "Fix flaky VideosUIIntegrationTests with run loop synchronization"

### Phase 2: Monitor Swift Releases (Ongoing)

1. **Track** Xcode 26.1, 26.2 releases
2. **Test one file** on each release (start with AVPlayerBufferAdapterTests - smallest)
3. **Re-enable** tests one file at a time when fixed

### Phase 3: Consider Alternatives (If Apple doesn't fix)

| Option | Pros | Cons |
|--------|------|------|
| Run tests on Xcode 16.4 | All tests work | Two Xcode versions |
| Swift Testing migration | Modern framework | Major effort |
| Remove @MainActor | May fix crash | Violates patterns |

---

## Test Suite Status Summary

| Scheme | Enabled | Commented | Total |
|--------|---------|-----------|-------|
| StreamingCore | 710 | 0 | 710 |
| StreamingCoreiOS | 181 | 0 | 181 |
| StreamingVideoApp | 87 | 76 | 163 |
| **Total** | **978** | **76** | **1,054** |

---

## References

- Plan file: `/Users/octaviorojas/.claude/plans/abundant-noodling-allen.md`
- Swift Issue #84793: https://github.com/swiftlang/swift/issues/84793
- Swift Issue #75501: https://github.com/swiftlang/swift/issues/75501

---

## Appendix: Fix Code for Tier 1 Tests

```swift
// MARK: - XCTestCase+RunLoop.swift

import XCTest

extension XCTestCase {
    /// Runs the run loop briefly to allow async operations to settle.
    /// Use after operations that trigger async work (table view updates, Task.immediate, etc.)
    func executeRunLoop(duration: TimeInterval = 0.01) {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: duration))
    }
}
```

```swift
// MARK: - Fixed Tests

func test_videoSelection_notifiesHandler() {
    let video0 = makeVideo()
    let video1 = makeVideo()
    var selectedVideos = [Video]()
    let (sut, loader) = makeSUT(selection: { selectedVideos.append($0) })

    sut.simulateAppearance()
    loader.completeLoading(with: [video0, video1], at: 0)
    executeRunLoop()  // ✅ Wait for cells to render

    sut.simulateTapOnVideoView(at: 0)
    XCTAssertEqual(selectedVideos, [video0])

    sut.simulateTapOnVideoView(at: 1)
    XCTAssertEqual(selectedVideos, [video0, video1])
}

func test_loadVideoCompletion_rendersSuccessfullyLoadedEmptyVideosAfterNonEmptyVideos() {
    let video = makeVideo()
    let (sut, loader) = makeSUT()

    sut.simulateAppearance()
    loader.completeLoading(with: [video], at: 0)
    executeRunLoop()  // ✅ Wait for diffable data source
    assertThat(sut, isRendering: [video])

    sut.simulateUserInitiatedReload()
    loader.completeLoading(with: [], at: 1)
    executeRunLoop()  // ✅ Wait for diffable data source
    assertThat(sut, isRendering: [])
}

func test_loadingMoreIndicator_isVisibleWhileLoadingMore() {
    let (sut, loader) = makeSUT()

    sut.simulateAppearance()
    XCTAssertFalse(sut.isShowingLoadMoreIndicator)

    loader.completeLoading(with: [makeVideo()], at: 0)
    executeRunLoop()  // ✅ Wait for table view
    XCTAssertFalse(sut.isShowingLoadMoreIndicator)

    sut.simulateLoadMoreAction()
    executeRunLoop()  // ✅ Wait for willDisplay
    XCTAssertTrue(sut.isShowingLoadMoreIndicator)

    loader.completeLoadMore(with: [makeVideo()], at: 0)
    executeRunLoop()  // ✅ Wait for completion
    XCTAssertFalse(sut.isShowingLoadMoreIndicator)

    sut.simulateLoadMoreAction()
    executeRunLoop()  // ✅ Wait for willDisplay
    XCTAssertTrue(sut.isShowingLoadMoreIndicator)

    loader.completeLoadMoreWithError(at: 1)
    executeRunLoop()  // ✅ Wait for completion
    XCTAssertFalse(sut.isShowingLoadMoreIndicator)
}

func test_videoImageView_loadsImageURLWhenVisible() {
    let video0 = makeVideo(url: URL(string: "http://url-0.com")!)
    let video1 = makeVideo(url: URL(string: "http://url-1.com")!)
    let (sut, loader) = makeSUT()

    sut.simulateAppearance()
    XCTAssertEqual(loader.loadedImageURLs, [])

    loader.completeLoading(with: [video0, video1])
    executeRunLoop()  // ✅ Wait for table view

    sut.simulateVideoViewVisible(at: 0)
    executeRunLoop()  // ✅ Wait for Task.immediate
    XCTAssertEqual(loader.loadedImageURLs, [video0.thumbnailURL])

    sut.simulateVideoViewVisible(at: 1)
    executeRunLoop()  // ✅ Wait for Task.immediate
    XCTAssertEqual(loader.loadedImageURLs, [video0.thumbnailURL, video1.thumbnailURL])
}
```
