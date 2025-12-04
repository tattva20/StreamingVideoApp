# Essential Feed vs StreamingVideoApp: Architectural Comparison Report

**Date**: December 4, 2025
**Purpose**: Identify deviations from Essential Feed best practices and recommend improvements

---

## Executive Summary

StreamingVideoApp follows most Essential Feed patterns correctly, but has **8 areas of deviation** that should be addressed. The most critical issues are:

1. **Actor usage instead of @MainActor classes** (partially fixed)
2. **Logger protocol uses async methods** (divergence from sync pattern)
3. **Missing Sendable conformance** on some domain models
4. **Inconsistent test spy patterns** (actor-based vs class-based)
5. **Task.detached usage in decorators** (potential context loss)

---

## Detailed Comparison

### 1. DEPENDENCY INJECTION PATTERNS

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| Composition Root | `SceneDelegate` with lazy vars | `SceneDelegate` with lazy vars | ✅ Match |
| Factory Pattern | Static `*UIComposer` methods | Static `*UIComposer` methods | ✅ Match |
| Constructor Injection | All dependencies via init | All dependencies via init | ✅ Match |
| No Service Locator | Explicit wiring | Explicit wiring | ✅ Match |

**Verdict**: ✅ **Fully Aligned**

---

### 2. PROTOCOL DESIGN

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| Naming Convention | `*Loader`, `*Store`, `*Cache` | `*Loader`, `*Store`, `*Cache` | ✅ Match |
| Method Count | 1-3 methods max | 1-3 methods max | ✅ Match |
| Sync vs Async | Sync with `throws` | **Mixed (async Logger)** | ⚠️ Deviation |
| @MainActor on protocols | Minimal | Heavy usage | ⚠️ Deviation |

**Issues Found**:

#### Issue 2.1: Logger Protocol Uses Async Methods
```swift
// StreamingVideoApp - Logger.swift
public protocol Logger: Sendable {
    var minimumLevel: LogLevel { get }
    func log(_ entry: LogEntry) async  // ❌ async method
}

// Essential Feed - No async protocols
// Uses sync methods, async happens at implementation level
```

**Recommendation**: Consider making `log()` synchronous and handling async internally in implementations.

#### Issue 2.2: Heavy @MainActor on Protocols
```swift
// StreamingVideoApp
@MainActor
public protocol MemoryMonitor: MemoryStateProvider { ... }

@MainActor
public protocol BufferManager: BufferSizeProvider { ... }

// Essential Feed - Protocols are actor-agnostic
public protocol FeedStore { ... }  // No @MainActor
```

**Recommendation**: Keep protocols actor-agnostic where possible. Apply `@MainActor` to implementations instead.

---

### 3. TEST ORGANIZATION

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| Spy Naming | `*Spy` suffix | `*Spy` suffix | ✅ Match |
| Stub Naming | `*Stub` suffix | `*Stub` suffix | ✅ Match |
| Memory Leak Tracking | `trackForMemoryLeaks` | `trackForMemoryLeaks` | ✅ Match |
| Shared Test Specs | `XCTestCase+*Specs` | `XCTestCase+*Specs` | ✅ Match |
| Spy Implementation | **Class-based** | **Mixed (Actor + Class)** | ⚠️ Deviation |

**Issue Found**:

#### Issue 3.1: Actor-Based Test Spies
```swift
// StreamingVideoApp - LoggerSpy.swift
actor LoggerSpy: Logger {  // ❌ Actor-based spy
    private var _loggedEntries: [LogEntry] = []
    var loggedEntries: [LogEntry] { _loggedEntries }
}

// Essential Feed - Class-based spy
class FeedStoreSpy: FeedStore {  // ✅ Class-based
    private(set) var receivedMessages = [ReceivedMessage]()
}
```

**Problem**: Actor-based spies require `await` for property access in tests, making assertions awkward:
```swift
// Awkward
let entries = await spy.loggedEntries
XCTAssertEqual(entries.count, 1)

// vs Essential Feed pattern (clean)
XCTAssertEqual(spy.receivedMessages.count, 1)
```

**Recommendation**: Use `@MainActor final class` for test spies, not actors.

---

### 4. COMBINE USAGE PATTERNS

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| Publisher Extensions | Constrained `where Output ==` | Constrained `where Output ==` | ✅ Match |
| Custom Scheduler | `ImmediateWhenOnMainThreadScheduler` | `ImmediateWhenOnMainThreadScheduler` | ✅ Match |
| Async Bridge | `Future` + `Deferred` | `Future` + `Deferred` | ✅ Match |
| AsyncStream Bridge | **None** | **Removed (was present)** | ✅ Fixed |
| dispatchOnMainThread | Present | Present | ✅ Match |

