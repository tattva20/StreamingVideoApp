# AVPlayer Integration Feature

The AVPlayer Integration feature provides clean abstractions over Apple's AVPlayer, bridging platform-specific events to domain-agnostic state machine actions and performance metrics.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      AVPlayer Integration Layer                         │
│                                                                         │
│  ┌─────────────────────┐                                               │
│  │      AVPlayer       │                                               │
│  │   (Platform API)    │                                               │
│  └─────────────────────┘                                               │
│           │  KVO                                                        │
│           │  Notifications                                              │
│           ▼                                                             │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                     Adapter Layer                                │  │
│  │  ┌─────────────────────┐    ┌─────────────────────────────────┐ │  │
│  │  │ AVPlayerStateAdapter│    │ AVPlayerPerformanceObserver    │ │  │
│  │  │                     │    │                                 │ │  │
│  │  │ - didBecomeReady    │    │ - playbackStatePublisher       │ │  │
│  │  │ - didStartPlaying   │    │ - bufferingStatePublisher      │ │  │
│  │  │ - didStartBuffering │    │ - performanceEventPublisher    │ │  │
│  │  │ - didFail           │    │                                 │ │  │
│  │  └─────────────────────┘    └─────────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│           │                              │                             │
│           ▼                              ▼                             │
│  ┌─────────────────────┐    ┌─────────────────────────────────────┐  │
│  │ PlaybackStateMachine│    │ Performance Monitoring              │  │
│  │   (Domain Layer)    │    │   (Analytics, Alerts)              │  │
│  └─────────────────────┘    └─────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Features

- **KVO Observation** - Monitors timeControlStatus, currentItem status
- **Notification Handling** - AVPlayerItem end/failure notifications
- **State Translation** - Converts AVPlayer states to domain actions
- **Performance Events** - Emits buffering, stall, quality events
- **Audio Interruption** - Handles AVAudioSession interruptions
- **Clean Separation** - Platform layer isolated from business logic

---

## Architecture

### AVPlayerStateAdapter

**File:** `StreamingCoreiOS/Video Playback iOS/AVPlayerStateAdapter.swift`

Bridges AVPlayer KVO observations to PlaybackAction events.

```swift
public final class AVPlayerStateAdapter: @unchecked Sendable {
    private weak var player: AVPlayer?
    private let actionHandler: @Sendable (PlaybackAction) -> Void
    private var playerObservers: [NSKeyValueObservation] = []
    private var itemObservers: [NSKeyValueObservation] = []
    private var cancellables = Set<AnyCancellable>()
    private var hasEmittedReady = false
    private var _isObserving = false

    public var isObserving: Bool { _isObserving }

    public init(player: AVPlayer, onAction: @escaping @Sendable (PlaybackAction) -> Void) {
        self.player = player
        self.actionHandler = onAction
    }
}
```

### Observation Methods

```swift
public func startObserving() {
    guard let player = player, !_isObserving else { return }
    _isObserving = true
    hasEmittedReady = false

    // Observe player time control status
    let timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
        self?.handleTimeControlStatusChange(player.timeControlStatus)
    }
    playerObservers.append(timeControlObserver)

    // Observe current item changes
    let currentItemObserver = player.observe(\.currentItem, options: [.new]) { [weak self] player, _ in
        self?.observePlayerItem(player.currentItem)
    }
    playerObservers.append(currentItemObserver)

    // Observe current item if already set
    if let currentItem = player.currentItem {
        observePlayerItem(currentItem)
    }

    setupNotificationObservers()
}

public func stopObserving() {
    _isObserving = false
    playerObservers.forEach { $0.invalidate() }
    playerObservers.removeAll()
    itemObservers.forEach { $0.invalidate() }
    itemObservers.removeAll()
    cancellables.removeAll()
}
```

---

## State Translation

### Time Control Status to Actions

```swift
private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
    switch status {
    case .playing:
        sendAction(.didStartPlaying)
    case .paused:
        sendAction(.didPause)
    case .waitingToPlayAtSpecifiedRate:
        sendAction(.didStartBuffering)
    @unknown default:
        break
    }
}
```

### Player Item Status to Actions

```swift
private func handleItemStatusChange(_ status: AVPlayerItem.Status, error: Error?) {
    switch status {
    case .readyToPlay:
        if !hasEmittedReady {
            hasEmittedReady = true
            sendAction(.didBecomeReady)
        }
    case .failed:
        let playbackError = PlaybackError.loadFailed(reason: error?.localizedDescription ?? "Unknown error")
        sendAction(.didFail(playbackError))
    case .unknown:
        break
    @unknown default:
        break
    }
}
```

