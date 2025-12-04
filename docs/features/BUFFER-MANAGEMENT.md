# Buffer Management Feature

The Buffer Management feature provides adaptive buffering that adjusts to network conditions and memory pressure for optimal playback performance.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Adaptive Buffer Management                  │
│                                                             │
│  Network Monitor ──┐                                        │
│                    │     ┌──────────────────┐               │
│                    ├────▶│ AdaptiveBuffer   │──▶ AVPlayer   │
│                    │     │   Manager        │               │
│  Memory Monitor ───┘     └──────────────────┘               │
│                                                             │
│  Strategies: Minimal │ Conservative │ Balanced │ Aggressive │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Adaptive Buffering** - Adjust buffer size based on conditions
- **Memory-Aware** - Reduce buffer during memory pressure
- **Network-Aware** - Increase buffer for poor networks
- **Strategy Pattern** - Swappable buffering strategies
- **Real-time Updates** - Continuous monitoring and adjustment
- **Combine Integration** - Reactive configuration publishing

---

## Architecture

### BufferManager Protocol

**File:** `StreamingCore/StreamingCore/Buffer Management Feature/BufferManager.swift`

```swift
@MainActor
public protocol BufferManager: AnyObject {
    var configuration: BufferConfiguration { get }
    var configurationPublisher: AnyPublisher<BufferConfiguration, Never> { get }

    func updateForMemoryState(_ state: MemoryState)
    func updateForNetworkQuality(_ quality: NetworkQuality)
}
```

### BufferConfiguration

**File:** `StreamingCore/StreamingCore/Buffer Management Feature/Domain/BufferConfiguration.swift`

```swift
public struct BufferConfiguration: Equatable, Sendable {
    public let preferredForwardBufferDuration: TimeInterval
    public let minimumForwardBufferDuration: TimeInterval
    public let maximumBufferSize: UInt64

    public static let minimal = BufferConfiguration(
        preferredForwardBufferDuration: 5,
        minimumForwardBufferDuration: 2,
        maximumBufferSize: 10_000_000  // 10 MB
    )

    public static let conservative = BufferConfiguration(
        preferredForwardBufferDuration: 15,
        minimumForwardBufferDuration: 5,
        maximumBufferSize: 30_000_000  // 30 MB
    )

    public static let balanced = BufferConfiguration(
        preferredForwardBufferDuration: 30,
        minimumForwardBufferDuration: 10,
        maximumBufferSize: 50_000_000  // 50 MB
    )

    public static let aggressive = BufferConfiguration(
        preferredForwardBufferDuration: 60,
        minimumForwardBufferDuration: 20,
        maximumBufferSize: 100_000_000  // 100 MB
    )
}
```

### BufferStrategy

**File:** `StreamingCore/StreamingCore/Buffer Management Feature/Domain/BufferStrategy.swift`

```swift
public enum BufferStrategy: String, Sendable {
    case minimal      // Critical memory or offline
    case conservative // Poor network or warning memory
    case balanced     // Normal conditions
    case aggressive   // Good network and plenty of memory

    public var configuration: BufferConfiguration {
        switch self {
        case .minimal: return .minimal
        case .conservative: return .conservative
        case .balanced: return .balanced
        case .aggressive: return .aggressive
        }
    }
}
```

---

## AdaptiveBufferManager

**File:** `StreamingCore/StreamingCore/Buffer Management Feature/AdaptiveBufferManager.swift`

```swift
@MainActor
public final class AdaptiveBufferManager: BufferManager {
    private let configurationSubject: CurrentValueSubject<BufferConfiguration, Never>
    private var memoryState: MemoryState = .normal
    private var networkQuality: NetworkQuality = .good

    public var configuration: BufferConfiguration {
        configurationSubject.value
    }

    public var configurationPublisher: AnyPublisher<BufferConfiguration, Never> {
        configurationSubject.eraseToAnyPublisher()
    }

    public init(initialConfiguration: BufferConfiguration = .balanced) {
        self.configurationSubject = CurrentValueSubject(initialConfiguration)
    }

    public func updateForMemoryState(_ state: MemoryState) {
        memoryState = state
        recalculateConfiguration()
    }

    public func updateForNetworkQuality(_ quality: NetworkQuality) {
        networkQuality = quality
        recalculateConfiguration()
    }

    private func recalculateConfiguration() {
        let strategy = determineStrategy()
        configurationSubject.send(strategy.configuration)
    }

    private func determineStrategy() -> BufferStrategy {
        // Memory pressure takes precedence
        switch memoryState.pressure {
        case .critical:
            return .minimal
        case .warning:
            return .conservative
        case .normal:
            break
        }

        // Then consider network
        switch networkQuality {
        case .offline, .poor:
            return .conservative
        case .fair:
            return .balanced
        case .good, .excellent:
            return .aggressive
        }
    }
}
```

---

## Strategy Selection Matrix

| Memory Pressure | Network Quality | Strategy |
|-----------------|-----------------|----------|
| Critical | Any | Minimal |
| Warning | Any | Conservative |
| Normal | Offline/Poor | Conservative |
| Normal | Fair | Balanced |
| Normal | Good/Excellent | Aggressive |

