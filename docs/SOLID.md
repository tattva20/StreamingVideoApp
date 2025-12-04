# SOLID Principles in StreamingVideoApp

This document demonstrates how each SOLID principle is applied throughout the StreamingVideoApp codebase with concrete examples.

---

## Overview

SOLID is an acronym for five design principles that make software more maintainable, flexible, and testable:

| Principle | Description |
|-----------|-------------|
| **S** - Single Responsibility | A class should have only one reason to change |
| **O** - Open/Closed | Open for extension, closed for modification |
| **L** - Liskov Substitution | Subtypes must be substitutable for their base types |
| **I** - Interface Segregation | Many specific interfaces are better than one general interface |
| **D** - Dependency Inversion | Depend on abstractions, not concretions |

---

## Single Responsibility Principle (SRP)

> *"A class should have only one reason to change."*

### Example: Video Loading Responsibilities

Each class handles exactly ONE concern:

```swift
RemoteVideoLoader       // ONLY fetches from network
LocalVideoLoader        // ONLY fetches from cache
VideoLoaderCacheDecorator // ONLY handles caching logic
VideoItemsMapper        // ONLY transforms JSON to domain models
VideoPresenter          // ONLY formats data for display
```

### Bad Example (Violation):

```swift
// DON'T DO THIS - Multiple responsibilities
class VideoService {
    func fetchVideosFromNetwork() -> [Video] { ... }
    func loadVideosFromCache() -> [Video] { ... }
    func saveToCache(_ videos: [Video]) { ... }
    func formatForDisplay(_ video: Video) -> VideoViewModel { ... }
    func trackAnalytics(_ event: String) { ... }
}
```

### Good Example (Following SRP):

```swift
// Each class has ONE job
final class RemoteVideoLoader: VideoLoader {
    private let client: HTTPClient
    private let url: URL

    func load() async throws -> [Video] {
        let (data, response) = try await client.get(from: url)
        return try VideoItemsMapper.map(data, from: response)
    }
}

final class LocalVideoLoader {
    private let store: VideoStore

    func load() throws -> [Video] {
        guard let cache = try store.retrieve(),
              VideoCachePolicy.validate(cache.timestamp, against: Date()) else {
            return []
        }
        return cache.videos.toModels()
    }
}
```

---

## Open/Closed Principle (OCP)

> *"Software entities should be open for extension, but closed for modification."*

### Example: Adding Caching Without Modifying Remote Loader

The `VideoLoaderCacheDecorator` adds caching behavior without changing `RemoteVideoLoader`:

```swift
// Original loader - NEVER modified
final class RemoteVideoLoader: VideoLoader {
    func load() async throws -> [Video] {
        // Network fetching logic
    }
}

// Extend behavior with decorator - NO modification needed
final class VideoLoaderCacheDecorator: VideoLoader {
    private let decoratee: VideoLoader
    private let cache: VideoCache

    init(decoratee: VideoLoader, cache: VideoCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    func load() async throws -> [Video] {
        let videos = try await decoratee.load()
        try cache.save(videos)  // Added behavior
        return videos
    }
}

// Usage - compose behaviors
let loader = VideoLoaderCacheDecorator(
    decoratee: RemoteVideoLoader(client: httpClient, url: url),
    cache: localCache
)
```

### Example: Adding Logging to Video Player

```swift
// Original player - NEVER modified
final class AVPlayerVideoPlayer: VideoPlayer { ... }

// Add logging via decorator
final class LoggingVideoPlayerDecorator: VideoPlayer {
    private let decoratee: VideoPlayer
    private let logger: Logger

    func play() {
        logger.log(.info, "Play requested")
        decoratee.play()
    }

    func pause() {
        logger.log(.info, "Pause requested")
        decoratee.pause()
    }
}

// Add analytics via another decorator
final class AnalyticsVideoPlayerDecorator: VideoPlayer {
    private let decoratee: VideoPlayer
    private let analytics: PlaybackAnalyticsLogger

    func play() {
        Task { await analytics.log(.play) }
        decoratee.play()
    }
}

// Stack decorators without modifying original
let player = LoggingVideoPlayerDecorator(
    decoratee: AnalyticsVideoPlayerDecorator(
        decoratee: AVPlayerVideoPlayer()
    )
)
```

