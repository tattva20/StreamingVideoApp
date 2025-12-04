# Video Preloading Feature

The Video Preloading feature anticipates user navigation and preloads upcoming videos to reduce startup time and provide seamless playback transitions.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Video Preloading System                             │
│                                                                         │
│  ┌───────────────┐    ┌─────────────────────┐    ┌─────────────────┐  │
│  │ Current Video │    │ PredictivePreload   │    │ VideoPreloader  │  │
│  │ Index         │───▶│ Strategy            │───▶│                 │  │
│  └───────────────┘    └─────────────────────┘    │ - preload()     │  │
│                                                   │ - cancel()      │  │
│  ┌───────────────┐              │                └─────────────────┘  │
│  │ Playlist      │              │                         │           │
│  │               │──────────────┤                         │           │
│  └───────────────┘              │                         ▼           │
│                                 │                ┌─────────────────┐  │
│  ┌───────────────┐              │                │ Preload Cache   │  │
│  │ Network       │              ▼                │ - Video 1       │  │
│  │ Quality       │    ┌─────────────────────┐   │ - Video 2       │  │
│  └───────────────┘    │ Videos to Preload:  │   └─────────────────┘  │
│                       │ - Next 1-2 videos   │                        │
│                       │ - Based on network  │                        │
│                       └─────────────────────┘                        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Features

- **Predictive Loading** - Anticipates which videos user will watch next
- **Network-Aware** - Adjusts preload count based on connection quality
- **Priority-Based** - Different urgency levels for preload tasks
- **Cancellable** - Can cancel preloads when navigation changes
- **Memory Efficient** - Balances preloading with memory constraints
- **Strategy Pattern** - Swappable preload decision algorithms

---

## Architecture

### PreloadableVideo

**File:** `StreamingCore/StreamingCore/Video Performance Feature/PreloadableVideo.swift`

```swift
public struct PreloadableVideo: Equatable, Sendable {
    public let id: UUID
    public let url: URL
    public let estimatedDuration: TimeInterval?

    public init(id: UUID, url: URL, estimatedDuration: TimeInterval?) {
        self.id = id
        self.url = url
        self.estimatedDuration = estimatedDuration
    }
}
```

### PreloadPriority

**File:** `StreamingCore/StreamingCore/Video Performance Feature/PreloadPriority.swift`

```swift
public enum PreloadPriority: Int, Sendable, Comparable, CaseIterable {
    case low = 0       // Background preloading
    case medium = 1    // Normal preloading
    case high = 2      // User likely to watch soon
    case immediate = 3 // User navigating now

    public static func < (lhs: PreloadPriority, rhs: PreloadPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

### Priority Use Cases

| Priority | Use Case |
|----------|----------|
| Low | Videos 3+ positions away |
| Medium | Next video in normal playback |
| High | User showing intent (hovering, slow scroll) |
| Immediate | User initiated navigation |

---

## VideoPreloader Protocol

**File:** `StreamingCore/StreamingCore/Video Performance Feature/VideoPreloader.swift`

```swift
public protocol VideoPreloader: AnyObject, Sendable {
    /// Preload a video with given priority
    func preload(_ video: PreloadableVideo, priority: PreloadPriority) async

    /// Cancel preloading for a specific video
    func cancelPreload(for videoID: UUID)

    /// Cancel all ongoing preloads
    func cancelAllPreloads()
}
```

---

## PredictivePreloadStrategy Protocol

**File:** `StreamingCore/StreamingCore/Video Performance Feature/PredictivePreloadStrategy.swift`

```swift
public protocol PredictivePreloadStrategy: Sendable {
    /// Determine which videos should be preloaded based on current position
    func videosToPreload(
        currentVideoIndex: Int,
        playlist: [PreloadableVideo],
        networkQuality: NetworkQuality
    ) -> [PreloadableVideo]
}
```

---

## AdjacentVideoPreloadStrategy

**File:** `StreamingCore/StreamingCore/Video Performance Feature/AdjacentVideoPreloadStrategy.swift`

```swift
public struct AdjacentVideoPreloadStrategy: PredictivePreloadStrategy, Sendable {

    public init() {}

    public func videosToPreload(
        currentVideoIndex: Int,
        playlist: [PreloadableVideo],
        networkQuality: NetworkQuality
    ) -> [PreloadableVideo] {
        // Validate index
        guard currentVideoIndex >= 0,
              currentVideoIndex < playlist.count,
              !playlist.isEmpty else {
            return []
        }

        // No preloading when offline
        guard networkQuality != .offline else {
            return []
        }

        // Determine how many videos to preload based on network quality
        let preloadCount: Int
        switch networkQuality {
        case .offline:
            preloadCount = 0
        case .poor:
            preloadCount = 1
        case .fair:
            preloadCount = 1
        case .good:
            preloadCount = 2
        case .excellent:
            preloadCount = 2
        }

        // Collect next videos
        var videosToPreload: [PreloadableVideo] = []
        let startIndex = currentVideoIndex + 1
        let endIndex = min(startIndex + preloadCount, playlist.count)

        for index in startIndex..<endIndex {
            videosToPreload.append(playlist[index])
        }

        return videosToPreload
    }
}
```

---

## Network Quality to Preload Count

| Network Quality | Preload Count | Rationale |
|-----------------|---------------|-----------|
| Offline | 0 | No connectivity |
| Poor | 1 | Preserve bandwidth |
| Fair | 1 | Conservative preloading |
| Good | 2 | Comfortable preloading |
| Excellent | 2 | Aggressive preloading |

---

## Usage Example

### Basic Preloading

```swift
let preloader: VideoPreloader = DefaultVideoPreloader(httpClient: httpClient)
let strategy = AdjacentVideoPreloadStrategy()

