# Malloc Crash Investigation Report

## Executive Summary

After extensive investigation, the malloc crashes (`malloc: *** error for object 0x262c5a6f0: pointer being freed was not allocated`) are caused by a combination of:
1. Swift actors with `nonisolated(unsafe)` Combine subject properties
2. Fire-and-forget `Task.immediate` / `Task {}` patterns without proper lifecycle management
3. Test teardown timing issues when actors are deallocated

---

## 1. Summary of All Commented Tests

### Test Suite: StatefulVideoPlayerTests (22 tests commented)
| # | Test Name | Category |
|---|-----------|----------|
| 1 | `test_init_startsInIdleState` | Initialization |
| 2 | `test_init_doesNotPlayVideo` | Initialization |
| 3 | `test_load_transitionsToLoadingState` | Load |
| 4 | `test_play_whenReady_transitionsToPlaying` | Play |
| 5 | `test_play_whenIdle_doesNotTransition` | Play |
| 6 | `test_play_whenReady_forwardsToDecoratee` | Play |
| 7 | `test_pause_whenPlaying_transitionsToPaused` | Pause |
| 8 | `test_pause_whenNotPlaying_doesNotTransition` | Pause |
| 9 | `test_pause_forwardsToDecoratee` | Pause |
| 10 | `test_seek_fromPlaying_transitionsToSeeking` | Seek |
| 11 | `test_seek_forwardsToDecoratee` | Seek |
| 12 | `test_stop_transitionsToIdle` | Stop |
| 13 | `test_statePublisher_emitsStateChanges` | Publishers |
| 14 | `test_currentTime_forwardsToDecoratee` | Property Forwarding |
| 15 | `test_duration_forwardsToDecoratee` | Property Forwarding |
| 16 | `test_volume_forwardsToDecoratee` | Property Forwarding |
| 17 | `test_isMuted_forwardsToDecoratee` | Property Forwarding |
| 18 | `test_seekForward_forwardsToDecoratee` | Method Forwarding |
| 19 | `test_seekBackward_forwardsToDecoratee` | Method Forwarding |
| 20 | `test_setVolume_forwardsToDecoratee` | Method Forwarding |
| 21 | `test_toggleMute_forwardsToDecoratee` | Method Forwarding |
| 22 | `test_setPlaybackSpeed_forwardsToDecoratee` | Method Forwarding |

**SUT:** `StatefulVideoPlayer` (holds `DefaultPlaybackStateMachine` actor)

### Test Suite: LoggingVideoPlayerDecoratorTests (18 tests commented)
| # | Test Name | Category |
|---|-----------|----------|
| 1 | `test_isPlaying_forwardsToDecoratee` | Property Forwarding |
| 2 | `test_currentTime_forwardsToDecoratee` | Property Forwarding |
| 3 | `test_duration_forwardsToDecoratee` | Property Forwarding |
| 4 | `test_volume_forwardsToDecoratee` | Property Forwarding |
| 5 | `test_isMuted_forwardsToDecoratee` | Property Forwarding |
| 6 | `test_playbackSpeed_forwardsToDecoratee` | Property Forwarding |
| 7 | `test_load_forwardsToDecoratee` | Method Forwarding |
| 8 | `test_play_forwardsToDecoratee` | Method Forwarding |
| 9 | `test_pause_forwardsToDecoratee` | Method Forwarding |
| 10 | `test_seekForward_forwardsToDecoratee` | Method Forwarding |
| 11 | `test_seekBackward_forwardsToDecoratee` | Method Forwarding |
| 12 | `test_seek_forwardsToDecoratee` | Method Forwarding |
| 13 | `test_setVolume_forwardsToDecoratee` | Method Forwarding |
| 14 | `test_toggleMute_forwardsToDecoratee` | Method Forwarding |
| 15 | `test_setPlaybackSpeed_forwardsToDecoratee` | Method Forwarding |
| 16 | `test_load_logsEvent` | Logging |
| 17 | `test_play_logsEvent` | Logging |
| 18 | `test_pause_logsEvent` | Logging |
| 19 | `test_seek_logsEvent` | Logging |

**SUT:** `LoggingVideoPlayerDecorator` (uses fire-and-forget `Task.immediate` for logging)