---

## Liskov Substitution Principle (LSP)

> *"Objects of a superclass should be replaceable with objects of its subclasses without affecting correctness."*

### Example: VideoLoader Implementations

Any `VideoLoader` can replace another without breaking the system:

```swift
protocol VideoLoader {
    func load() async throws -> [Video]
}

// All implementations are interchangeable:
let loader: VideoLoader = RemoteVideoLoader(...)      // Production
let loader: VideoLoader = LocalVideoLoader(...)       // Offline
let loader: VideoLoader = VideoLoaderCacheDecorator(...)  // Cached
let loader: VideoLoader = VideoLoaderSpy()            // Testing
```

### Example: HTTPClient Implementations

```swift
protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

// Production implementation
final class URLSessionHTTPClient: HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
        // ...
    }
}

// Test implementation - same interface, different behavior
final class HTTPClientSpy: HTTPClient {
    var requestedURLs: [URL] = []
    var stubbedResult: Result<(Data, HTTPURLResponse), Error>?

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        return try stubbedResult!.get()
    }
}
```

The consumer doesn't know or care which implementation it's using:

```swift
final class RemoteVideoLoader {
    private let client: HTTPClient  // Works with ANY HTTPClient

    init(client: HTTPClient, url: URL) {
        self.client = client
    }
}
```

---

## Interface Segregation Principle (ISP)

> *"Clients should not be forced to depend on interfaces they don't use."*

### Good Example: Segregated Protocols

```swift
// Small, focused protocols
protocol VideoLoader {
    func load() async throws -> [Video]
}

protocol VideoCache {
    func save(_ videos: [Video]) throws
}

protocol VideoImageDataLoader {
    func loadImageData(from url: URL) async throws -> Data
}
```

### Bad Example (Violation):

```swift
// DON'T DO THIS - Fat interface
protocol VideoService {
    func load() async throws -> [Video]
    func save(_ videos: [Video]) throws
    func loadImageData(from url: URL) async throws -> Data
    func loadComments(for videoId: UUID) async throws -> [VideoComment]
    func trackPlayback(_ event: PlaybackEvent)
    func validate(_ video: Video) -> Bool
    // ... 20 more methods
}
```

### Example: VideoStore Triple Conformance

The `CoreDataVideoStore` conforms to THREE separate protocols:

```swift
protocol VideoStore {
    func deleteCachedVideos() throws
    func insert(_ videos: [LocalVideo], timestamp: Date) throws
    func retrieve() throws -> CachedVideos?
}

protocol VideoImageDataStore {
    func insert(_ data: Data, for url: URL) throws
    func retrieve(dataForURL url: URL) throws -> Data?
}

protocol VideoFeedStore {
    func retrieve() throws -> LocalVideoFeed?
}

// One class, multiple focused interfaces
final class CoreDataVideoStore: VideoStore, VideoImageDataStore, VideoFeedStore {
    // Implementation
}
```

Clients only depend on what they need:

```swift
final class LocalVideoLoader {
    private let store: VideoStore  // Only needs video store methods
}

final class LocalVideoImageDataLoader {
    private let store: VideoImageDataStore  // Only needs image methods
}
```

---

## Dependency Inversion Principle (DIP)

> *"High-level modules should not depend on low-level modules. Both should depend on abstractions."*

### Example: Protocol Definitions in Core, Implementations in App

