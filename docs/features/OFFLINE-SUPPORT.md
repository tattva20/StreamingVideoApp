# Offline Support Feature

The Offline Support feature enables the app to work without network connectivity by caching videos and images locally.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Online Mode                              │
│                                                             │
│    Remote API ──▶ Cache ──▶ Display                        │
│                     │                                       │
│                     ▼                                       │
│               Save to Local                                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Offline Mode                             │
│                                                             │
│    Remote API ✗ ──▶ Fallback ──▶ Local Cache ──▶ Display   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Video Metadata Caching** - Store video list locally
- **Image Caching** - Persist thumbnails for offline viewing
- **Cache Validation** - 7-day expiration policy
- **Fallback Loading** - Automatic switch to cache on network failure
- **Cache-First Strategy** - Try remote, save to cache, fallback on error

---

## Architecture

### Cache Policy

**File:** `StreamingCore/StreamingCore/Video Cache/VideoCachePolicy.swift`

```swift
final class VideoCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int { 7 }

    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(
            byAdding: .day,
            value: maxCacheAgeInDays,
            to: timestamp
        ) else {
            return false
        }
        return date < maxCacheAge
    }
}
```

### Video Store Protocol

**File:** `StreamingCore/StreamingCore/Video Cache/VideoStore.swift`

```swift
public protocol VideoStore {
    func deleteCachedVideos() throws
    func insert(_ videos: [LocalVideo], timestamp: Date) throws
    func retrieve() throws -> CachedVideos?
}

public struct CachedVideos {
    public let videos: [LocalVideo]
    public let timestamp: Date
}
```

---

## Storage Implementations

### CoreData Store

**File:** `StreamingCore/StreamingCore/Video Cache/Infrastructure/CoreData/CoreDataVideoStore.swift`

```swift
public final class CoreDataVideoStore: VideoStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public func insert(_ videos: [LocalVideo], timestamp: Date) throws {
        try context.performAndWait {
            let cache = ManagedCache(context: context)
            cache.timestamp = timestamp
            cache.videos = NSOrderedSet(array: videos.map {
                ManagedVideo.video(from: $0, in: context)
            })
            try context.save()
        }
    }

    public func retrieve() throws -> CachedVideos? {
        try context.performAndWait {
            guard let cache = try ManagedCache.find(in: context) else {
                return nil
            }
            return CachedVideos(
                videos: cache.localVideos,
                timestamp: cache.timestamp
            )
        }
    }

    public func deleteCachedVideos() throws {
        try context.performAndWait {
            try ManagedCache.find(in: context).map(context.delete)
            try context.save()
        }
    }
}
```

### In-Memory Store (Testing)

**File:** `StreamingCore/StreamingCore/Video Cache/Infrastructure/InMemory/InMemoryVideoStore.swift`

```swift
public final class InMemoryVideoStore: VideoStore {
    private var cache: CachedVideos?

    public func insert(_ videos: [LocalVideo], timestamp: Date) throws {
        cache = CachedVideos(videos: videos, timestamp: timestamp)
    }

    public func retrieve() throws -> CachedVideos? {
        cache
    }

    public func deleteCachedVideos() throws {
        cache = nil
    }
}
```

---

## Local Video Loader

**File:** `StreamingCore/StreamingCore/Video Cache/LocalVideoLoader.swift`

```swift
public final class LocalVideoLoader {
    private let store: VideoStore
    private let currentDate: () -> Date

    public init(store: VideoStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
}

// MARK: - VideoLoader
extension LocalVideoLoader: VideoLoader {
    public func load() throws -> [Video] {
        if let cache = try store.retrieve(),
           VideoCachePolicy.validate(cache.timestamp, against: currentDate()) {
            return cache.videos.toModels()
        }
        return []
    }
}

// MARK: - VideoCache
extension LocalVideoLoader: VideoCache {
    public func save(_ videos: [Video]) throws {
        try store.deleteCachedVideos()
        try store.insert(videos.toLocal(), timestamp: currentDate())
    }
}
```

---

## Composition Patterns

### Cache Decorator

```swift
public final class VideoLoaderCacheDecorator: VideoLoader {
    private let decoratee: VideoLoader
    private let cache: VideoCache

    public init(decoratee: VideoLoader, cache: VideoCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    public func load() async throws -> [Video] {
        let videos = try await decoratee.load()
        try cache.save(videos)  // Save to cache on success
        return videos
    }
}
```

### Fallback Composite

```swift
public final class VideoLoaderWithFallbackComposite: VideoLoader {
    private let primary: VideoLoader
    private let fallback: VideoLoader

    public init(primary: VideoLoader, fallback: VideoLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func load() async throws -> [Video] {
        do {
            return try await primary.load()
        } catch {
            return try await fallback.load()  // Use cache on failure
        }
    }
}
```

