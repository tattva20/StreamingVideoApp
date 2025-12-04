# Player State Machine Feature

The Player State Machine provides a robust, predictable way to manage video player states with explicit, testable transitions.

---

## Overview

```
                              ┌─────────────────────────────────────────────────────────┐
                              │              Playback State Machine                     │
                              │                                                         │
                              │   ┌──────┐  load   ┌─────────┐  ready  ┌───────┐      │
                              │   │ idle │ ──────▶ │ loading │ ──────▶ │ ready │      │
                              │   └──────┘         └─────────┘         └───────┘      │
                              │      ▲                   │                  │          │
                              │      │ stop              │ fail          play│          │
                              │      │                   ▼                  ▼          │
                              │      │              ┌────────┐        ┌─────────┐     │
                              │      ├───────────── │ failed │        │ playing │     │
                              │      │              └────────┘        └─────────┘     │
                              │      │                   ▲                │   │        │
                              │      │                   │              pause│ buffer │
                              │      │                   │                │   │        │
                              │      │  ┌────────────────┼────────────────┘   │        │
                              │      │  │                │                    ▼        │
                              │      │  ▼                │              ┌───────────┐  │
                              │   ┌────────┐    end  ┌───────┐         │ buffering │  │
                              │   │ paused │ ◀───── │ ended  │         └───────────┘  │
                              │   └────────┘         └───────┘                        │
                              └─────────────────────────────────────────────────────────┘
```

---

## Features

- **Explicit State Definitions** - Nine distinct states with clear semantics
- **Type-Safe Transitions** - Compile-time enforced transition rules
- **Resumable States** - Buffering/seeking preserve previous state for restoration
- **Action Categorization** - User, system, and external action separation
- **Transition History** - Full audit trail of state changes
- **Combine Integration** - Reactive state and transition publishers
- **Thread Safety** - @MainActor isolation for predictable behavior

---

## Architecture

### PlaybackState

**File:** `StreamingCore/StreamingCore/Video Playback Feature/PlaybackState.swift`

```swift
public enum PlaybackState: Equatable, Sendable, CustomStringConvertible {
    case idle
    case loading(URL)
    case ready
    case playing
    case paused
    case buffering(previousState: ResumableState)
    case seeking(to: TimeInterval, previousState: ResumableState)
    case ended
    case failed(PlaybackError)

    /// States that can be resumed after buffering or seeking completes
    public enum ResumableState: Equatable, Sendable {
        case playing
        case paused
    }
}
```

### State Properties

```swift
/// Whether playback is conceptually "active" (for analytics tracking)
public var isActive: Bool {
    switch self {
    case .playing:
        return true
    case .buffering(let previousState):
        return previousState == .playing
    case .seeking(_, let previousState):
        return previousState == .playing
    default:
        return false
    }
}

/// Whether the player can receive play commands
public var canPlay: Bool {
    switch self {
    case .ready, .paused, .ended:
        return true
    default:
        return false
    }
}

/// Whether the player can receive pause commands
public var canPause: Bool {
    switch self {
    case .playing:
        return true
    case .buffering(let previousState):
        return previousState == .playing
    default:
        return false
    }
}
```

---

## PlaybackAction

**File:** `StreamingCore/StreamingCore/Video Playback Feature/PlaybackAction.swift`

```swift
public enum PlaybackAction: Equatable, Sendable {
    // MARK: - User-Initiated Actions
    case load(URL)
    case play
    case pause
    case seek(to: TimeInterval)
    case stop
    case retry

    // MARK: - System Events
    case didBecomeReady
    case didStartPlaying
    case didPause
    case didStartBuffering
    case didFinishBuffering
    case didStartSeeking
    case didFinishSeeking
    case didReachEnd
    case didFail(PlaybackError)

    // MARK: - External Events
    case didEnterBackground
    case didBecomeActive
    case audioSessionInterrupted
    case audioSessionResumed
}
```

---

## PlaybackTransition

**File:** `StreamingCore/StreamingCore/Video Playback Feature/PlaybackTransition.swift`

```swift
public struct PlaybackTransition: Equatable, Sendable {
    public let from: PlaybackState
    public let to: PlaybackState
    public let action: PlaybackAction
    public let timestamp: Date

    /// Whether this transition actually changed the state
    public var didChangeState: Bool {
        from != to
    }
}
```

---

## DefaultPlaybackStateMachine

**File:** `StreamingCore/StreamingCore/Video Playback Feature/DefaultPlaybackStateMachine.swift`

```swift
@MainActor
public final class DefaultPlaybackStateMachine {
    private var _currentState: PlaybackState = .idle
    private let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
    private let transitionSubject = PassthroughSubject<PlaybackTransition, Never>()

    /// The current playback state
    public var currentState: PlaybackState {
        stateSubject.value
    }

    /// Publisher that emits the current state and all future state changes
    public var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    /// Publisher that emits only state transitions
    public var transitionPublisher: AnyPublisher<PlaybackTransition, Never> {
        transitionSubject.eraseToAnyPublisher()
    }

    /// Sends an action to the state machine and returns the resulting transition
    @discardableResult
    public func send(_ action: PlaybackAction) -> PlaybackTransition? {
        guard let nextState = nextState(for: action, from: _currentState) else {
            return nil
        }

        let transition = PlaybackTransition(
            from: _currentState,
            to: nextState,
            action: action,
            timestamp: currentDate()
        )

        _currentState = nextState
        stateSubject.send(nextState)
        transitionSubject.send(transition)

        return transition
    }

    /// Checks if an action can be performed without actually performing it
    public func canPerform(_ action: PlaybackAction) -> Bool {
        nextState(for: action, from: _currentState) != nil
    }
}
```

