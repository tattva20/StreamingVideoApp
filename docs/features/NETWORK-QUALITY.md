# Network Quality Monitoring Feature

The Network Quality Monitoring feature tracks network conditions to enable adaptive streaming quality and buffer management.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Network Quality Monitoring                 │
│                                                             │
│  NWPathMonitor ──▶ NetworkQualityMonitor ──▶ Consumers     │
│                           │                                 │
│                           │ qualityPublisher                │
│                           ▼                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  BufferManager  │  BitrateStrategy  │  Preloader     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  Quality Levels: Offline │ Poor │ Fair │ Good │ Excellent  │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Real-time Monitoring** - Continuous network status tracking
- **Quality Levels** - Five distinct quality classifications
- **Connection Type Detection** - WiFi, cellular, wired
- **Bandwidth Estimation** - Sample-based throughput estimation
- **Constrained Network Detection** - Low data mode awareness
- **Combine Integration** - Reactive quality publishing

---

## Architecture

### NetworkQuality

**File:** `StreamingCore/StreamingCore/Video Performance Feature/PerformanceEvent.swift`

```swift
public enum NetworkQuality: Int, Comparable, Sendable {
    case offline = 0
    case poor = 1
    case fair = 2
    case good = 3
    case excellent = 4

    public static func < (lhs: NetworkQuality, rhs: NetworkQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

### NetworkQualityMonitor

**File:** `StreamingCoreiOS/Video Performance iOS/NetworkQualityMonitor.swift`

```swift
import Network

@MainActor
public final class NetworkQualityMonitor {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let qualitySubject = CurrentValueSubject<NetworkQuality, Never>(.good)

    public var qualityPublisher: AnyPublisher<NetworkQuality, Never> {
        qualitySubject.eraseToAnyPublisher()
    }

    public var currentQuality: NetworkQuality {
        qualitySubject.value
    }

    public init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "NetworkQualityMonitor")
    }

    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }

    public func stopMonitoring() {
        monitor.cancel()
    }

    private func handlePathUpdate(_ path: NWPath) {
        let quality = determineQuality(from: path)
        qualitySubject.send(quality)
    }

    private func determineQuality(from path: NWPath) -> NetworkQuality {
        guard path.status == .satisfied else {
            return .offline
        }

        // Check if constrained (Low Data Mode)
        if path.isConstrained {
            return .poor
        }

        // Check if expensive (cellular)
        if path.isExpensive {
            return .fair
        }

        // Check connection type
        if path.usesInterfaceType(.wifi) {
            return .excellent
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .excellent
        } else if path.usesInterfaceType(.cellular) {
            return .good
        }

        return .fair
    }
}
```

---

## Bandwidth Estimation

### BandwidthEstimator

**File:** `StreamingCoreiOS/Video Performance iOS/NetworkBandwidthEstimator.swift`

```swift
@MainActor
public final class NetworkBandwidthEstimator {
    private var samples: [BandwidthSample] = []
    private let maxSamples: Int
    private let sampleWindow: TimeInterval

    public init(maxSamples: Int = 10, sampleWindow: TimeInterval = 30) {
        self.maxSamples = maxSamples
        self.sampleWindow = sampleWindow
    }

    public func recordSample(bytes: UInt64, duration: TimeInterval) {
        guard duration > 0 else { return }

        let bitsPerSecond = Double(bytes * 8) / duration
        let sample = BandwidthSample(
            bandwidth: bitsPerSecond,
            timestamp: Date()
        )
        samples.append(sample)
        trimOldSamples()
    }

    public func estimatedBandwidth() -> Double {
        trimOldSamples()
        guard !samples.isEmpty else { return 0 }

        // Use weighted average (newer samples weighted more)
        var weightedSum: Double = 0
        var totalWeight: Double = 0

        for (index, sample) in samples.enumerated() {
            let weight = Double(index + 1)
            weightedSum += sample.bandwidth * weight
            totalWeight += weight
        }

        return totalWeight > 0 ? weightedSum / totalWeight : 0
    }

    public func networkQuality() -> NetworkQuality {
        let bandwidth = estimatedBandwidth()

        switch bandwidth {
        case 0:
            return .offline
        case ..<500_000:      // < 500 Kbps
            return .poor
        case ..<2_000_000:    // < 2 Mbps
            return .fair
        case ..<5_000_000:    // < 5 Mbps
            return .good
        default:              // >= 5 Mbps
            return .excellent
        }
    }