---

## AVPlayer Integration

### AVPlayerBufferAdapter

**File:** `StreamingVideoApp/AVPlayerBufferAdapter.swift`

```swift
@MainActor
public final class AVPlayerBufferAdapter {
    private weak var playerItem: AVPlayerItem?
    private var cancellables = Set<AnyCancellable>()

    public init(playerItem: AVPlayerItem, bufferManager: BufferManager) {
        self.playerItem = playerItem

        bufferManager.configurationPublisher
            .removeDuplicates()
            .sink { [weak self] configuration in
                self?.applyConfiguration(configuration)
            }
            .store(in: &cancellables)
    }

    private func applyConfiguration(_ configuration: BufferConfiguration) {
        playerItem?.preferredForwardBufferDuration = configuration.preferredForwardBufferDuration
    }
}
```

---

## Monitoring Integration

### Complete Flow

```swift
// In VideoPlayerComposer
func setupBufferManagement(
    player: AVPlayer,
    memoryMonitor: MemoryMonitor,
    networkMonitor: NetworkQualityMonitor
) {
    let bufferManager = AdaptiveBufferManager()

    // Subscribe to memory changes
    memoryMonitor.statePublisher
        .sink { [weak bufferManager] state in
            bufferManager?.updateForMemoryState(state)
        }
        .store(in: &cancellables)

    // Subscribe to network changes
    networkMonitor.qualityPublisher
        .sink { [weak bufferManager] quality in
            bufferManager?.updateForNetworkQuality(quality)
        }
        .store(in: &cancellables)

    // Apply to player
    if let playerItem = player.currentItem {
        let adapter = AVPlayerBufferAdapter(
            playerItem: playerItem,
            bufferManager: bufferManager
        )
    }
}
```

---

## Configuration Values

### Minimal (Memory Critical)

```swift
preferredForwardBufferDuration: 5 seconds
minimumForwardBufferDuration: 2 seconds
maximumBufferSize: 10 MB
```

Use when:
- Memory pressure is critical
- Device is low on resources

### Conservative (Poor Network/Warning Memory)

```swift
preferredForwardBufferDuration: 15 seconds
minimumForwardBufferDuration: 5 seconds
maximumBufferSize: 30 MB
```

Use when:
- Network is poor or offline
- Memory pressure is warning

### Balanced (Normal Conditions)

```swift
preferredForwardBufferDuration: 30 seconds
minimumForwardBufferDuration: 10 seconds
maximumBufferSize: 50 MB
```

Use when:
- Network is fair
- Memory is normal

### Aggressive (Optimal Conditions)

```swift
preferredForwardBufferDuration: 60 seconds
minimumForwardBufferDuration: 20 seconds
maximumBufferSize: 100 MB
```

Use when:
- Network is good/excellent
- Memory is plentiful

---

## State Transitions

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  Memory: Normal, Network: Good                               │
│  ──▶ Strategy: Aggressive (60s buffer)                       │
│                                                              │
│  Memory: Normal, Network: Poor                               │
│  ──▶ Strategy: Conservative (15s buffer)                     │
│                                                              │
│  Memory: Warning, Network: Any                               │
│  ──▶ Strategy: Conservative (15s buffer)                     │
│                                                              │
│  Memory: Critical, Network: Any                              │
│  ──▶ Strategy: Minimal (5s buffer)                           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Testing

### Unit Tests

```swift
@MainActor
func test_updateForMemoryState_critical_switchesToMinimal() {
    let sut = AdaptiveBufferManager(initialConfiguration: .aggressive)

    sut.updateForMemoryState(MemoryState(pressure: .critical))

    XCTAssertEqual(sut.configuration, .minimal)
}

@MainActor
func test_updateForNetworkQuality_poor_switchesToConservative() {
    let sut = AdaptiveBufferManager(initialConfiguration: .aggressive)

    sut.updateForNetworkQuality(.poor)

    XCTAssertEqual(sut.configuration, .conservative)
}

@MainActor
func test_memoryPressure_takesPrecedenceOverNetwork() {
    let sut = AdaptiveBufferManager()

    sut.updateForNetworkQuality(.excellent)
    sut.updateForMemoryState(MemoryState(pressure: .critical))

    XCTAssertEqual(sut.configuration, .minimal)
}
```

### Publisher Tests

```swift
@MainActor
func test_configurationPublisher_emitsChanges() {
    let sut = AdaptiveBufferManager()
    var receivedConfigs: [BufferConfiguration] = []

    let cancellable = sut.configurationPublisher
        .sink { receivedConfigs.append($0) }

    sut.updateForNetworkQuality(.poor)
    sut.updateForNetworkQuality(.excellent)

    XCTAssertEqual(receivedConfigs.count, 3)  // Initial + 2 changes
}
```

---

## Related Documentation

- [Video Playback](VIDEO-PLAYBACK.md) - Player integration
- [Memory Management](MEMORY-MANAGEMENT.md) - Memory monitoring
- [Network Quality](NETWORK-QUALITY.md) - Network monitoring
- [Performance](../PERFORMANCE.md) - Performance optimization