---

## State Transition Table

### From Idle

| Action | Next State |
|--------|------------|
| `load(url)` | `loading(url)` |

### From Loading

| Action | Next State |
|--------|------------|
| `didBecomeReady` | `ready` |
| `didFail(error)` | `failed(error)` |
| `stop` | `idle` |

### From Ready

| Action | Next State |
|--------|------------|
| `play` | `playing` |
| `stop` | `idle` |
| `load(url)` | `loading(url)` |

### From Playing

| Action | Next State |
|--------|------------|
| `pause` | `paused` |
| `didStartBuffering` | `buffering(previousState: .playing)` |
| `seek(to: time)` | `seeking(to: time, previousState: .playing)` |
| `didReachEnd` | `ended` |
| `didFail(error)` | `failed(error)` |
| `stop` | `idle` |
| `didEnterBackground` | `paused` |
| `audioSessionInterrupted` | `paused` |

### From Paused

| Action | Next State |
|--------|------------|
| `play` | `playing` |
| `didStartBuffering` | `buffering(previousState: .paused)` |
| `seek(to: time)` | `seeking(to: time, previousState: .paused)` |
| `stop` | `idle` |
| `load(url)` | `loading(url)` |
| `audioSessionResumed` | `playing` |

### From Buffering

| Action | Next State |
|--------|------------|
| `didFinishBuffering` | `playing` or `paused` (based on previousState) |
| `pause` | `buffering(previousState: .paused)` |
| `play` | `buffering(previousState: .playing)` |
| `didFail(error)` | `failed(error)` |
| `stop` | `idle` |

### From Seeking

| Action | Next State |
|--------|------------|
| `didFinishSeeking` | `playing` or `paused` (based on previousState) |
| `pause` | `seeking(to: time, previousState: .paused)` |
| `play` | `seeking(to: time, previousState: .playing)` |
| `didFail(error)` | `failed(error)` |
| `stop` | `idle` |

### From Ended

| Action | Next State |
|--------|------------|
| `play` | `playing` |
| `seek(to: time)` | `seeking(to: time, previousState: .paused)` |
| `stop` | `idle` |
| `load(url)` | `loading(url)` |

### From Failed

| Action | Next State |
|--------|------------|
| `retry` (if recoverable) | `idle` |
| `stop` | `idle` |
| `load(url)` | `loading(url)` |

---

## PlaybackError

**File:** `StreamingCore/StreamingCore/Video Playback Feature/PlaybackError.swift`

```swift
public enum PlaybackError: Error, Equatable, Sendable {
    case loadFailed(reason: String)
    case networkError(reason: String)
    case decodingError(reason: String)
    case drmError(reason: String)
    case unknown(reason: String)

    /// Whether this error can be recovered from by retrying
    public var isRecoverable: Bool {
        switch self {
        case .networkError:
            return true
        default:
            return false
        }
    }
}
```

---

## Usage Example

```swift
@MainActor
func setupPlayer() {
    let stateMachine = DefaultPlaybackStateMachine()

    // Subscribe to state changes
    stateMachine.statePublisher
        .sink { state in
            updateUI(for: state)
        }
        .store(in: &cancellables)

    // Subscribe to transitions for analytics
    stateMachine.transitionPublisher
        .sink { transition in
            analytics.track(transition)
        }
        .store(in: &cancellables)

    // Send actions
    stateMachine.send(.load(videoURL))
    // After system event...
    stateMachine.send(.didBecomeReady)
    stateMachine.send(.play)
}
```

---

## Integration with AVPlayer

The `AVPlayerStateAdapter` bridges AVPlayer events to state machine actions:

```swift
let adapter = AVPlayerStateAdapter(player: avPlayer) { action in
    Task { @MainActor in
        stateMachine.send(action)
    }
}
adapter.startObserving()
```

---

## Testing

### Unit Tests

```swift
@MainActor
func test_send_load_transitionsFromIdleToLoading() {
    let sut = DefaultPlaybackStateMachine()
    let url = URL(string: "https://example.com/video.mp4")!

    let transition = sut.send(.load(url))

    XCTAssertEqual(sut.currentState, .loading(url))
    XCTAssertEqual(transition?.from, .idle)
    XCTAssertEqual(transition?.to, .loading(url))
}

@MainActor
func test_send_invalidAction_returnsNilAndKeepsState() {
    let sut = DefaultPlaybackStateMachine()

    let transition = sut.send(.play) // Invalid from idle

    XCTAssertNil(transition)
    XCTAssertEqual(sut.currentState, .idle)
}

@MainActor
func test_buffering_preservesPreviousState() {
    let sut = DefaultPlaybackStateMachine()
    sut.send(.load(URL(string: "https://example.com")!))
    sut.send(.didBecomeReady)
    sut.send(.play)

    sut.send(.didStartBuffering)

    XCTAssertEqual(sut.currentState, .buffering(previousState: .playing))
}
```

---

## Related Documentation

- [Video Playback](VIDEO-PLAYBACK.md) - Player integration
- [AVPlayer Integration](AVPLAYER-INTEGRATION.md) - Platform adapter
- [State Machines](../STATE-MACHINES.md) - Design pattern details
- [Analytics](ANALYTICS.md) - Transition tracking