### Complete Composition

```swift
// In SceneDelegate
func makeVideoLoader() -> VideoLoader {
    let remoteLoader = RemoteVideoLoader(client: httpClient, url: videosURL)
    let localLoader = LocalVideoLoader(store: coreDataStore)

    // Remote with caching
    let cachedRemoteLoader = VideoLoaderCacheDecorator(
        decoratee: remoteLoader,
        cache: localLoader
    )

    // Fallback to local on failure
    return VideoLoaderWithFallbackComposite(
        primary: cachedRemoteLoader,
        fallback: localLoader
    )
}
```

---

## Loading Flow

```
┌─────────────────┐
│ Load Videos     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Try Remote      │
│ Loader          │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
 success   failure
    │         │
    ▼         ▼
┌─────────┐ ┌─────────────────┐
│ Save to │ │ Load from       │
│ Cache   │ │ Local Cache     │
└────┬────┘ └────────┬────────┘
     │               │
     └───────┬───────┘
             │
             ▼
      ┌─────────────┐
      │ Display     │
      │ Videos      │
      └─────────────┘
```

---

## Image Caching

### FileSystem Storage

**File:** `StreamingCore/StreamingCore/Video Cache/Infrastructure/FileSystem/FileSystemVideoImageDataStore.swift`

```swift
public final class FileSystemVideoImageDataStore: VideoImageDataStore {
    private let storeURL: URL

    public func insert(_ data: Data, for url: URL) throws {
        let fileURL = cacheURL(for: url)
        try FileManager.default.createDirectory(
            at: storeURL,
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL)
    }

    public func retrieve(dataForURL url: URL) throws -> Data? {
        let fileURL = cacheURL(for: url)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return try Data(contentsOf: fileURL)
    }

    private func cacheURL(for url: URL) -> URL {
        let filename = url.absoluteString
            .data(using: .utf8)!
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
        return storeURL.appendingPathComponent(filename)
    }
}
```

---

## Cache Invalidation

### Automatic Expiration

```swift
// In LocalVideoLoader.load()
if let cache = try store.retrieve(),
   VideoCachePolicy.validate(cache.timestamp, against: currentDate()) {
    return cache.videos.toModels()
}
// Expired or no cache - return empty
return []
```

### Manual Clearing

```swift
// Clear video cache
try store.deleteCachedVideos()

// Clear image cache
try FileManager.default.removeItem(at: imageCacheURL)
```

---

## Data Models

### LocalVideo

**File:** `StreamingCore/StreamingCore/Video Cache/LocalVideo.swift`

```swift
public struct LocalVideo: Equatable {
    public let id: UUID
    public let title: String
    public let description: String
    public let url: URL
    public let thumbnailURL: URL
    public let duration: TimeInterval
}

extension Array where Element == Video {
    func toLocal() -> [LocalVideo] {
        map { LocalVideo(
            id: $0.id,
            title: $0.title,
            description: $0.description,
            url: $0.url,
            thumbnailURL: $0.thumbnailURL,
            duration: $0.duration
        )}
    }
}

extension Array where Element == LocalVideo {
    func toModels() -> [Video] {
        map { Video(
            id: $0.id,
            title: $0.title,
            description: $0.description,
            url: $0.url,
            thumbnailURL: $0.thumbnailURL,
            duration: $0.duration
        )}
    }
}
```

---

## Testing

### Cache Policy Tests

```swift
func test_validate_returnsTrueOnLessThanSevenDaysOldCache() {
    let sixDaysAgo = Date().addingTimeInterval(-6 * 24 * 60 * 60)
    XCTAssertTrue(VideoCachePolicy.validate(sixDaysAgo, against: Date()))
}

func test_validate_returnsFalseOnSevenDaysOldCache() {
    let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    XCTAssertFalse(VideoCachePolicy.validate(sevenDaysAgo, against: Date()))
}
```

### Integration Tests

```swift
func test_load_deliversCachedVideosOnCacheHit() async throws {
    let store = InMemoryVideoStore()
    let sut = LocalVideoLoader(store: store)
    let videos = [makeVideo(), makeVideo()]

    try sut.save(videos)
    let result = try sut.load()

    XCTAssertEqual(result, videos)
}
```

---

## Related Documentation

- [Video Feed](VIDEO-FEED.md) - Feed loading
- [Thumbnail Loading](THUMBNAIL-LOADING.md) - Image caching
- [Design Patterns](../DESIGN-PATTERNS.md) - Decorator pattern
- [Memory Management](MEMORY-MANAGEMENT.md) - Cache cleanup