    private func trimOldSamples() {
        let cutoff = Date().addingTimeInterval(-sampleWindow)
        samples = samples.filter { $0.timestamp > cutoff }

        if samples.count > maxSamples {
            samples = Array(samples.suffix(maxSamples))
        }
    }
}
```

### BandwidthSample

**File:** `StreamingCoreiOS/Video Performance iOS/BandwidthSample.swift`

```swift
public struct BandwidthSample: Sendable {
    public let bandwidth: Double  // bits per second
    public let timestamp: Date
}
```

---

## Quality Thresholds

| Quality Level | Bandwidth | Description |
|---------------|-----------|-------------|
| Offline | 0 | No connectivity |
| Poor | < 500 Kbps | Very slow, audio only |
| Fair | 500 Kbps - 2 Mbps | Low quality video |
| Good | 2 - 5 Mbps | Standard quality |
| Excellent | > 5 Mbps | HD quality |

---

## AVPlayer Performance Observer

**File:** `StreamingCoreiOS/Video Performance iOS/AVPlayerPerformanceObserver.swift`

```swift
@MainActor
public final class AVPlayerPerformanceObserver {
    private weak var player: AVPlayer?
    private let playbackStateSubject = PassthroughSubject<ObserverPlaybackState, Never>()
    private let bufferingStateSubject = PassthroughSubject<BufferingState, Never>()
    private var observers: [NSKeyValueObservation] = []

    public var playbackStatePublisher: AnyPublisher<ObserverPlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }

    public var bufferingStatePublisher: AnyPublisher<BufferingState, Never> {
        bufferingStateSubject.eraseToAnyPublisher()
    }

    public func startObserving(_ player: AVPlayer) {
        self.player = player

        // Observe time control status
        let timeControlObserver = player.observe(\.timeControlStatus) { [weak self] player, _ in
            self?.handleTimeControlStatus(player.timeControlStatus)
        }
        observers.append(timeControlObserver)

        // Observe buffer status
        if let item = player.currentItem {
            let bufferObserver = item.observe(\.isPlaybackLikelyToKeepUp) { [weak self] item, _ in
                self?.handleBufferStatus(item)
            }
            observers.append(bufferObserver)
        }
    }

    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            playbackStateSubject.send(.playing)
        case .paused:
            playbackStateSubject.send(.paused)
        case .waitingToPlayAtSpecifiedRate:
            playbackStateSubject.send(.buffering)
            bufferingStateSubject.send(.started)
        @unknown default:
            break
        }
    }

    private func handleBufferStatus(_ item: AVPlayerItem) {
        if item.isPlaybackLikelyToKeepUp {
            bufferingStateSubject.send(.ended)
        }
    }
}

public enum ObserverPlaybackState {
    case playing
    case paused
    case buffering
}

public enum BufferingState {
    case started
    case ended
}
```

---

## Integration with Other Features

### Buffer Management

```swift
networkMonitor.qualityPublisher
    .sink { [weak bufferManager] quality in
        bufferManager?.updateForNetworkQuality(quality)
    }
    .store(in: &cancellables)
```

### Bitrate Strategy

```swift
let bitrate = bitrateStrategy.initialBitrate(
    for: networkMonitor.currentQuality,
    availableLevels: availableBitrates
)
```

### Video Preloader

```swift
let videosToPreload = preloadStrategy.videosToPreload(
    currentVideoIndex: currentIndex,
    playlist: videos,
    networkQuality: networkMonitor.currentQuality
)
```

---

## Composition

```swift
// In SceneDelegate
func setupNetworkMonitoring() -> NetworkQualityMonitor {
    let networkMonitor = NetworkQualityMonitor()
    networkMonitor.startMonitoring()

    // Subscribe to quality changes
    networkMonitor.qualityPublisher
        .removeDuplicates()
        .sink { quality in
            print("Network quality changed to: \(quality)")
        }
        .store(in: &cancellables)

    return networkMonitor
}
```

---

## Testing

### Mock Network Monitor

```swift
final class NetworkQualityMonitorStub: NetworkQualityMonitor {
    private let qualitySubject = CurrentValueSubject<NetworkQuality, Never>(.good)

    override var qualityPublisher: AnyPublisher<NetworkQuality, Never> {
        qualitySubject.eraseToAnyPublisher()
    }

    func simulateQualityChange(_ quality: NetworkQuality) {
        qualitySubject.send(quality)
    }
}
```

### Bandwidth Estimator Tests

```swift
func test_estimatedBandwidth_calculatesWeightedAverage() {
    let sut = NetworkBandwidthEstimator()

    sut.recordSample(bytes: 1_000_000, duration: 1.0)  // 8 Mbps
    sut.recordSample(bytes: 2_000_000, duration: 1.0)  // 16 Mbps

    let estimated = sut.estimatedBandwidth()

    // Newer sample weighted more heavily
    XCTAssertGreaterThan(estimated, 12_000_000)
}

func test_networkQuality_returnsCorrectLevel() {
    let sut = NetworkBandwidthEstimator()

    sut.recordSample(bytes: 100_000, duration: 1.0)  // 800 Kbps

    XCTAssertEqual(sut.networkQuality(), .fair)
}
```

---

## Related Documentation

- [Buffer Management](BUFFER-MANAGEMENT.md) - Network-aware buffering
- [Video Playback](VIDEO-PLAYBACK.md) - Adaptive streaming
- [Performance](../PERFORMANCE.md) - Bitrate strategies