### Test Suite: AnalyticsVideoPlayerDecoratorTests (12 tests commented)
| # | Test Name | Category |
|---|-----------|----------|
| 1 | `test_load_delegatesToDecoratee` | Delegation |
| 2 | `test_pause_delegatesToDecoratee` | Delegation |
| 3 | `test_seekForward_delegatesToDecoratee` | Delegation |
| 4 | `test_seekBackward_delegatesToDecoratee` | Delegation |
| 5 | `test_play_logsPlayEvent` | Analytics Logging |
| 6 | `test_pause_logsPauseEvent` | Analytics Logging |
| 7 | `test_seek_logsSeekEvent` | Analytics Logging |
| 8 | `test_setPlaybackSpeed_logsSpeedChangedEvent` | Analytics Logging |
| 9 | `test_setVolume_logsVolumeChangedEvent` | Analytics Logging |
| 10 | `test_toggleMute_logsMuteToggledEvent` | Analytics Logging |

**SUT:** `AnalyticsVideoPlayerDecorator` (uses fire-and-forget `Task {}` for analytics)

### Test Suite: AVPlayerBufferAdapterTests (4 tests commented)
| # | Test Name | Category |
|---|-----------|----------|
| 1 | `test_applyToNewItem_setsPreferredForwardBufferDuration` | Buffer Configuration |
| 2 | `test_applyToNewItem_appliesMinimalBuffer_whenConfiguredForMinimal` | Buffer Configuration |
| 3 | `test_applyToNewItem_appliesAggressiveBuffer_whenConfiguredForAggressive` | Buffer Configuration |
| 4 | `test_configurationUpdate_appliesNewBufferDuration_toCurrentItem` | Buffer Updates |

**SUT:** `AVPlayerBufferAdapter` (interacts with AVPlayer)

### Test Suite: VideoPlayerPerformanceAdapterTests (7 tests commented)
| # | Test Name | Category |
|---|-----------|----------|
| 1 | `test_init_doesNotStartObserving` | Initialization |
| 2 | `test_stopMonitoring_stopsPerformanceServiceSession` | Monitoring |
| 3 | `test_stopMonitoring_stopsPlayerObservation` | Monitoring |
| 4 | `test_playerStartsPlaying_recordsLoadStartAndFirstFrame` | Events |
| 5 | `test_bufferingStarted_recordsBufferingStartedEvent` | Events |
| 6 | `test_bufferingEnded_recordsBufferingEndedEvent` | Events |

**SUT:** `VideoPlayerPerformanceAdapter` (uses async/await with performance service)

### Test Suite: VideosUIIntegrationTests (1 test commented)
| # | Test Name | Category |
|---|-----------|----------|
| 1 | `test_loadingMoreIndicator_isVisibleWhileLoadingMore` | UI State |

**Total: 64 commented tests across 6 test suites**

---

## 2. What These Tests Have in Common vs Passing Tests

### Common Patterns in Failing Tests:

1. **Actor Dependency**: Tests use classes that interact with `DefaultPlaybackStateMachine` (an actor with `nonisolated(unsafe)` Combine subjects)

2. **Fire-and-Forget Tasks**: Production code spawns Tasks without tracking/cancelling:
   ```swift
   // LoggingVideoPlayerDecorator
   Task.immediate { [weak self, logger, context, level, message] in
       guard self != nil else { return }
       await logger.log(...)
   }

   // AnalyticsVideoPlayerDecorator
   Task { [logger, position] in await logger.log(.play, position: position) }

   // StatefulVideoPlayer
   Task.immediate { @MainActor [weak self] in
       guard let self else { return }
       await self.stateMachine.send(.load(url))
   }
   ```

3. **No Task Lifecycle Management**: Unlike Essential Feed's pattern, Tasks are not stored or cancelled in `deinit`

4. **Test tearDown has RunLoop manipulation**:
   ```swift
   override func tearDown() async throws {
       cancellables.removeAll()
       await Task.yield()
       try? await Task.sleep(nanoseconds: 50_000_000)
       await MainActor.run {
           RunLoop.current.run(until: Date())  // PROBLEMATIC
       }
   }
   ```

### Passing Tests Characteristics:

