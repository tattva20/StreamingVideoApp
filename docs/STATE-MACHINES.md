# State Machine Design in StreamingVideoApp

This document explains the pure state machine implementation used for video playback control, demonstrating how functional programming principles create predictable, testable state management.

---

## Overview

The playback system uses a **finite state machine (FSM)** with:
- **Immutable state values** (enums)
- **Pure state transition functions**
- **Reactive state publishing**
- **Complete testability**

```
┌─────────────────────────────────────────────────────────────┐
│                     Playback State Machine                  │
│                                                             │
│   ┌───────┐    load    ┌─────────┐   ready   ┌───────┐     │
│   │ idle  │───────────▶│ loading │──────────▶│ ready │     │
│   └───────┘            └─────────┘           └───────┘     │
│       ▲                     │                    │         │
│       │                     │ fail               │ play    │
│       │ stop                ▼                    ▼         │
│       │                ┌─────────┐          ┌─────────┐    │
│       └────────────────│ failed  │          │ playing │    │
│       │                └─────────┘          └─────────┘    │
│       │                                          │         │
│       │                                          │ pause   │
│       │                                          ▼         │
│       │                                     ┌─────────┐    │
│       └─────────────────────────────────────│ paused  │    │
│                                             └─────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. PlaybackState - Immutable State Enum

**File:** `StreamingCore/StreamingCore/Video Playback Feature/PlaybackState.swift`

```swift
public enum PlaybackState: Equatable, Sendable {
    case idle
    case loading(URL)
    case ready
    case playing
    case paused
    case buffering(previousState: ResumableState)
    case seeking(to: TimeInterval, previousState: ResumableState)
    case ended
    case failed(PlaybackError)

    public enum ResumableState: Equatable, Sendable {
        case playing
        case paused
    }
}
```

**Key Design Decisions:**

1. **Associated Values** - `loading(URL)` captures the loading URL
2. **Previous State Tracking** - `buffering` and `seeking` remember what state to return to
3. **Sendable Conformance** - Safe to pass across actor boundaries
4. **Equatable** - Enables testing with `XCTAssertEqual`

### Pure Computed Properties

```swift
extension PlaybackState {
    public var isActive: Bool {
        switch self {
        case .playing:
            return true
        case .buffering(let previousState), .seeking(_, let previousState):
            return previousState == .playing
        default:
            return false
        }
    }

    public var canPlay: Bool {
        switch self {
        case .ready, .paused, .ended:
            return true
        default:
            return false
        }
    }

    public var canPause: Bool {
        switch self {
        case .playing, .buffering(.playing), .seeking(_, .playing):
            return true
        default:
            return false
        }
    }
}
```

---

### 2. PlaybackAction - Command Enum

**File:** `StreamingCore/StreamingCore/Video Playback Feature/PlaybackAction.swift`

```swift
public enum PlaybackAction: Equatable, Sendable {
    // User-Initiated Actions
    case load(URL)
    case play
    case pause
    case seek(to: TimeInterval)
    case stop
    case retry

    // System Events
    case didBecomeReady
    case didStartPlaying
    case didPause
    case didStartBuffering
    case didFinishBuffering
    case didStartSeeking
    case didFinishSeeking
    case didReachEnd
    case didFail(PlaybackError)

    // External Events
    case didEnterBackground
    case didBecomeActive
    case audioSessionInterrupted
    case audioSessionResumed
}
```

**Categorization:**
- **User Actions** - Triggered by user interaction (play, pause, seek)
- **System Events** - Triggered by AVPlayer observations (didBecomeReady)
- **External Events** - App lifecycle and audio session events

---

### 3. PlaybackTransition - State Change Record

**File:** `StreamingCore/StreamingCore/Video Playback Feature/PlaybackTransition.swift`

```swift
public struct PlaybackTransition: Equatable, Sendable {
    public let from: PlaybackState
    public let to: PlaybackState
    public let action: PlaybackAction
    public let timestamp: Date

    public var didChangeState: Bool {
        from != to
    }
}
```

**Use Cases:**
- Debugging and logging state changes
- Analytics tracking
- Undo/replay functionality

---

### 4. DefaultPlaybackStateMachine - Pure Transitions

**File:** `StreamingCore/StreamingCore/Video Playback Feature/DefaultPlaybackStateMachine.swift`

```swift
@MainActor
public final class DefaultPlaybackStateMachine {
    private var _currentState: PlaybackState = .idle
    private let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
    private let transitionSubject = PassthroughSubject<PlaybackTransition, Never>()
    private let currentDate: () -> Date  // Injected as function!

    public var currentState: PlaybackState { _currentState }
    public var statePublisher: AnyPublisher<PlaybackState, Never> { stateSubject.eraseToAnyPublisher() }
    public var transitionPublisher: AnyPublisher<PlaybackTransition, Never> { transitionSubject.eraseToAnyPublisher() }

