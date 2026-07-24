# Performance Optimization in Tattva

This document explains the performance strategies, monitoring systems, and optimization patterns used in the Tattva.

---

## Overview

Tattva implements several performance optimization strategies:
- Adaptive bitrate selection
- Predictive video preloading
- Intelligent buffer management
- Memory pressure handling
- Performance monitoring and alerts

This stack is cross-platform: the tvOS target wires the same types (for example
`TVPlayerComposer` constructs a `NetworkBandwidthEstimator`), so the strategies
below are not iOS-only. See [Apple TV](features/APPLE-TV.md) for tvOS specifics.

---

## 1. Adaptive Bitrate Selection

### BitrateStrategy Protocol

```swift
public protocol BitrateStrategy: Sendable {
    func initialBitrate(for networkQuality: NetworkQuality,
                       availableLevels: [BitrateLevel]) -> Int

    func shouldUpgrade(currentBitrate: Int, bufferHealth: Double,
                      networkQuality: NetworkQuality,
                      availableLevels: [BitrateLevel]) -> Int?

    func shouldDowngrade(currentBitrate: Int, rebufferingRatio: Double,
                        networkQuality: NetworkQuality,
                        availableLevels: [BitrateLevel]) -> Int?
}
```

### ConservativeBitrateStrategy

Prioritizes stability over quality:

```swift
public struct ConservativeBitrateStrategy: BitrateStrategy, Sendable {
    public func initialBitrate(for networkQuality: NetworkQuality,
                              availableLevels: [BitrateLevel]) -> Int {
        let sortedLevels = availableLevels.sorted()

        switch networkQuality {
        case .offline, .poor: return sortedLevels[0].bitrate
        case .fair: return sortedLevels[sortedLevels.count / 3].bitrate
        case .good: return sortedLevels[sortedLevels.count * 2 / 3].bitrate
        case .excellent: return sortedLevels.last!.bitrate
        }
    }

    public func shouldDowngrade(...) -> Int? {
        if rebufferingRatio >= 0.05 || networkQuality <= .poor {
            return nextLowerBitrate
        }
        return nil
    }
}
```

---

## 2. Video Preloading

### PreloadStrategy Protocol

```swift
public protocol PreloadStrategy: Sendable {
    func videosToPreload(currentVideoIndex: Int,
                        playlist: [PreloadableVideo],
                        networkQuality: NetworkQuality) -> [PreloadableVideo]
}
```

### AdjacentVideoPreloadStrategy

Preloads next videos based on network:

```swift
public struct AdjacentVideoPreloadStrategy: PreloadStrategy {
    public func videosToPreload(...) -> [PreloadableVideo] {
        let count: Int
        switch networkQuality {
        case .excellent: count = 2
        case .good: count = 1
        default: count = 0
        }

        return Array(playlist.dropFirst(currentVideoIndex + 1).prefix(count))
    }
}
```

### DefaultVideoPreloader (Actor)

Thread-safe preloading with cancellation:

```swift
public actor DefaultVideoPreloader: VideoPreloader {
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    public func preload(_ video: PreloadableVideo, priority: PreloadPriority) async {
        activeTasks[video.id]?.cancel()

        let task = Task {
            await performPreload(video)
        }
        activeTasks[video.id] = task

        if priority == .immediate {
            await task.value
        }
    }

    public func cancelPreload(for videoId: UUID) {
        activeTasks[videoId]?.cancel()
        activeTasks[videoId] = nil
    }
}
```

---

## 3. Buffer Management

### AdaptiveBufferManager

Adjusts buffer based on memory and network:

```swift
@MainActor
public final class AdaptiveBufferManager: BufferManager {
    private var memoryPressure: MemoryPressureLevel = .normal
    private var networkQuality: NetworkQuality = .good
    private let thresholds: MemoryThresholds
    private let configurationSubject = CurrentValueSubject<BufferConfiguration, Never>(.balanced)

    public func updateMemoryState(_ state: MemoryState) {
        memoryPressure = state.pressureLevel(thresholds: thresholds)
        recalculateStrategy()
    }

    public func updateNetworkQuality(_ quality: NetworkQuality) {
        networkQuality = quality
        recalculateStrategy()
    }

    private func recalculateStrategy() {
        let newConfig = calculateConfiguration(memory: memoryPressure, network: networkQuality)
        if newConfig != currentConfiguration {
            configurationSubject.send(newConfig)
        }
    }

    // Memory pressure takes precedence over network quality
    private func calculateConfiguration(memory: MemoryPressureLevel,
                                        network: NetworkQuality) -> BufferConfiguration {
        switch memory {
        case .critical: return .minimal
        case .warning: return .conservative
        case .normal:
            switch network {
            case .offline, .poor: return .conservative
            case .fair: return .balanced
            case .good, .excellent: return .aggressive
            }
        }
    }
}
```

### BufferConfiguration

