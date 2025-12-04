# Reactive Programming with Combine in StreamingVideoApp

This document explains the Combine patterns and reactive programming practices used throughout the StreamingVideoApp codebase.

---

## Overview

StreamingVideoApp uses Apple's **Combine framework** for:
- Asynchronous data streams
- State management and publishing
- Event handling
- Functional transformations

---

## Publisher Types Used

| Publisher | Purpose | Example |
|-----------|---------|---------|
| `CurrentValueSubject` | State storage with current value access | `PlaybackState` |
| `PassthroughSubject` | Event streams without state | `PlaybackTransition` |
| `Deferred + Future` | Lazy async-to-Combine bridging | HTTP requests |
| `AnyPublisher` | Type-erased publisher for protocols | `VideoLoader` |

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

## 3. Async-to-Combine Bridging

**File:** `StreamingCore/StreamingCore/Shared Combine/CombineHelpers.swift`

```swift
public extension HTTPClient {
    @MainActor
    func getPublisher(url: URL) -> AnyPublisher<(Data, HTTPURLResponse), Error> {
        var task: Task<Void, Never>?

        return Deferred {
            Future { completion in
                task = Task {
                    do {
                        let result = try await self.get(from: url)
                        completion(.success(result))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}
```

---

## 4. Functional Transformations

### Fallback Strategy

```swift
public extension Publisher {
    func fallback(to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
        self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}
```

### Caching Side-Effect

```swift
public extension Publisher where Output == [Video] {
    func caching(to cache: VideoCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { videos in
            try? cache.save(videos)
        }).eraseToAnyPublisher()
    }
}
```

### Main Thread Dispatch

```swift
public extension Publisher {
    func dispatchOnMainThread() -> AnyPublisher<Output, Failure> {
        receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
}
```

---

## 5. Complete Data Loading Flow

```swift
let loadVideos: () -> AnyPublisher<[Video], Error> = {
    remoteLoader.load()
        .caching(to: localCache)
        .fallback(to: { localLoader.loadPublisher() })
        .dispatchOnMainThread()
        .eraseToAnyPublisher()
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
