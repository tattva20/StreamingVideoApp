# Memory Management Feature

The Memory Management feature monitors system memory, detects pressure levels, and coordinates resource cleanup to prevent out-of-memory crashes.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Memory Management                          │
│                                                             │
│  PollingMemoryMonitor ──▶ ResourceCleanupCoordinator       │
│         │                          │                        │
│         │ statePublisher           │ cleaners               │
│         ▼                          ▼                        │
│  ┌─────────────┐           ┌─────────────────┐             │
│  │MemoryState  │           │ VideoCacheCleaner│             │
│  │ .normal     │           │ ImageCacheCleaner│             │
│  │ .warning    │           │ BufferCleaner    │             │
│  │ .critical   │           └─────────────────┘             │
│  └─────────────┘                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Continuous Monitoring** - Poll memory state at regular intervals
- **Pressure Levels** - Normal, warning, critical thresholds
- **Auto-Cleanup** - Automatic cleanup on memory pressure
- **Priority-Based** - Clean low-priority resources first
- **Combine Integration** - Reactive state publishing
- **Configurable Thresholds** - Customize pressure levels

---

## Architecture

### MemoryMonitor Protocol

**File:** `StreamingCore/StreamingCore/Memory Monitoring Feature/MemoryMonitor.swift`

```swift
@MainActor
public protocol MemoryStateProvider: AnyObject {
    func currentMemoryState() -> MemoryState
}

@MainActor
public protocol MemoryMonitor: MemoryStateProvider {
    var statePublisher: AnyPublisher<MemoryState, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}
```

### MemoryState

**File:** `StreamingCore/StreamingCore/Memory Monitoring Feature/Domain/MemoryState.swift`

```swift
public struct MemoryState: Equatable, Sendable {
    public let availableMemory: UInt64
    public let usedMemory: UInt64
    public let pressure: MemoryPressure

    public enum MemoryPressure: Sendable {
        case normal
        case warning
        case critical
    }

    public var usagePercentage: Double {
        let total = availableMemory + usedMemory
        guard total > 0 else { return 0 }
        return Double(usedMemory) / Double(total)
    }
}
```

### MemoryThresholds

**File:** `StreamingCore/StreamingCore/Memory Monitoring Feature/Domain/MemoryThresholds.swift`

```swift
public struct MemoryThresholds: Equatable, Sendable {
    public let warningThreshold: Double   // e.g., 0.70 (70%)
    public let criticalThreshold: Double  // e.g., 0.85 (85%)

    public static let `default` = MemoryThresholds(
        warningThreshold: 0.70,
        criticalThreshold: 0.85
    )

    public static let conservative = MemoryThresholds(
        warningThreshold: 0.60,
        criticalThreshold: 0.75
    )

    public func pressure(for usagePercentage: Double) -> MemoryState.MemoryPressure {
        if usagePercentage >= criticalThreshold {
            return .critical
        } else if usagePercentage >= warningThreshold {
            return .warning
        } else {
            return .normal
        }
    }
}
```

---

## PollingMemoryMonitor

**File:** `StreamingCore/StreamingCore/Memory Monitoring Feature/PollingMemoryMonitor.swift`

```swift
@MainActor
public final class PollingMemoryMonitor: MemoryMonitor {
    private let stateSubject = CurrentValueSubject<MemoryState, Never>(.normal)
    private let thresholds: MemoryThresholds
    private let pollingInterval: TimeInterval
    private let memoryProvider: () -> (available: UInt64, used: UInt64)
    private var timer: Timer?

    public var statePublisher: AnyPublisher<MemoryState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public init(
        thresholds: MemoryThresholds = .default,
        pollingInterval: TimeInterval = 5.0,
        memoryProvider: @escaping () -> (available: UInt64, used: UInt64) = Self.systemMemory
    ) {
        self.thresholds = thresholds
        self.pollingInterval = pollingInterval
        self.memoryProvider = memoryProvider
    }

    public func startMonitoring() {
        stopMonitoring()
        updateMemoryState()

        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryState()
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    public func currentMemoryState() -> MemoryState {
        stateSubject.value
    }

    private func updateMemoryState() {
        let memory = memoryProvider()
        let total = memory.available + memory.used
        let usagePercentage = total > 0 ? Double(memory.used) / Double(total) : 0

        let state = MemoryState(
            availableMemory: memory.available,
            usedMemory: memory.used,
            pressure: thresholds.pressure(for: usagePercentage)
        )

        stateSubject.send(state)
    }

    public static func systemMemory() -> (available: UInt64, used: UInt64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (available: 0, used: 0)
        }

        let used = UInt64(info.resident_size)
        let available = ProcessInfo.processInfo.physicalMemory - used
        return (available: available, used: used)
    }
}
```