### Buffer State to Actions

```swift
private func observePlayerItem(_ item: AVPlayerItem?) {
    // ... setup ...

    // Observe buffer state
    let bufferObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
        if item.isPlaybackLikelyToKeepUp {
            self?.sendAction(.didFinishBuffering)
        }
    }
    itemObservers.append(bufferObserver)

    // Setup end time notification
    NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
        .sink { [weak self] _ in
            self?.sendAction(.didReachEnd)
        }
        .store(in: &cancellables)

    // Setup failure notification
    NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item)
        .sink { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            let playbackError = PlaybackError.networkError(reason: error?.localizedDescription ?? "Playback failed")
            self?.sendAction(.didFail(playbackError))
        }
        .store(in: &cancellables)
}
```

---

## AVPlayerPerformanceObserver

**File:** `StreamingCoreiOS/Video Performance iOS/AVPlayerPerformanceObserver.swift`

Observes AVPlayer for performance metrics and emits events.

```swift
public final class AVPlayerPerformanceObserver: @unchecked Sendable {
    private weak var player: AVPlayer?
    private var playerObservers: [NSKeyValueObservation] = []
    private var itemObservers: [NSKeyValueObservation] = []
    private var bufferingStartTime: Date?

    private let playbackStateSubject = CurrentValueSubject<ObserverPlaybackState, Never>(.idle)
    private let bufferingStateSubject = CurrentValueSubject<BufferingState, Never>(.unknown)
    private let performanceEventSubject = PassthroughSubject<PerformanceEvent, Never>()

    public var playbackStatePublisher: AnyPublisher<ObserverPlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }

    public var bufferingStatePublisher: AnyPublisher<BufferingState, Never> {
        bufferingStateSubject.eraseToAnyPublisher()
    }

    public var performanceEventPublisher: AnyPublisher<PerformanceEvent, Never> {
        performanceEventSubject.eraseToAnyPublisher()
    }
}
```

### Observer States

```swift
public enum ObserverPlaybackState: Equatable, Sendable {
    case idle
    case playing
    case paused
    case buffering
    case stalled
    case failed(Error)
}

public enum BufferingState: Equatable, Sendable {
    case unknown
    case buffering
    case ready
    case stalled
}
```

### Performance Events

```swift
public enum PerformanceEvent: Equatable, Sendable {
    case loadStarted
    case firstFrameRendered
    case bufferingStarted
    case bufferingEnded(duration: TimeInterval)
    case playbackStalled
    case playbackResumed
    case qualityChanged(bitrate: Int)
    case memoryWarning(level: MemoryPressureLevel)
    case networkChanged(quality: NetworkQuality)
    case bytesTransferred(bytes: Int64, duration: TimeInterval)
}
```

---

## KVO Properties Observed

### AVPlayer Properties

| Property | Use | Emits |
|----------|-----|-------|
| `timeControlStatus` | Play/pause/buffering state | `.didStartPlaying`, `.didPause`, `.didStartBuffering` |
| `currentItem` | Item changes | Triggers item observation |

### AVPlayerItem Properties

| Property | Use | Emits |
|----------|-----|-------|
| `status` | Ready/failed state | `.didBecomeReady`, `.didFail` |
| `isPlaybackLikelyToKeepUp` | Buffer ready | `.didFinishBuffering` |
| `isPlaybackBufferEmpty` | Buffer empty | `.bufferingStarted` |
| `isPlaybackBufferFull` | Buffer full | `.ready` |

### Notifications

| Notification | Use | Emits |
|-------------|-----|-------|
| `AVPlayerItemDidPlayToEndTime` | End of video | `.didReachEnd` |
| `AVPlayerItemFailedToPlayToEndTime` | Playback failure | `.didFail` |
| `AVAudioSession.interruptionNotification` | Phone calls, etc. | `.audioSessionInterrupted` |

---

## Usage Example

### State Machine Integration

```swift
@MainActor
func setupPlayer() -> AVPlayer {
    let player = AVPlayer()
    let stateMachine = DefaultPlaybackStateMachine()

    let adapter = AVPlayerStateAdapter(player: player) { [weak stateMachine] action in
        Task { @MainActor in
            stateMachine?.send(action)
        }
    }
    adapter.startObserving()

    return player
}
```