1. **No Actor Dependencies**: Don't use `DefaultPlaybackStateMachine`
2. **Synchronous Operations**: Don't spawn fire-and-forget Tasks
3. **Simple tearDown**: Just `cancellables.removeAll()` or `super.tearDown()`
4. **Essential Feed Pattern**: When using `Task.immediate`, store in `cancellable` property and cancel in `deinit`

---

## 3. Differences: Working Branch vs Main

### Working Branch (`fix/malloc-crash-working-state`)

**Test Files (5):**
- SceneDelegateTests.swift
- VideoAcceptanceTests.swift
- VideoCommentsUIIntegrationTests.swift
- VideoPlayerUIIntegrationTests.swift
- VideosUIIntegrationTests.swift

**Production Files (11):**
- AppDelegate.swift
- AVPlayerVideoPlayer.swift
- CombineHelpers.swift
- LoadResourcePresentationAdapter.swift
- SceneDelegate.swift
- VideoCommentsUIComposer.swift
- VideoCommentsViewAdapter.swift
- VideoPlayerUIComposer.swift
- VideosUIComposer.swift
- VideosViewAdapter.swift
- WeakRefVirtualProxy.swift

**Key: NO actors, NO `DefaultPlaybackStateMachine`, NO fire-and-forget Tasks without lifecycle management**

### Main Branch (Current)

**Additional Test Files (6):**
- StatefulVideoPlayerTests.swift ❌
- LoggingVideoPlayerDecoratorTests.swift ❌
- AnalyticsVideoPlayerDecoratorTests.swift ⚠️
- AVPlayerBufferAdapterTests.swift ⚠️
- VideoPlayerPerformanceAdapterTests.swift ⚠️
- DeviceInfoProviderTests.swift ✅

**Additional Production Files (17 commits worth):**
- StatefulVideoPlayer.swift (uses `DefaultPlaybackStateMachine` actor)
- LoggingVideoPlayerDecorator.swift (fire-and-forget `Task.immediate`)
- AnalyticsVideoPlayerDecorator.swift (fire-and-forget `Task {}`)
- DefaultPlaybackStateMachine.swift (actor with `nonisolated(unsafe)` subjects)
- PlaybackAnalyticsService.swift (actor)
- PlaybackPerformanceService.swift (actor)
- PollingMemoryMonitor.swift
- ResourceCleanupCoordinator.swift
- And many more...

---

## 4. How Essential Feed Handles This

### Essential Feed Pattern (CORRECT):

```swift
@MainActor
final class AsyncLoadResourcePresentationAdapter<Resource, View: ResourceView> {
    private var cancellable: Task<Void, Never>?  // ✅ STORED

    func loadResource() {
        cancellable = Task.immediate { @MainActor [weak self] in
            // ... async work
        }
    }

    deinit {
        cancellable?.cancel()  // ✅ CANCELLED ON DEALLOC
    }
}
```

### Essential Feed's `nonisolated(unsafe)` Usage:

```swift
// Only for LOCAL VARIABLES, not properties:
nonisolated(unsafe) let uncheckedCompletion = completion
Task.immediate {
    // use uncheckedCompletion
}
```

### StreamingVideoApp Pattern (PROBLEMATIC):

```swift
// DefaultPlaybackStateMachine.swift
public actor DefaultPlaybackStateMachine {
    // ❌ nonisolated(unsafe) on ACTOR PROPERTIES
    private nonisolated(unsafe) let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
    private nonisolated(unsafe) let transitionSubject = PassthroughSubject<PlaybackTransition, Never>()
}

// LoggingVideoPlayerDecorator.swift
private func logEvent(...) {
    // ❌ Fire-and-forget, NOT STORED
    Task.immediate { [weak self, logger, context, level, message] in
        guard self != nil else { return }
        await logger.log(...)
    }
}
```

---

## 5. Detailed Fix Plan: One Test at a Time

### Priority Order (based on dependencies):

1. **Phase 1: Fix Actor Pattern** - `DefaultPlaybackStateMachine`
2. **Phase 2: Fix Decorator Pattern** - `LoggingVideoPlayerDecorator`
3. **Phase 3: Fix Analytics Pattern** - `AnalyticsVideoPlayerDecorator`
4. **Phase 4: Fix State Player** - `StatefulVideoPlayer`
5. **Phase 5: Fix Remaining** - Buffer/Performance adapters

---