**Verdict**: ✅ **Fully Aligned** (after AsyncStream removal)

---

### 5. ERROR HANDLING

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| Nested Error Enums | `Type.Error` pattern | `Type.Error` pattern | ✅ Match |
| Error Scoping | Per-operation errors | Per-operation errors | ✅ Match |
| Equatable Errors | Yes | Yes | ✅ Match |
| Error ViewModels | `ResourceErrorViewModel` | `ResourceErrorViewModel` | ✅ Match |

**Verdict**: ✅ **Fully Aligned**

---

### 6. MEMORY MANAGEMENT

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| WeakRefVirtualProxy | Present | Present | ✅ Match |
| trackForMemoryLeaks | Present | Present | ✅ Match |
| Deinit Cleanup | CoreData stores | CoreData stores | ✅ Match |
| Weak Captures | `[weak self]` in closures | `[weak self]` in closures | ✅ Match |

**Verdict**: ✅ **Fully Aligned**

---

### 7. THREADING/CONCURRENCY

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| @MainActor Adapters | Yes | Yes | ✅ Match |
| Sendable Models | All domain models | **Partial** | ⚠️ Deviation |
| Task.immediate | Used for bridging | Used for bridging | ✅ Match |
| nonisolated(unsafe) | Used sparingly | Used sparingly | ✅ Match |
| Task.detached | **Not used** | **Used in decorators** | ⚠️ Deviation |

**Issues Found**:

#### Issue 7.1: Task.detached in Decorators
```swift
// StreamingVideoApp - LoggingVideoPlayerDecorator.swift
public func play() {
    Task.detached { [logger, context, level, message] in  // ❌ Loses actor context
        await logger.log(LogEntry(...))
    }
    decoratee.play()
}

// Essential Feed - No Task.detached
// Logging would be synchronous or use Task (not detached)
```

**Problem**: `Task.detached` loses the current actor context and priority. This can cause:
- Unexpected execution order
- Loss of task-local values
- Harder debugging

**Recommendation**: Use `Task { @MainActor in ... }` or make logging synchronous.

#### Issue 7.2: Missing Sendable Conformance
```swift
// StreamingVideoApp - Some models missing Sendable
public struct LogContext {  // ❌ Missing Sendable
    public let correlationID: UUID?
    public let sessionID: UUID?
    // ...
}

// Essential Feed - All models are Sendable
public struct FeedImage: Hashable, Sendable { ... }
```

**Recommendation**: Add `Sendable` conformance to all value types passed across actor boundaries.

---

### 8. FEATURE MODULES

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| Layered Structure | Feature/API/Cache/Presentation | Feature/API/Cache/Presentation | ✅ Match |
| Infrastructure Folder | `Infrastructure/CoreData/` | `Infrastructure/CoreData/` | ✅ Match |
| Shared Modules | `Shared API`, `Shared Presentation` | `Shared Combine`, `Shared Presentation` | ✅ Match |
| iOS-Specific Module | `EssentialFeediOS` | `StreamingCoreiOS` | ✅ Match |

**Verdict**: ✅ **Fully Aligned**

---

### 9. DECORATORS AND ADAPTERS

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| Decorator Pattern | `WeakRefVirtualProxy` | `WeakRefVirtualProxy` + Video decorators | ✅ Match |
| Adapter Pattern | `*ViewAdapter`, `*PresentationAdapter` | `*ViewAdapter`, `*PresentationAdapter` | ✅ Match |
| CellController | Present | Present | ✅ Match |
| Decorator Chaining | In Composer | In `VideoPlayerUIComposer` | ✅ Match |

**Minor Issue**:

#### Issue 9.1: Decorator Async Handling
```swift
// StreamingVideoApp - Decorators use fire-and-forget
public func play() {
    Task.detached { ... }  // Fire-and-forget logging
    decoratee.play()
}

// Essential Feed - No async decorators
// Cross-cutting concerns are sync
```

**Recommendation**: Keep decorator operations synchronous. If logging must be async, queue it rather than fire-and-forget.

---

### 10. STATE MANAGEMENT