---

## Resource Cleanup

### ResourceCleaner Protocol

**File:** `StreamingCore/StreamingCore/Resource Cleanup Feature/ResourceCleaner.swift`

```swift
public protocol ResourceCleaner: Sendable {
    var priority: CleanupPriority { get }
    func cleanup() async -> CleanupResult
}
```

### CleanupPriority

**File:** `StreamingCore/StreamingCore/Resource Cleanup Feature/Domain/CleanupPriority.swift`

```swift
public enum CleanupPriority: Int, Comparable, Sendable {
    case low = 0      // Optional caches
    case medium = 1   // Important but not critical
    case high = 2     // Critical resources

    public static func < (lhs: CleanupPriority, rhs: CleanupPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

### CleanupResult

**File:** `StreamingCore/StreamingCore/Resource Cleanup Feature/Domain/CleanupResult.swift`

```swift
public struct CleanupResult: Equatable, Sendable {
    public let cleanerName: String
    public let bytesFreed: UInt64
    public let success: Bool
    public let error: String?
}
```

---

## ResourceCleanupCoordinator

**File:** `StreamingCore/StreamingCore/Resource Cleanup Feature/ResourceCleanupCoordinator.swift`

```swift
@MainActor
public final class ResourceCleanupCoordinator {
    private var cleaners: [(cleaner: ResourceCleaner, priority: CleanupPriority)] = []
    private let cleanupResultsSubject = PassthroughSubject<[CleanupResult], Never>()
    private let memoryMonitor: MemoryMonitor
    private var cancellables = Set<AnyCancellable>()

    public var cleanupResultsPublisher: AnyPublisher<[CleanupResult], Never> {
        cleanupResultsSubject.eraseToAnyPublisher()
    }

    public init(memoryMonitor: MemoryMonitor) {
        self.memoryMonitor = memoryMonitor
    }

    public func register(_ cleaner: ResourceCleaner) {
        cleaners.append((cleaner: cleaner, priority: cleaner.priority))
        cleaners.sort { $0.priority < $1.priority }
    }

    public func enableAutoCleanup() {
        memoryMonitor.statePublisher
            .removeDuplicates(by: { $0.pressure == $1.pressure })
            .sink { [weak self] state in
                Task { await self?.handleMemoryPressure(state.pressure) }
            }
            .store(in: &cancellables)
    }

    private func handleMemoryPressure(_ pressure: MemoryState.MemoryPressure) async {
        switch pressure {
        case .critical:
            await cleanupAll()
        case .warning:
            await cleanupUpTo(priority: .medium)
        case .normal:
            break
        }
    }

    public func cleanupAll() async -> [CleanupResult] {
        var results: [CleanupResult] = []
        for (cleaner, _) in cleaners {
            let result = await cleaner.cleanup()
            results.append(result)
        }
        cleanupResultsSubject.send(results)
        return results
    }

    public func cleanupUpTo(priority: CleanupPriority) async -> [CleanupResult] {
        var results: [CleanupResult] = []
        let toClean = cleaners.filter { $0.priority <= priority }
        for (cleaner, _) in toClean {
            let result = await cleaner.cleanup()
            results.append(result)
        }
        cleanupResultsSubject.send(results)
        return results
    }
}
```

---

## Cache Cleaners

### VideoCacheCleaner

**File:** `StreamingCore/StreamingCore/Resource Cleanup Feature/VideoCacheCleaner.swift`

```swift
public final class VideoCacheCleaner: ResourceCleaner, @unchecked Sendable {
    public let priority: CleanupPriority = .medium
    private let cache: ClearableCache