func onVideoChanged(newIndex: Int) {
    // Cancel previous preloads
    preloader.cancelAllPreloads()

    // Determine videos to preload
    let videosToPreload = strategy.videosToPreload(
        currentVideoIndex: newIndex,
        playlist: playlist,
        networkQuality: networkMonitor.currentQuality
    )

    // Start preloading with decreasing priority
    for (offset, video) in videosToPreload.enumerated() {
        let priority: PreloadPriority = offset == 0 ? .high : .medium
        Task {
            await preloader.preload(video, priority: priority)
        }
    }
}
```

### Integration with Video Feed

```swift
@MainActor
class VideoFeedViewModel {
    private let preloader: VideoPreloader
    private let preloadStrategy: PredictivePreloadStrategy
    private let networkMonitor: NetworkQualityMonitor

    func onVisibleIndexChanged(_ index: Int) {
        // Preload adjacent videos
        let videosToPreload = preloadStrategy.videosToPreload(
            currentVideoIndex: index,
            playlist: videos.map { PreloadableVideo(id: $0.id, url: $0.videoURL, estimatedDuration: $0.duration) },
            networkQuality: networkMonitor.currentQuality
        )

        videosToPreload.enumerated().forEach { offset, video in
            let priority: PreloadPriority = offset == 0 ? .high : .medium
            Task {
                await preloader.preload(video, priority: priority)
            }
        }
    }

    func onNavigatingAway() {
        preloader.cancelAllPreloads()
    }
}
```

---

## Preload Workflow

```
User viewing Video 3
        │
        ▼
┌───────────────────────┐
│ Strategy determines:  │
│ - Preload Video 4     │
│ - Preload Video 5     │
│ (based on network)    │
└───────────────────────┘
        │
        ▼
┌───────────────────────┐
│ Preloader starts:     │
│ - Video 4 (High)      │
│ - Video 5 (Medium)    │
└───────────────────────┘
        │
        ▼
User navigates to Video 4
        │
        ▼
┌───────────────────────┐
│ Video 4 loads         │
│ instantly from cache! │
└───────────────────────┘
        │
        ▼
┌───────────────────────┐
│ New preloads:         │
│ - Cancel Video 5      │
│ - Preload Video 5     │
│ - Preload Video 6     │
└───────────────────────┘
```

---

## Testing

### Strategy Tests

```swift
func test_videosToPreload_excellentNetwork_returnsNext2Videos() {
    let sut = AdjacentVideoPreloadStrategy()
    let playlist = makePlaylist(count: 5)

    let result = sut.videosToPreload(
        currentVideoIndex: 1,
        playlist: playlist,
        networkQuality: .excellent
    )

    XCTAssertEqual(result.count, 2)
    XCTAssertEqual(result[0].id, playlist[2].id)
    XCTAssertEqual(result[1].id, playlist[3].id)
}

func test_videosToPreload_poorNetwork_returnsNext1Video() {
    let sut = AdjacentVideoPreloadStrategy()
    let playlist = makePlaylist(count: 5)

    let result = sut.videosToPreload(
        currentVideoIndex: 1,
        playlist: playlist,
        networkQuality: .poor
    )

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].id, playlist[2].id)
}

func test_videosToPreload_offline_returnsEmpty() {
    let sut = AdjacentVideoPreloadStrategy()
    let playlist = makePlaylist(count: 5)

    let result = sut.videosToPreload(
        currentVideoIndex: 1,
        playlist: playlist,
        networkQuality: .offline
    )

    XCTAssertTrue(result.isEmpty)
}

func test_videosToPreload_atEndOfPlaylist_returnsEmpty() {
    let sut = AdjacentVideoPreloadStrategy()
    let playlist = makePlaylist(count: 3)

    let result = sut.videosToPreload(
        currentVideoIndex: 2,  // Last video
        playlist: playlist,
        networkQuality: .excellent
    )

    XCTAssertTrue(result.isEmpty)
}
```

### Preloader Tests

```swift
func test_preload_startsPreloadingForVideo() async {
    let spy = HTTPClientSpy()
    let sut = DefaultVideoPreloader(httpClient: spy)
    let video = PreloadableVideo(id: UUID(), url: anyURL(), estimatedDuration: 60)

    await sut.preload(video, priority: .high)

    XCTAssertEqual(spy.requestedURLs, [video.url])
}

func test_cancelPreload_stopsPreloadingForVideo() async {
    let sut = DefaultVideoPreloader(httpClient: HTTPClientSpy())
    let video = PreloadableVideo(id: UUID(), url: anyURL(), estimatedDuration: 60)

    Task {
        await sut.preload(video, priority: .high)
    }

    sut.cancelPreload(for: video.id)

    // Verify cancellation behavior
}
```

---

## Memory Considerations

- Preloaded data stored in system cache
- Memory pressure triggers cleanup via ResourceCleanupCoordinator
- Priority levels help determine what to evict first
- Network quality limits prevent over-preloading

---

## Related Documentation

- [Network Quality](NETWORK-QUALITY.md) - Network monitoring for adaptive preloading
- [Memory Management](MEMORY-MANAGEMENT.md) - Cache cleanup
- [Startup Performance](STARTUP-PERFORMANCE.md) - TTFF improvement
- [Performance](../PERFORMANCE.md) - Overall optimization strategies
