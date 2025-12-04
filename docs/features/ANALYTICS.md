# Analytics Feature

The Analytics feature tracks playback events, user engagement, and performance metrics for video streaming sessions.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Analytics Pipeline                        │
│                                                             │
│  VideoPlayer ──▶ AnalyticsDecorator ──▶ AnalyticsService   │
│                                              │              │
│                                              ▼              │
│                                        AnalyticsStore       │
│                                              │              │
│                                              ▼              │
│                                        Remote Server        │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Session Tracking** - Track complete playback sessions
- **Event Logging** - Record play, pause, seek, complete events
- **Engagement Metrics** - Watch time, completion rate
- **Performance Metrics** - Time to first frame, buffering ratio
- **Device Info** - Track device type, OS version, app version
- **Correlation IDs** - Link related events

---

## Architecture

### PlaybackAnalyticsLogger Protocol

**File:** `StreamingCore/StreamingCore/Video Analytics Feature/PlaybackAnalyticsLogger.swift`

```swift
@MainActor
public protocol PlaybackAnalyticsLogger: AnyObject {
    func startSession(
        videoID: UUID,
        videoTitle: String,
        videoDuration: TimeInterval,
        deviceInfo: DeviceInfo,
        appVersion: String
    ) async

    func log(_ event: PlaybackEventType, position: TimeInterval) async
    func endSession() async
}
```

### PlaybackAnalyticsService

**File:** `StreamingCore/StreamingCore/Video Analytics Feature/PlaybackAnalyticsService.swift`

```swift
@MainActor
public final class PlaybackAnalyticsService: PlaybackAnalyticsLogger {
    private let store: AnalyticsStore
    private let currentDate: () -> Date
    private var currentSession: PlaybackSession?
    private var events: [PlaybackEvent] = []

    public func startSession(
        videoID: UUID,
        videoTitle: String,
        videoDuration: TimeInterval,
        deviceInfo: DeviceInfo,
        appVersion: String
    ) async {
        currentSession = PlaybackSession(
            id: UUID(),
            videoID: videoID,
            videoTitle: videoTitle,
            videoDuration: videoDuration,
            startTime: currentDate(),
            deviceInfo: deviceInfo,
            appVersion: appVersion
        )
        events = []
    }

    public func log(_ event: PlaybackEventType, position: TimeInterval) async {
        let playbackEvent = PlaybackEvent(
            id: UUID(),
            type: event,
            timestamp: currentDate(),
            position: position
        )
        events.append(playbackEvent)
    }

    public func endSession() async {
        guard var session = currentSession else { return }
        session.endTime = currentDate()
        session.events = events

        try? await store.save(session)
        currentSession = nil
        events = []
    }
}
```

---

## Event Types

**File:** `StreamingCore/StreamingCore/Video Analytics Feature/PlaybackEvent.swift`

```swift
public enum PlaybackEventType: String, Codable, Sendable {
    // Playback Events
    case videoPlayed
    case videoPaused
    case videoSeeked
    case videoCompleted
    case videoAbandoned

    // Quality Events
    case qualityChanged
    case bitrateUpgraded
    case bitrateDowngraded

    // Error Events
    case playbackError
    case bufferingStarted
    case bufferingEnded

    // User Events
    case fullscreenEntered
    case fullscreenExited
    case pipStarted
    case pipStopped
}

public struct PlaybackEvent: Equatable, Sendable {
    public let id: UUID
    public let type: PlaybackEventType
    public let timestamp: Date
    public let position: TimeInterval
    public let metadata: [String: String]?
}
```

---

## Session Model

**File:** `StreamingCore/StreamingCore/Video Analytics Feature/PlaybackSession.swift`

```swift
public struct PlaybackSession: Equatable, Sendable {
    public let id: UUID
    public let videoID: UUID
    public let videoTitle: String
    public let videoDuration: TimeInterval
    public let startTime: Date
    public var endTime: Date?
    public let deviceInfo: DeviceInfo
    public let appVersion: String
    public var events: [PlaybackEvent]

    public var watchDuration: TimeInterval {
        guard let endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }

    public var completionRate: Double {
        guard videoDuration > 0 else { return 0 }
        return min(watchDuration / videoDuration, 1.0)
    }
}

public struct DeviceInfo: Equatable, Codable, Sendable {
    public let model: String
    public let osVersion: String
    public let screenSize: String
}
```

---

## Engagement Metrics

**File:** `StreamingCore/StreamingCore/Video Analytics Feature/EngagementMetrics.swift`

```swift
public struct EngagementMetrics: Equatable, Sendable {
    public let totalWatchTime: TimeInterval
    public let averageWatchTime: TimeInterval
    public let completionRate: Double
    public let playCount: Int
    public let pauseCount: Int
    public let seekCount: Int
    public let abandonmentRate: Double

    public static func calculate(from sessions: [PlaybackSession]) -> EngagementMetrics {
        let totalWatch = sessions.reduce(0) { $0 + $1.watchDuration }
        let avgWatch = sessions.isEmpty ? 0 : totalWatch / Double(sessions.count)
        let completions = sessions.filter { $0.completionRate >= 0.9 }.count
        let abandonments = sessions.filter { $0.completionRate < 0.25 }.count

        return EngagementMetrics(
            totalWatchTime: totalWatch,
            averageWatchTime: avgWatch,
            completionRate: Double(completions) / Double(sessions.count),
            playCount: countEvents(.videoPlayed, in: sessions),
            pauseCount: countEvents(.videoPaused, in: sessions),
            seekCount: countEvents(.videoSeeked, in: sessions),
            abandonmentRate: Double(abandonments) / Double(sessions.count)
        )
    }
}
```