    public init(cache: ClearableCache) {
        self.cache = cache
    }

    public func cleanup() async -> CleanupResult {
        let sizeBefore = await cache.estimateCacheSize()
        await cache.clearAllCaches()
        let sizeAfter = await cache.estimateCacheSize()

        return CleanupResult(
            cleanerName: "VideoCacheCleaner",
            bytesFreed: sizeBefore - sizeAfter,
            success: true,
            error: nil
        )
    }
}
```

### ImageCacheCleaner

**File:** `StreamingCore/StreamingCore/Resource Cleanup Feature/ImageCacheCleaner.swift`

```swift
public final class ImageCacheCleaner: ResourceCleaner, @unchecked Sendable {
    public let priority: CleanupPriority = .low
    private let cache: ClearableCache

    public init(cache: ClearableCache) {
        self.cache = cache
    }

    public func cleanup() async -> CleanupResult {
        let sizeBefore = await cache.estimateCacheSize()
        await cache.clearAllCaches()

        return CleanupResult(
            cleanerName: "ImageCacheCleaner",
            bytesFreed: sizeBefore,
            success: true,
            error: nil
        )
    }
}
```

---

## Cleanup Strategy

```
Memory Pressure: Normal
──▶ No cleanup

Memory Pressure: Warning
──▶ Clean low priority (images)
──▶ Clean medium priority (video metadata)

Memory Pressure: Critical
──▶ Clean ALL priorities
──▶ Low (images)
──▶ Medium (video metadata)
──▶ High (active buffers)
```

---

## Composition

```swift
// In SceneDelegate
func setupMemoryManagement() {
    let memoryMonitor = PollingMemoryMonitor(
        thresholds: .default,
        pollingInterval: 5.0
    )

    let cleanupCoordinator = ResourceCleanupCoordinator(memoryMonitor: memoryMonitor)

    // Register cleaners in priority order
    cleanupCoordinator.register(ImageCacheCleaner(cache: imageCache))
    cleanupCoordinator.register(VideoCacheCleaner(cache: videoCache))

    // Enable automatic cleanup
    cleanupCoordinator.enableAutoCleanup()

    // Start monitoring
    memoryMonitor.startMonitoring()
}
```

---

## Testing

### Memory Monitor Tests

```swift
@MainActor
func test_statePublisher_emitsStateChanges() {
    var emittedMemory: (available: UInt64, used: UInt64) = (100, 50)
    let sut = PollingMemoryMonitor(
        thresholds: .default,
        pollingInterval: 0.1,
        memoryProvider: { emittedMemory }
    )
    var receivedStates: [MemoryState] = []

    let cancellable = sut.statePublisher.sink { receivedStates.append($0) }

    sut.startMonitoring()

    // Simulate memory pressure
    emittedMemory = (10, 90)  // 90% usage

    RunLoop.current.run(until: Date().addingTimeInterval(0.2))

    XCTAssertTrue(receivedStates.contains { $0.pressure == .critical })
    cancellable.cancel()
}
```

### Cleanup Coordinator Tests

```swift
@MainActor
func test_cleanupAll_cleansAllRegisteredCleaners() async {
    let cleaner1 = ResourceCleanerSpy(priority: .low)
    let cleaner2 = ResourceCleanerSpy(priority: .high)
    let sut = ResourceCleanupCoordinator(memoryMonitor: MemoryMonitorSpy())

    sut.register(cleaner1)
    sut.register(cleaner2)

    _ = await sut.cleanupAll()

    XCTAssertEqual(cleaner1.cleanupCallCount, 1)
    XCTAssertEqual(cleaner2.cleanupCallCount, 1)
}
```

---

## Related Documentation

- [Buffer Management](BUFFER-MANAGEMENT.md) - Memory-aware buffering
- [Offline Support](OFFLINE-SUPPORT.md) - Cache management
- [Performance](../PERFORMANCE.md) - Performance optimization