### Performance Monitoring Integration

```swift
@MainActor
func setupPerformanceMonitoring(player: AVPlayer) {
    let observer = AVPlayerPerformanceObserver(player: player)
    observer.startObserving()

    observer.performanceEventPublisher
        .sink { event in
            switch event {
            case .loadStarted:
                startupTracker.recordLoadStart()

            case .firstFrameRendered:
                startupTracker.recordFirstFrame()

            case .bufferingStarted:
                rebufferingMonitor.bufferingStarted()

            case .bufferingEnded(let duration):
                rebufferingMonitor.bufferingEnded()
                analytics.track(.bufferingEnded(duration: duration))

            default:
                break
            }
        }
        .store(in: &cancellables)
}
```

---

## Simulation Methods (Testing)

The adapter provides simulation methods for testing without a real AVPlayer:

```swift
// Simulate player becoming ready
public func simulatePlayerItemReady() async {
    sendAction(.didBecomeReady)
}

// Simulate playback started
public func simulatePlaybackStarted() async {
    sendAction(.didStartPlaying)
}

// Simulate buffering
public func simulateBufferingStarted() async {
    sendAction(.didStartBuffering)
}

public func simulateBufferingEnded() async {
    sendAction(.didFinishBuffering)
}

// Simulate playback end
public func simulatePlaybackEnded() async {
    sendAction(.didReachEnd)
}

// Simulate failure
public func simulatePlaybackFailed(error: Error) async {
    let playbackError = PlaybackError.loadFailed(reason: error.localizedDescription)
    sendAction(.didFail(playbackError))
}
```

---

## Testing

### Adapter Tests

```swift
func test_startObserving_setsIsObservingTrue() {
    let player = AVPlayer()
    let sut = AVPlayerStateAdapter(player: player, onAction: { _ in })

    sut.startObserving()

    XCTAssertTrue(sut.isObserving)
}

func test_stopObserving_setsIsObservingFalse() {
    let player = AVPlayer()
    let sut = AVPlayerStateAdapter(player: player, onAction: { _ in })
    sut.startObserving()

    sut.stopObserving()

    XCTAssertFalse(sut.isObserving)
}

func test_simulatePlayerItemReady_sendsDidBecomeReady() async {
    var receivedActions: [PlaybackAction] = []
    let player = AVPlayer()
    let sut = AVPlayerStateAdapter(player: player) { action in
        receivedActions.append(action)
    }

    await sut.simulatePlayerItemReady()

    XCTAssertEqual(receivedActions, [.didBecomeReady])
}
```

### Performance Observer Tests

```swift
func test_performanceEventPublisher_emitsLoadStarted() {
    let player = AVPlayer()
    let sut = AVPlayerPerformanceObserver(player: player)
    var events: [PerformanceEvent] = []

    let cancellable = sut.performanceEventPublisher
        .sink { events.append($0) }

    // Trigger new item observation (internally emits .loadStarted)
    player.replaceCurrentItem(with: AVPlayerItem(url: anyURL()))
    sut.startObserving()

    // Verify loadStarted was emitted
    XCTAssertTrue(events.contains(.loadStarted))
}
```

---

## Architecture Benefits

### Clean Architecture Compliance

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer                                          │
│   VideoPlayerViewController                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Domain Layer                                                │
│   PlaybackStateMachine (pure, testable)                    │
│   PerformanceService (platform-agnostic)                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Infrastructure Layer (Adapters)                             │
│   AVPlayerStateAdapter (AVPlayer → PlaybackAction)         │
│   AVPlayerPerformanceObserver (AVPlayer → PerformanceEvent)│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Platform Layer                                              │
│   AVPlayer, AVPlayerItem, AVAudioSession                   │
└─────────────────────────────────────────────────────────────┘
```

This separation enables:
- Unit testing domain logic without AVPlayer
- Swapping player implementations (AVPlayer → custom)
- Platform-agnostic business rules
- Isolated platform-specific bug fixes

---

## Related Documentation

- [Player State Machine](PLAYER-STATE-MACHINE.md) - Domain state management
- [Audio Session](AUDIO-SESSION.md) - Audio configuration
- [Rebuffering Detection](REBUFFERING-DETECTION.md) - Stall monitoring
- [Startup Performance](STARTUP-PERFORMANCE.md) - TTFF tracking