---

## Performance Tracking

**File:** `StreamingCore/StreamingCore/Video Analytics Feature/PerformanceTracker.swift`

```swift
public final class PerformanceTracker {
    private var loadStartTime: Date?
    private var firstFrameTime: Date?
    private var bufferingEvents: [(start: Date, end: Date?)] = []

    public func recordLoadStart() {
        loadStartTime = Date()
    }

    public func recordFirstFrame() {
        firstFrameTime = Date()
    }

    public func recordBufferingStart() {
        bufferingEvents.append((start: Date(), end: nil))
    }

    public func recordBufferingEnd() {
        guard var last = bufferingEvents.popLast() else { return }
        last.end = Date()
        bufferingEvents.append(last)
    }

    public var timeToFirstFrame: TimeInterval? {
        guard let start = loadStartTime, let end = firstFrameTime else { return nil }
        return end.timeIntervalSince(start)
    }

    public var totalBufferingDuration: TimeInterval {
        bufferingEvents.compactMap { event in
            guard let end = event.end else { return nil }
            return end.timeIntervalSince(event.start)
        }.reduce(0, +)
    }

    public func calculateMetrics(sessionDuration: TimeInterval) -> PerformanceMetrics {
        PerformanceMetrics(
            timeToFirstFrame: timeToFirstFrame ?? 0,
            bufferingDuration: totalBufferingDuration,
            bufferingCount: bufferingEvents.count,
            rebufferingRatio: sessionDuration > 0
                ? totalBufferingDuration / sessionDuration
                : 0
        )
    }
}
```

---

## Analytics Decorator

**File:** `StreamingVideoApp/AnalyticsVideoPlayerDecorator.swift`

```swift
@MainActor
public final class AnalyticsVideoPlayerDecorator: VideoPlayer {
    private let decoratee: VideoPlayer
    private let analyticsLogger: PlaybackAnalyticsLogger

    public var statePublisher: AnyPublisher<PlaybackState, Never> {
        decoratee.statePublisher
    }

    public func play() {
        Task { [weak self] in
            await self?.analyticsLogger.log(.videoPlayed, position: currentTime)
        }
        decoratee.play()
    }

    public func pause() {
        Task { [weak self] in
            await self?.analyticsLogger.log(.videoPaused, position: currentTime)
        }
        decoratee.pause()
    }

    public func seek(to time: TimeInterval) {
        Task { [weak self] in
            await self?.analyticsLogger.log(.videoSeeked, position: time)
        }
        decoratee.seek(to: time)
    }
}
```

---

## Storage

### AnalyticsStore Protocol

**File:** `StreamingCore/StreamingCore/Video Analytics Cache/AnalyticsStore.swift`

```swift
public protocol AnalyticsStore: Sendable {
    func save(_ session: PlaybackSession) async throws
    func retrieve() async throws -> [PlaybackSession]
    func delete(_ sessionID: UUID) async throws
}
```

### In-Memory Implementation

**File:** `StreamingCore/StreamingCore/Video Analytics Cache/Infrastructure/InMemory/InMemoryAnalyticsStore.swift`

```swift
public actor InMemoryAnalyticsStore: AnalyticsStore {
    private var sessions: [PlaybackSession] = []

    public func save(_ session: PlaybackSession) async throws {
        sessions.append(session)
    }

    public func retrieve() async throws -> [PlaybackSession] {
        sessions
    }

    public func delete(_ sessionID: UUID) async throws {
        sessions.removeAll { $0.id == sessionID }
    }
}
```

---

## Composition

```swift
// In VideoPlayerComposer
func composePlayer(video: Video) -> VideoPlayer {
    let basePlayer = AVPlayerVideoPlayer(player: avPlayer)

    let analyticsService = PlaybackAnalyticsService(store: analyticsStore)
    Task {
        await analyticsService.startSession(
            videoID: video.id,
            videoTitle: video.title,
            videoDuration: video.duration,
            deviceInfo: DeviceInfoProvider.current,
            appVersion: Bundle.main.appVersion
        )
    }

    return AnalyticsVideoPlayerDecorator(
        decoratee: basePlayer,
        analyticsLogger: analyticsService
    )
}
```

---

## Event Timeline Example

```
00:00 ──▶ videoPlayed
00:15 ──▶ videoPaused
00:15 ──▶ videoPlayed
00:30 ──▶ bufferingStarted
00:32 ──▶ bufferingEnded
01:00 ──▶ videoSeeked (to 02:30)
02:30 ──▶ videoPlayed
03:00 ──▶ videoCompleted
```

---

## Testing

### Service Tests

```swift
func test_log_recordsEvent() async {
    let store = InMemoryAnalyticsStore()
    let sut = PlaybackAnalyticsService(store: store)

    await sut.startSession(videoID: UUID(), ...)
    await sut.log(.videoPlayed, position: 0)
    await sut.log(.videoPaused, position: 30)
    await sut.endSession()

    let sessions = try await store.retrieve()
    XCTAssertEqual(sessions.first?.events.count, 2)
}
```

### Decorator Tests

```swift
func test_play_logsPlayEvent() async {
    let (sut, spy) = makeSUT()

    sut.play()
    await Task.yield()

    XCTAssertEqual(spy.loggedEvents, [.videoPlayed])
}
```

---

## Related Documentation

- [Video Playback](VIDEO-PLAYBACK.md) - Player integration
- [Logging](LOGGING.md) - Structured logging
- [Performance](../PERFORMANCE.md) - Performance metrics
- [Design Patterns](../DESIGN-PATTERNS.md) - Decorator pattern