```swift
public struct BufferConfiguration: Equatable, Sendable {
    public let strategy: BufferStrategy
    public let preferredForwardBufferDuration: TimeInterval
    public let reason: String

    public static let minimal = BufferConfiguration(
        strategy: .minimal,
        preferredForwardBufferDuration: 2.0,
        reason: "Memory critical - minimal buffering"
    )

    public static let conservative = BufferConfiguration(
        strategy: .conservative,
        preferredForwardBufferDuration: 5.0,
        reason: "Limited resources - conservative buffering"
    )

    public static let balanced = BufferConfiguration(
        strategy: .balanced,
        preferredForwardBufferDuration: 10.0,
        reason: "Normal conditions - balanced buffering"
    )

    public static let aggressive = BufferConfiguration(
        strategy: .aggressive,
        preferredForwardBufferDuration: 30.0,
        reason: "Optimal conditions - aggressive buffering"
    )
}
```

---

## 4. Memory Management

### MemoryMonitor Protocol

The monitor is split via interface segregation: on-demand state access lives on
`MemoryStateProvider`, and `MemoryMonitor` adds the reactive stream.

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

Pressure is not stored on the state; it is derived on demand from the byte
counts via `pressureLevel(thresholds:)`, which returns the top-level
`MemoryPressureLevel` enum (`normal` / `warning` / `critical`).

```swift
public struct MemoryState: Equatable, Sendable {
    public let availableBytes: UInt64
    public let totalBytes: UInt64
    public let usedBytes: UInt64
    public let timestamp: Date

    public var availableMB: Double { Double(availableBytes) / 1_048_576.0 }
    public var usedMB: Double { Double(usedBytes) / 1_048_576.0 }
    public var usagePercentage: Double { /* usedBytes / totalBytes * 100 */ }

    public func pressureLevel(thresholds: MemoryThresholds) -> MemoryPressureLevel {
        thresholds.pressureLevel(for: availableMB)
    }
}
```

### ResourceCleanupCoordinator

Prioritized cleanup based on memory pressure:

```swift
@MainActor
public final class ResourceCleanupCoordinator {
    private var cleaners: [ResourceCleaner]

    public func enableAutoCleanup() {
        memoryMonitor.startMonitoring()
        monitoringCancellable = memoryMonitor.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                let pressureLevel = state.pressureLevel(thresholds: .default)
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch pressureLevel {
                    case .critical:
                        self.triggerCleanupResults(await self.cleanupAll())
                    case .warning:
                        let results = await self.cleanupUpTo(priority: .medium)
                        if !results.isEmpty { self.triggerCleanupResults(results) }
                    case .normal:
                        break
                    }
                }
            }
    }

    public func cleanupUpTo(priority: CleanupPriority) async -> [CleanupResult] {
        var results: [CleanupResult] = []
        for cleaner in cleaners where cleaner.priority <= priority {
            results.append(await cleaner.cleanup())
        }
        return results
    }
}
```

---

## 5. Performance Monitoring

### PerformanceMonitor Protocol

```swift
@MainActor
public protocol PerformanceMonitor: AnyObject {
    var metricsPublisher: AnyPublisher<PerformanceSnapshot, Never> { get }
    var alertPublisher: AnyPublisher<PerformanceAlert, Never> { get }

    func startMonitoring()
    func stopMonitoring()
    func recordEvent(_ event: PerformanceEvent)
}
```

### PerformanceSnapshot

```swift
public struct PerformanceSnapshot: Equatable, Sendable {
    public let timestamp: Date
    public let timeToFirstFrame: TimeInterval?
    public let isBuffering: Bool
    public let bufferingCount: Int
    public let totalBufferingDuration: TimeInterval
    public let memoryPressure: MemoryPressureLevel

    public var rebufferingRatio: Double {
        let sessionDuration = timestamp.timeIntervalSince(sessionStartTime)
        guard sessionDuration > 0 else { return 0 }
        return totalBufferingDuration / sessionDuration
    }

    public var isHealthy: Bool {
        rebufferingRatio < 0.02 &&
        memoryPressure == .normal &&
        (timeToFirstFrame ?? 0) < 3.0
    }
}
```

### PerformanceAlert

`PerformanceAlert` is a struct carrying a categorized `AlertType` plus severity
and human-readable messaging:

```swift
public struct PerformanceAlert: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let sessionID: UUID
    public let type: AlertType
    public let severity: Severity
    public let timestamp: Date
    public let message: String
    public let suggestion: String?

    public enum AlertType: Equatable, Sendable {
        case slowStartup(duration: TimeInterval)
        case frequentRebuffering(count: Int, ratio: Double)
        case prolongedBuffering(duration: TimeInterval)
        case memoryPressure(level: MemoryPressureLevel)
        case networkDegradation(from: NetworkQuality, to: NetworkQuality)
        case playbackStalled
        case qualityDowngrade(fromBitrate: Int, toBitrate: Int)
    }

    public enum Severity: Int, Sendable, Comparable {
        case info = 0
        case warning = 1
        case critical = 2
    }
}
```

---

## 6. Network Quality Monitoring

