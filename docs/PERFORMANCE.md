# Performance Optimization in StreamingVideoApp

This document explains the performance strategies, monitoring systems, and optimization patterns used in the StreamingVideoApp.

---

## Overview

StreamingVideoApp implements several performance optimization strategies:
- Adaptive bitrate selection
- Predictive video preloading
- Intelligent buffer management
- Memory pressure handling
- Performance monitoring and alerts

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
public final class AdaptiveBufferManager {
    private let configurationSubject = CurrentValueSubject<BufferConfiguration, Never>(.default)

    public func recalculateConfiguration(memory: MemoryState, network: NetworkQuality) {
        var config = BufferConfiguration.default

        // Memory pressure takes precedence
        if memory.pressure == .critical {
            config = .minimal
        } else if memory.pressure == .warning {
            config = .reduced
        } else {
            // Adjust for network
            switch network {
            case .excellent: config = .generous
            case .good: config = .default
            case .fair: config = .reduced
            case .poor, .offline: config = .minimal
            }
        }

        configurationSubject.send(config)
    }
}
```

### BufferConfiguration

```swift
public struct BufferConfiguration: Equatable, Sendable {
    public let preferredForwardDuration: TimeInterval
    public let minimumForwardDuration: TimeInterval
    public let maximumBufferSize: UInt64

    public static let `default` = BufferConfiguration(
        preferredForwardDuration: 30,
        minimumForwardDuration: 5,
        maximumBufferSize: 50_000_000
    )

    public static let minimal = BufferConfiguration(
        preferredForwardDuration: 10,
        minimumForwardDuration: 2,
        maximumBufferSize: 20_000_000
    )
}
```

---

## 4. Memory Management

### MemoryMonitor Protocol

```swift
@MainActor
public protocol MemoryMonitor: AnyObject {
    var statePublisher: AnyPublisher<MemoryState, Never> { get }
    func currentMemoryState() -> MemoryState
    func startMonitoring()
    func stopMonitoring()
}
```

### MemoryState

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
}
```

### ResourceCleanupCoordinator

Prioritized cleanup based on memory pressure:

```swift
@MainActor
public final class ResourceCleanupCoordinator {
    private var cleaners: [(cleaner: ResourceCleaner, priority: CleanupPriority)] = []

    public func enableAutoCleanup() {
        memoryMonitor.statePublisher
            .sink { [weak self] state in
                Task { await self?.handleMemoryPressure(state.pressure) }
            }
            .store(in: &cancellables)
    }

    private func handleMemoryPressure(_ pressure: MemoryPressure) async {
        switch pressure {
        case .critical:
            await cleanupAll()
        case .warning:
            await cleanupUpTo(priority: .medium)
        case .normal:
            break
        }
    }

    public func cleanupUpTo(priority: CleanupPriority) async {
        let toClean = cleaners.filter { $0.priority <= priority }
        for (cleaner, _) in toClean {
            await cleaner.cleanup()
        }
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
    public let memoryPressure: MemoryPressure

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

```swift
public enum PerformanceAlert: Equatable, Sendable {
    case slowStartup(duration: TimeInterval)
    case excessiveBuffering(ratio: Double)
    case memoryWarning(available: UInt64)
    case memoryCritical(available: UInt64)
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

### BandwidthEstimator

```swift
public final class BandwidthEstimator {
    private var samples: [BandwidthSample] = []

    public func recordSample(bytes: UInt64, duration: TimeInterval) {
        let bitsPerSecond = Double(bytes * 8) / duration
        samples.append(BandwidthSample(bandwidth: bitsPerSecond, timestamp: Date()))
        trimOldSamples()
    }

    public func estimatedBandwidth() -> Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.bandwidth).reduce(0, +) / Double(samples.count)
    }

    public func networkQuality() -> NetworkQuality {
        let bandwidth = estimatedBandwidth()
        switch bandwidth {
        case 0: return .offline
        case ..<500_000: return .poor
        case ..<2_000_000: return .fair
        case ..<5_000_000: return .good
        default: return .excellent
        }
    }
}
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
    public let acceptableStartupTime: TimeInterval
    public let warningStartupTime: TimeInterval
    public let criticalStartupTime: TimeInterval
    public let acceptableRebufferingRatio: Double

    public static let `default` = PerformanceThresholds(
        acceptableStartupTime: 2.0,
        warningStartupTime: 4.0,
        criticalStartupTime: 8.0,
        acceptableRebufferingRatio: 0.02
    )

    public static let strictStreaming = PerformanceThresholds(
        acceptableStartupTime: 1.5,
        warningStartupTime: 3.0,
        criticalStartupTime: 5.0,
        acceptableRebufferingRatio: 0.01
    )
}
```

---

## 9. Cache Size Estimation

```swift
public protocol ClearableCache: AnyObject {
    func clearAllCaches() async
    func estimateCacheSize() async -> UInt64
}

extension CoreDataVideoStore: ClearableCache {
    public func estimateCacheSize() async -> UInt64 {
        // Calculate total size of cached videos and images
    }
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