```swift
// StreamingCore defines abstractions (high-level)
public protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

public protocol VideoStore {
    func deleteCachedVideos() throws
    func insert(_ videos: [LocalVideo], timestamp: Date) throws
    func retrieve() throws -> CachedVideos?
}

// StreamingVideoApp provides implementations (low-level)
final class URLSessionHTTPClient: HTTPClient { ... }
final class CoreDataVideoStore: VideoStore { ... }
```

### The Dependency Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    StreamingCore (Core)                     │
│                                                             │
│  ┌─────────────────┐         ┌─────────────────┐           │
│  │  VideoLoader    │         │   HTTPClient    │           │
│  │   (protocol)    │─────────│   (protocol)    │           │
│  └─────────────────┘         └─────────────────┘           │
│          ▲                           ▲                     │
│          │                           │                     │
│          │ depends on                │ depends on          │
│          │                           │                     │
│  ┌─────────────────┐                 │                     │
│  │RemoteVideoLoader│─────────────────┘                     │
│  │ (implementation)│                                       │
│  └─────────────────┘                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ implements
                              │
┌─────────────────────────────────────────────────────────────┐
│                 StreamingVideoApp (App)                     │
│                                                             │
│  ┌─────────────────┐         ┌─────────────────┐           │
│  │URLSessionHTTP   │         │ CoreDataVideo   │           │
│  │    Client       │         │     Store       │           │
│  │(implementation) │         │(implementation) │           │
│  └─────────────────┘         └─────────────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Business Logic Never Knows About Frameworks

```swift
// RemoteVideoLoader has NO idea it's using URLSession
public final class RemoteVideoLoader: VideoLoader {
    private let client: HTTPClient  // Abstract protocol
    private let url: URL

    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    public func load() async throws -> [Video] {
        let (data, response) = try await client.get(from: url)
        return try VideoItemsMapper.map(data, from: response)
    }
}
```

---

## SOLID in Practice: Complete Example

Here's how all five principles work together in the video loading feature:

```swift
// S - Single Responsibility
// Each class does ONE thing
final class RemoteVideoLoader: VideoLoader { ... }  // Fetches from network
final class LocalVideoLoader { ... }                 // Fetches from cache
final class VideoItemsMapper { ... }                 // Maps JSON to models

// O - Open/Closed
// Add caching without modifying RemoteVideoLoader
let cachedLoader = VideoLoaderCacheDecorator(
    decoratee: remoteLoader,
    cache: localCache
)

// L - Liskov Substitution
// Any VideoLoader works interchangeably
func displayVideos(loader: VideoLoader) {
    let videos = try await loader.load()
    // Works with Remote, Local, Cached, or Test loader
}

// I - Interface Segregation
// Small, focused protocols
protocol VideoLoader { func load() async throws -> [Video] }
protocol VideoCache { func save(_ videos: [Video]) throws }

// D - Dependency Inversion
// Core defines protocols, App provides implementations
public protocol HTTPClient { ... }  // In StreamingCore
final class URLSessionHTTPClient: HTTPClient { ... }  // In StreamingVideoApp
```

---

## Benefits

Following SOLID principles enables:

1. **Testability** - Each unit can be tested in isolation
2. **Maintainability** - Changes are localized to specific classes
3. **Extensibility** - Add features without modifying existing code
4. **Reusability** - Components can be used in different contexts
5. **Readability** - Each class has a clear, single purpose

---

## Related Documentation

- [Architecture](ARCHITECTURE.md) - How SOLID enables Clean Architecture
- [Design Patterns](DESIGN-PATTERNS.md) - Decorator, Composite patterns
- [Dependency Rejection](DEPENDENCY-REJECTION.md) - Pure functions complement SOLID
- [TDD](TDD.md) - Testing SOLID-compliant code

---

## References

- [SOLID Principles - Robert C. Martin](https://en.wikipedia.org/wiki/SOLID)
- [Agile Software Development - Robert C. Martin](https://www.amazon.com/Agile-Software-Development-Principles-Practices/dp/0135974445)