### NetworkQuality Levels

```swift
public enum NetworkQuality: Comparable, Sendable {
    case offline
    case poor
    case fair
    case good
    case excellent
}
```

### NetworkBandwidthEstimator

`NetworkBandwidthEstimator`, `BandwidthSample`, and `BandwidthEstimate` live in
the `StreamingCorePlayback` framework, alongside the adapters that feed the
monitor: `AVPlayerPerformanceObserver` observes the live `AVPlayer` and emits
`PerformanceEvent`s, and `VideoPlayerPerformanceAdapter` bridges those into the
`PerformanceSnapshot` stream this document describes.

```swift
@MainActor
public final class NetworkBandwidthEstimator {
    private var samples: [BandwidthSample] = []

    public init(maxSamples: Int = 30) { /* retains a rolling window of samples */ }

    // A sample carries the raw transfer; `bitsPerSecond` is computed from it.
    public func recordSample(_ sample: BandwidthSample) {
        samples.append(sample)
        // drop the oldest beyond maxSamples
    }

    // Rolling throughput estimate over the retained window.
    public var currentEstimate: BandwidthEstimate {
        // averages sample.bitsPerSecond across the window
    }

    public func clear() { samples.removeAll() }
}

// Recording a sample from a completed transfer:
let sample = BandwidthSample(bytesTransferred: bytes, duration: elapsed, timestamp: Date())

// Mapping an estimate to a coarse quality tier lives in NetworkQualityMonitor
// (StreamingCoreiOS), not in the estimator.
```

---

## 7. Startup Time Tracking

### StartupTimeTracker

```swift
public final class StartupTimeTracker {
    private var loadStartTime: Date?
    private var firstFrameTime: Date?

    public func recordLoadStart() {
        loadStartTime = Date()
    }

    public func recordFirstFrame() {
        firstFrameTime = Date()
    }

    public var timeToFirstFrame: TimeInterval? {
        guard let start = loadStartTime, let end = firstFrameTime else { return nil }
        return end.timeIntervalSince(start)
    }
}
```

---

## 8. Performance Thresholds

```swift
public struct PerformanceThresholds: Equatable, Sendable {
    // Startup
    public let acceptableStartupTime: TimeInterval
    public let warningStartupTime: TimeInterval
    public let criticalStartupTime: TimeInterval

    // Rebuffering
    public let acceptableRebufferingRatio: Double
    public let warningRebufferingRatio: Double
    public let criticalRebufferingRatio: Double
    public let maxBufferingDuration: TimeInterval
    public let maxBufferingEventsPerMinute: Int

    // Memory
    public let warningMemoryMB: Double
    public let criticalMemoryMB: Double

    public static let `default` = PerformanceThresholds(
        acceptableStartupTime: 2.0,
        warningStartupTime: 4.0,
        criticalStartupTime: 8.0,
        acceptableRebufferingRatio: 0.01,
        warningRebufferingRatio: 0.03,
        criticalRebufferingRatio: 0.05,
        maxBufferingDuration: 10.0,
        maxBufferingEventsPerMinute: 3,
        warningMemoryMB: 150.0,
        criticalMemoryMB: 250.0
    )

    public static let strictStreaming = PerformanceThresholds(
        acceptableStartupTime: 1.5,
        warningStartupTime: 3.0,
        criticalStartupTime: 5.0,
        acceptableRebufferingRatio: 0.005,
        warningRebufferingRatio: 0.02,
        criticalRebufferingRatio: 0.03,
        maxBufferingDuration: 5.0,
        maxBufferingEventsPerMinute: 2,
        warningMemoryMB: 100.0,
        criticalMemoryMB: 200.0
    )
}
```

---

## 9. Cache Size Estimation

Methods are intentionally synchronous to avoid Swift interface generation issues
with async closures in public APIs when `BUILD_LIBRARY_FOR_DISTRIBUTION` is enabled.

```swift
public protocol ClearableCache: Sendable {
    /// Clear all cached items; returns the number of items cleared
    func clearAll() throws -> Int

    /// Estimate the current cache size in bytes (0 if unknown)
    func estimateSize() -> UInt64
}
```

---

## Key Performance Metrics

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Time to First Frame | < 2s | 2-4s | > 4s |
| Rebuffering Ratio | < 2% | 2-5% | > 5% |
| Memory Usage | < 70% | 70-85% | > 85% |
| Buffer Health | > 80% | 50-80% | < 50% |

---

## Related Documentation

- [Architecture](ARCHITECTURE.md) - Performance layer placement
- [State Machines](STATE-MACHINES.md) - Playback state tracking
- [Reactive Programming](REACTIVE-PROGRAMMING.md) - Performance publishers
- [Design Patterns](DESIGN-PATTERNS.md) - Strategy pattern for bitrate

---

## References

- [AVFoundation Programming Guide - Apple](https://developer.apple.com/documentation/avfoundation)
- [HLS Authoring Specification](https://developer.apple.com/documentation/http-live-streaming)