    public init(currentDate: @escaping () -> Date = { Date() }) {
        self.currentDate = currentDate
    }

    public func send(_ action: PlaybackAction) -> PlaybackTransition? {
        guard let nextState = nextState(for: action, from: _currentState) else {
            return nil  // Invalid transition
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

    public func canPerform(_ action: PlaybackAction) -> Bool {
        nextState(for: action, from: _currentState) != nil
    }
}
```

---

## Pure State Transition Logic

The core of the state machine is the **pure `nextState` function**:

```swift
private func nextState(for action: PlaybackAction, from state: PlaybackState) -> PlaybackState? {
    switch (state, action) {
    // MARK: - Idle State
    case (.idle, .load(let url)):
        return .loading(url)

    // MARK: - Loading State
    case (.loading, .didBecomeReady):
        return .ready
    case (.loading, .didFail(let error)):
        return .failed(error)
    case (.loading, .stop):
        return .idle

    // MARK: - Ready State
    case (.ready, .play):
        return .playing
    case (.ready, .stop):
        return .idle
    case (.ready, .load(let url)):
        return .loading(url)

    // MARK: - Playing State
    case (.playing, .pause):
        return .paused
    case (.playing, .didStartBuffering):
        return .buffering(previousState: .playing)
    case (.playing, .seek(let time)):
        return .seeking(to: time, previousState: .playing)
    case (.playing, .didReachEnd):
        return .ended
    case (.playing, .didFail(let error)):
        return .failed(error)
    case (.playing, .stop):
        return .idle
    case (.playing, .didEnterBackground):
        return .paused
    case (.playing, .audioSessionInterrupted):
        return .paused

    // MARK: - Paused State
    case (.paused, .play):
        return .playing
    case (.paused, .didStartBuffering):
        return .buffering(previousState: .paused)
    case (.paused, .seek(let time)):
        return .seeking(to: time, previousState: .paused)
    case (.paused, .stop):
        return .idle
    case (.paused, .load(let url)):
        return .loading(url)

    // MARK: - Buffering State
    case (.buffering(let previous), .didFinishBuffering):
        return previous == .playing ? .playing : .paused
    case (.buffering, .pause):
        return .buffering(previousState: .paused)
    case (.buffering, .play):
        return .buffering(previousState: .playing)
    case (.buffering, .didFail(let error)):
        return .failed(error)
    case (.buffering, .stop):
        return .idle

    // MARK: - Seeking State
    case (.seeking(_, let previous), .didFinishSeeking):
        return previous == .playing ? .playing : .paused
    case (.seeking(let time, _), .pause):
        return .seeking(to: time, previousState: .paused)
    case (.seeking(let time, _), .play):
        return .seeking(to: time, previousState: .playing)
    case (.seeking, .didFail(let error)):
        return .failed(error)
    case (.seeking, .stop):
        return .idle

    // MARK: - Ended State
    case (.ended, .play):
        return .playing
    case (.ended, .stop):
        return .idle
    case (.ended, .load(let url)):
        return .loading(url)

    // MARK: - Failed State
    case (.failed(let error), .retry) where error.isRecoverable:
        return .idle
    case (.failed, .load(let url)):
        return .loading(url)
    case (.failed, .stop):
        return .idle

    // Invalid transition
    default:
        return nil
    }
}
```

**Key Properties:**
- **Pure function** - No side effects, only returns computed state
- **Exhaustive** - Every valid transition is explicit
- **Invalid transitions return nil** - Caller knows action was rejected

---

## Testing the State Machine

The pure nature enables exhaustive testing:

```swift
@MainActor
final class DefaultPlaybackStateMachineTests: XCTestCase {

    // MARK: - Initial State

    func test_init_startsInIdleState() {
        let sut = makeSUT()
        XCTAssertEqual(sut.currentState, .idle)
    }

    // MARK: - Valid Transitions

    func test_sendLoad_fromIdle_transitionsToLoading() {
        let sut = makeSUT()
        let url = anyURL()

        let transition = sut.send(.load(url))

        XCTAssertEqual(sut.currentState, .loading(url))
        XCTAssertEqual(transition?.from, .idle)
        XCTAssertEqual(transition?.to, .loading(url))
        XCTAssertEqual(transition?.action, .load(url))
    }

    func test_sendPlay_fromReady_transitionsToPlaying() {
        let sut = makeSUT()
        sut.send(.load(anyURL()))
        sut.send(.didBecomeReady)

        let transition = sut.send(.play)

        XCTAssertEqual(sut.currentState, .playing)
        XCTAssertEqual(transition?.from, .ready)
        XCTAssertEqual(transition?.to, .playing)
    }

    // MARK: - Invalid Transitions

    func test_sendPlay_fromIdle_isRejected() {
        let sut = makeSUT()

        let transition = sut.send(.play)

        XCTAssertEqual(sut.currentState, .idle)  // State unchanged
        XCTAssertNil(transition)  // No transition occurred
    }

    func test_sendPause_fromIdle_isRejected() {
        let sut = makeSUT()

        let transition = sut.send(.pause)

        XCTAssertEqual(sut.currentState, .idle)
        XCTAssertNil(transition)
    }

    // MARK: - Buffering Recovery

    func test_sendDidFinishBuffering_fromBufferingWhilePlaying_returnsToPlaying() {
        let sut = makeSUT()
        transitionTo(.playing, sut: sut)
        sut.send(.didStartBuffering)

        sut.send(.didFinishBuffering)

        XCTAssertEqual(sut.currentState, .playing)
    }

    func test_sendDidFinishBuffering_fromBufferingWhilePaused_returnsToPaused() {
        let sut = makeSUT()
        transitionTo(.paused, sut: sut)
        sut.send(.didStartBuffering)

        sut.send(.didFinishBuffering)

        XCTAssertEqual(sut.currentState, .paused)
    }

    // MARK: - Time Control

    func test_transition_containsCorrectTimestamp() {
        let fixedDate = Date()
        let sut = makeSUT(currentDate: { fixedDate })

        let transition = sut.send(.load(anyURL()))

        XCTAssertEqual(transition?.timestamp, fixedDate)
    }

    // MARK: - Publisher Tests

    func test_statePublisher_emitsStateChanges() {
        let sut = makeSUT()
        var receivedStates: [PlaybackState] = []

        let cancellable = sut.statePublisher.sink { state in
            receivedStates.append(state)
        }

        sut.send(.load(anyURL()))
        sut.send(.didBecomeReady)
        sut.send(.play)

        XCTAssertEqual(receivedStates, [
            .idle,  // Initial value
            .loading(anyURL()),
            .ready,
            .playing
        ])

        cancellable.cancel()
    }

    // MARK: - Helpers

    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DefaultPlaybackStateMachine {
        let sut = DefaultPlaybackStateMachine(currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func transitionTo(_ state: PlaybackState, sut: DefaultPlaybackStateMachine) {
        switch state {
        case .playing:
            sut.send(.load(anyURL()))
            sut.send(.didBecomeReady)
            sut.send(.play)
        case .paused:
            transitionTo(.playing, sut: sut)
            sut.send(.pause)
        default:
            break
        }
    }
}
```

---

## Integration with iOS Layer

### AVPlayerStateAdapter

The adapter bridges AVPlayer observations to pure state machine actions:

```swift
public final class AVPlayerStateAdapter {
    private weak var player: AVPlayer?
    private let actionHandler: (PlaybackAction) -> Void

    public func startObserving() {
        // KVO observation
        player?.observe(\.timeControlStatus) { [weak self] player, _ in
            self?.handleTimeControlStatusChange(player.timeControlStatus)
        }
    }

    private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            actionHandler(.didStartPlaying)
        case .paused:
            actionHandler(.didPause)
        case .waitingToPlayAtSpecifiedRate:
            actionHandler(.didStartBuffering)
        @unknown default:
            break
        }
    }
}
```

### Complete Flow

```
┌─────────────────────────────────────────┐
│        IMPURE (iOS Layer)               │
│  AVPlayerStateAdapter                   │
│  - Observes AVPlayer KVO                │
│  - Translates to PlaybackAction         │
└────────────────┬────────────────────────┘
                 │ send(PlaybackAction)
                 ↓
┌─────────────────────────────────────────┐
│        PURE (Core Domain)               │
│  DefaultPlaybackStateMachine            │
│  - nextState(action, state) → PURE      │
│  - Emits PlaybackTransition             │
└────────────────┬────────────────────────┘
                 │ statePublisher
                 ↓
┌─────────────────────────────────────────┐
│  IMPURE (Subscribers)                   │
│  UI updates, logging, analytics         │
└─────────────────────────────────────────┘
```

---

## Benefits of This Design

1. **Predictable** - Same action + state always produces same result
2. **Testable** - 60+ transition tests with no mocks
3. **Debuggable** - Transitions are logged with timestamps
4. **Type-Safe** - Invalid states are impossible to represent
5. **Decoupled** - State machine knows nothing about AVPlayer

---

## Related Documentation

- [Dependency Rejection](DEPENDENCY-REJECTION.md) - Why the state machine is pure
- [Architecture](ARCHITECTURE.md) - Where state machine fits in layers
- [TDD](TDD.md) - Testing state transitions
- [Reactive Programming](REACTIVE-PROGRAMMING.md) - State publishers

---

## References

- [State Pattern - Design Patterns](https://refactoring.guru/design-patterns/state)
- [Finite State Machines](https://en.wikipedia.org/wiki/Finite-state_machine)