### Test #1: `LoggingVideoPlayerDecoratorTests/test_isPlaying_forwardsToDecoratee`

**Current Implementation Problem:**
```swift
// LoggingVideoPlayerDecorator.swift:118-123
private func logEvent(...) {
    Task.immediate { [weak self, logger, context, level, message] in
        guard self != nil else { return }
        await logger.log(...)
    }
    // ❌ Task is fire-and-forget, no cancellation
}
```

**Why It Fails:**
- The test creates `LoggingVideoPlayerDecorator`
- When test ends, the decorator is deallocated
- Any in-flight `Task.immediate` may still be running
- The Task accesses `logger` (an actor) after `self` is checked but potentially deallocated
- Actor deallocation during test teardown triggers malloc crash

**Fix Strategy:**
1. Store Tasks in a `Set<Task<Void, Never>>` property
2. Cancel all tasks in `deinit`
3. Alternatively, make logging synchronous for tests OR use a completion handler pattern

**Expected Result After Fix:**
- Test should pass without malloc crash
- Logging functionality preserved

---

### Test #2: `StatefulVideoPlayerTests/test_init_startsInIdleState`

**Current Implementation Problem:**
```swift
// StatefulVideoPlayer.swift holds:
private let stateMachine: DefaultPlaybackStateMachine

// DefaultPlaybackStateMachine.swift:16-17
private nonisolated(unsafe) let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
private nonisolated(unsafe) let transitionSubject = PassthroughSubject<PlaybackTransition, Never>()
```

**Why It Fails:**
- `nonisolated(unsafe)` on actor properties means they can be accessed from any isolation context
- When actor is deallocated, these subjects may be accessed by subscribed Combine pipelines
- The deallocation order between actor and subjects is undefined
- Results in "pointer being freed was not allocated"

**Fix Strategy (Options):**
1. **Option A:** Remove `nonisolated(unsafe)`, make properties actor-isolated, access via async
2. **Option B:** Use `@unchecked Sendable` wrapper for subjects
3. **Option C:** Use async streams instead of Combine subjects
4. **Option D:** Keep subjects external to the actor (injected dependency)

**Recommended: Option D** - Inject subjects as dependencies, keep actor state internal

---

### Systematic Test Enablement Process:

For EACH test:

1. **Enable ONE test only**
2. **Run test in isolation**: `xcodebuild test -only-testing:'TestSuite/test_name'`
3. **If passes:** Run with other passing tests
4. **If fails:**
   - Document exact error
   - Identify root cause
   - Apply minimal fix
   - Re-test
5. **Only proceed to next test when current passes consistently**

---

## 6. Root Cause Summary Table

| Component | Issue | Severity | Fix Complexity |
|-----------|-------|----------|----------------|
| `DefaultPlaybackStateMachine` | `nonisolated(unsafe)` Combine subjects on actor | HIGH | Medium |
| `LoggingVideoPlayerDecorator` | Fire-and-forget `Task.immediate` | MEDIUM | Low |
| `AnalyticsVideoPlayerDecorator` | Fire-and-forget `Task {}` | MEDIUM | Low |
| `StatefulVideoPlayer` | Fire-and-forget `Task.immediate` + actor dependency | HIGH | Medium |
| Test tearDown methods | `RunLoop.current.run(until: Date())` | MEDIUM | Low |
| `LoggerSpy` actor | Test double is actor - may conflict with production actors | LOW | Low |

---

## 7. Recommended Fixes Summary

### Immediate (Low Risk):
1. Remove `RunLoop.current.run(until: Date())` from all test tearDown methods
2. Store `Task` references and cancel in `deinit` for all decorators

### Short-term (Medium Risk):
3. Refactor `DefaultPlaybackStateMachine` to not use `nonisolated(unsafe)` for properties
4. Add proper Task lifecycle management to `StatefulVideoPlayer`

### Long-term (Architecture):
5. Consider using AsyncStream instead of Combine subjects in actors
6. Follow Essential Feed pattern strictly for Task management

---

## Next Steps

1. Start with `LoggingVideoPlayerDecoratorTests/test_isPlaying_forwardsToDecoratee`
2. Fix the fire-and-forget Task pattern
3. Verify test passes in isolation AND with other tests
4. Document the fix
5. Proceed to next test

**Do not enable multiple tests until each individual test passes consistently.**