| Aspect | Essential Feed | StreamingVideoApp | Status |
|--------|---------------|-------------------|--------|
| Immutable ViewModels | Structs only | Structs only | ✅ Match |
| Presenter Pattern | `LoadResourcePresenter` | `LoadResourcePresenter` | ✅ Match |
| State in Adapters | `isLoading` flag | `isLoading` flag | ✅ Match |
| Publisher Types | `PassthroughSubject`, `CurrentValueSubject` | `PassthroughSubject`, `CurrentValueSubject` | ✅ Match |
| State Machine | **Not present** | `DefaultPlaybackStateMachine` | ➕ Addition |

**Verdict**: ✅ **Fully Aligned** (StreamingVideoApp adds state machine which is appropriate for video playback domain)

---

## Summary of Deviations

### Critical (Should Fix)

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| 1 | Actor-based test spies | `LoggerSpy.swift` | Test readability |
| 2 | Task.detached in decorators | `LoggingVideoPlayerDecorator.swift`, `AnalyticsVideoPlayerDecorator.swift` | Execution context loss |

### Moderate (Should Consider)

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| 3 | Async Logger protocol | `Logger.swift` | Protocol complexity |
| 4 | @MainActor on protocols | `MemoryMonitor.swift`, `BufferManager.swift`, etc. | Reduced flexibility |
| 5 | Missing Sendable conformance | `LogContext.swift` and others | Potential data races |

### Minor (Nice to Have)

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| 6 | Fire-and-forget logging | Decorators | Potential lost logs |

---

## Recommended Fixes

### Fix 1: Convert Actor Spies to @MainActor Classes

```swift
// Before
actor LoggerSpy: Logger { ... }

// After
@MainActor
final class LoggerSpy: Logger {
    private var _loggedEntries: [LogEntry] = []
    var loggedEntries: [LogEntry] { _loggedEntries }

    nonisolated var minimumLevel: LogLevel { .debug }

    func log(_ entry: LogEntry) async {
        _loggedEntries.append(entry)
    }
}
```

### Fix 2: Replace Task.detached with Task

```swift
// Before
Task.detached { [logger, ...] in
    await logger.log(...)
}

// After
Task { @MainActor [weak self, logger, ...] in
    await logger.log(...)
}
```

### Fix 3: Consider Sync Logger Protocol

```swift
// Option A: Keep async but document fire-and-forget behavior
// Option B: Make sync with internal queueing
public protocol Logger: Sendable {
    var minimumLevel: LogLevel { get }
    func log(_ entry: LogEntry)  // Sync - implementation handles async
}

// Implementation
@MainActor
final class AsyncLogger: Logger {
    private let queue = DispatchQueue(label: "logger")

    func log(_ entry: LogEntry) {
        queue.async { /* write to disk/network */ }
    }
}
```

### Fix 4: Add Sendable to All Value Types

```swift
public struct LogContext: Sendable {
    public let correlationID: UUID?
    public let sessionID: UUID?
    public let metadata: [String: String]  // Already Sendable
}

public struct LogEntry: Sendable { ... }
```

### Fix 5: Remove @MainActor from Protocols (Optional)

```swift
// Before
@MainActor
public protocol MemoryMonitor { ... }

// After
public protocol MemoryMonitor { ... }

// Apply to implementation
@MainActor
public final class PollingMemoryMonitor: MemoryMonitor { ... }
```

---

## What StreamingVideoApp Does Better

1. **State Machine Pattern** - `DefaultPlaybackStateMachine` is a clean addition for video playback complexity
2. **Memory Pressure Monitoring** - `PollingMemoryMonitor` and `ResourceCleanupCoordinator` are domain-appropriate
3. **Adaptive Strategies** - `BitrateStrategy`, `PreloadStrategy` show good use of Strategy pattern
4. **Performance Monitoring** - `PlaybackPerformanceService` tracks metrics Essential Feed doesn't need

---

## Alignment Score

| Category | Score |
|----------|-------|
| Dependency Injection | 10/10 |
| Protocol Design | 7/10 |
| Test Organization | 8/10 |
| Combine Usage | 10/10 |
| Error Handling | 10/10 |
| Memory Management | 10/10 |
| Threading/Concurrency | 7/10 |
| Feature Modules | 10/10 |
| Decorators/Adapters | 9/10 |
| State Management | 10/10 |
| **Overall** | **91/100** |

---

## Conclusion

StreamingVideoApp is **91% aligned** with Essential Feed patterns. The main areas for improvement are:

1. **Test spy implementation** - Switch from actors to @MainActor classes
2. **Task.detached usage** - Replace with regular Task
3. **Sendable conformance** - Add to remaining value types
4. **Protocol @MainActor** - Consider moving to implementations

The codebase demonstrates strong adherence to Clean Architecture principles and would benefit from the minor refinements outlined above.
