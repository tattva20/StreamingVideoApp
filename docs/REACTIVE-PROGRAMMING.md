# Reactive Programming with Combine in StreamingVideoApp

This document explains the Combine patterns and reactive programming practices used throughout the StreamingVideoApp codebase.

---

## Overview

StreamingVideoApp uses Apple's **Combine framework** for **observation and state streams**. The video feed and comments loaders now use async/await; Combine backs the parts of the system that are genuinely stream-shaped:
- Playback state and transition streams
- Buffer, memory, and performance monitoring
- Resource cleanup events
- CoreData store scheduling (`AnyScheduler`)

---

## Publisher Types Used

| Publisher | Purpose | Example |
|-----------|---------|---------|
| `CurrentValueSubject` | State storage with current value access | `PlaybackState` |
| `PassthroughSubject` | Event streams without state | `PlaybackTransition` |
| `AnyScheduler` | Type-erased scheduler for CoreData work | Cache scheduling |
| `AnyPublisher` | Type-erased publisher for observation | `statePublisher` |

---

## 1. State Publishing with CurrentValueSubject

### PlaybackState Publishing

```swift
@MainActor
public final class DefaultPlaybackStateMachine {
    private let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)

    public var currentState: PlaybackState { stateSubject.value }

    public var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public func send(_ action: PlaybackAction) -> PlaybackTransition? {
        guard let nextState = nextState(for: action, from: stateSubject.value) else {
            return nil
        }
        stateSubject.send(nextState)
        return transition
    }
}
```

**Why CurrentValueSubject?**
- Stores current value (accessible via `.value`)
- New subscribers immediately receive current state
- Perfect for UI state bindings

---

## 2. Event Streams with PassthroughSubject

```swift
@MainActor
public final class DefaultPlaybackStateMachine {
    private let transitionSubject = PassthroughSubject<PlaybackTransition, Never>()

    public var transitionPublisher: AnyPublisher<PlaybackTransition, Never> {
        transitionSubject.eraseToAnyPublisher()
    }

    public func send(_ action: PlaybackAction) -> PlaybackTransition? {
        transitionSubject.send(transition)
        return transition
    }
}
```

**Why PassthroughSubject?** No stored value, only emits to current subscribers - perfect for events.

---

## 3. Scheduling with AnyScheduler

**File:** `StreamingCore/StreamingCore/Shared Combine/CombineHelpers.swift`

CoreData work is dispatched through a type-erased `AnyScheduler`, keeping store access on the store's own queue:

```swift
public typealias AnyDispatchQueueScheduler = AnyScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>

public extension AnyDispatchQueueScheduler {
    static func scheduler(for store: CoreDataVideoStore) -> AnyDispatchQueueScheduler {
        CoreDataVideoStoreScheduler(store: store).eraseToAnyScheduler()
    }
}
```

---

## 4. Functional Side-Effects

Image data flows through a Combine caching helper — a `handleEvents` side-effect that writes successful loads to the cache:

```swift
public extension Publisher where Output == Data {
    func caching(to cache: VideoImageDataCache, for url: URL) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { data in
            try? cache.save(data, for: url)
        }).eraseToAnyPublisher()
    }
}
```

---

## 5. Feed and Comments Loading

The feed and comments loaders are **not** Combine. They compose with async/await — remote fetch, cache write, and local fallback expressed directly:

```swift
func makeRemoteVideoLoaderWithLocalFallback() async throws -> Paginated<Video> {
    do {
        let items = try await makeRemoteVideoLoader()
        try? localVideoLoader.save(items)
        return makeFirstPage(items: items)
    } catch {
        return makeFirstPage(items: try localVideoLoader.load())
    }
}
```

---

## 6. State Machine Subscriptions

```swift
@MainActor
final class VideoPlayerViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        stateMachine.statePublisher
            .removeDuplicates()
            .sink { [weak self] state in
                self?.updateUI(for: state)
            }
            .store(in: &cancellables)
    }
}
```

---

## 7. Common Pitfalls

### Forgetting to Store Cancellables

```swift
// Bad - subscription immediately cancelled
publisher.sink { value in }

// Good - stored
publisher.sink { value in }.store(in: &cancellables)
```

### Strong Reference Cycles

```swift
// Bad
publisher.sink { state in self.updateUI(state) }

// Good
publisher.sink { [weak self] state in self?.updateUI(state) }
```

### Not Dispatching to Main Thread

```swift
// Bad
networkPublisher.sink { [weak self] data in self?.label.text = data }

// Good
networkPublisher.receive(on: DispatchQueue.main).sink { ... }
```

---

## Related Documentation

- [State Machines](STATE-MACHINES.md) - State publishing patterns
- [Architecture](ARCHITECTURE.md) - Where Combine fits in layers
- [TDD](TDD.md) - Testing publishers

---

## References

- [Combine Framework - Apple](https://developer.apple.com/documentation/combine)
