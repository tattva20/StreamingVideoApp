# Structured Logging Feature

The Structured Logging feature provides a comprehensive logging system with multiple destinations, log levels, and correlation tracking.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Logging Pipeline                          │
│                                                             │
│  VideoPlayer ──▶ LoggingDecorator ──▶ CompositeLogger      │
│                                              │              │
│                         ┌────────────────────┼───────────┐  │
│                         │                    │           │  │
│                         ▼                    ▼           ▼  │
│                   ConsoleLogger        OSLogLogger   Remote │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Multiple Log Levels** - debug, info, warning, error, critical
- **Composite Logging** - Log to multiple destinations simultaneously
- **Structured Context** - Subsystem, category, correlation ID, metadata
- **Correlation Tracking** - Link related log entries
- **Platform Integration** - OSLog for Apple's unified logging
- **Testable Design** - NullLogger for unit tests

---

## Architecture

### Logger Protocol

**File:** `StreamingCore/StreamingCore/Structured Logging Feature/Logger.swift`

```swift
public protocol Logger: Sendable {
    func log(_ entry: LogEntry)
}
```

### Log Entry

**File:** `StreamingCore/StreamingCore/Structured Logging Feature/Domain/LogEntry.swift`

```swift
public struct LogEntry: Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let context: LogContext

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        context: LogContext
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.context = context
    }
}
```

### Log Context

**File:** `StreamingCore/StreamingCore/Structured Logging Feature/Domain/LogContext.swift`

```swift
public struct LogContext: Sendable {
    public let subsystem: String
    public let category: String
    public let correlationID: UUID
    public let metadata: [String: String]

    public init(
        subsystem: String,
        category: String,
        correlationID: UUID = UUID(),
        metadata: [String: String] = [:]
    ) {
        self.subsystem = subsystem
        self.category = category
        self.correlationID = correlationID
        self.metadata = metadata
    }
}
```

### Log Levels

**File:** `StreamingCore/StreamingCore/Structured Logging Feature/Domain/LogLevel.swift`

```swift
public enum LogLevel: String, Sendable, Comparable {
    case debug
    case info
    case warning
    case error
    case critical

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.priority < rhs.priority
    }

    private var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
}
```

---

## Logger Implementations

### ConsoleLogger

**File:** `StreamingCore/StreamingCore/Structured Logging Feature/ConsoleLogger.swift`

```swift
public final class ConsoleLogger: Logger, @unchecked Sendable {
    private let minimumLevel: LogLevel
    private let dateFormatter: DateFormatter

    public init(minimumLevel: LogLevel = .debug) {
        self.minimumLevel = minimumLevel
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        let timestamp = dateFormatter.string(from: entry.timestamp)
        let level = entry.level.rawValue.uppercased().padding(toLength: 8, withPad: " ", startingAt: 0)
        let correlation = String(entry.context.correlationID.uuidString.prefix(8))

        print("[\(timestamp)] [\(level)] [\(correlation)] [\(entry.context.category)] \(entry.message)")

        if !entry.context.metadata.isEmpty {
            print("  metadata: \(entry.context.metadata)")
        }
    }
}
```

### OSLogLogger

**File:** `StreamingCoreiOS/Structured Logging iOS/OSLogLogger.swift`

```swift
import os.log

public final class OSLogLogger: Logger, @unchecked Sendable {
    private let logger: os.Logger

    public init(subsystem: String, category: String) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    public func log(_ entry: LogEntry) {
        let message = "[\(entry.context.correlationID)] \(entry.message)"

        switch entry.level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
    }
}
```

### CompositeLogger

**File:** `StreamingCore/StreamingCore/Structured Logging Feature/CompositeLogger.swift`

```swift
public final class CompositeLogger: Logger, @unchecked Sendable {
    private let loggers: [any Logger]

    public init(loggers: [any Logger]) {
        self.loggers = loggers
    }

    public func log(_ entry: LogEntry) {
        for logger in loggers {
            logger.log(entry)
        }
    }
}
```

### NullLogger

**File:** `StreamingCore/StreamingCore/Structured Logging Feature/NullLogger.swift`

```swift
public final class NullLogger: Logger, Sendable {
    public init() {}

    public func log(_ entry: LogEntry) {
        // No-op
    }
}
```

---

## Logging Decorator

**File:** `StreamingVideoApp/LoggingVideoPlayerDecorator.swift`

```swift
@MainActor
public final class LoggingVideoPlayerDecorator: VideoPlayer {
    private let decoratee: VideoPlayer
    private let logger: Logger
    private let correlationID: UUID

    public init(decoratee: VideoPlayer, logger: Logger, correlationID: UUID = UUID()) {
        self.decoratee = decoratee
        self.logger = logger
        self.correlationID = correlationID
    }

    public func load(url: URL) {
        log(.info, "Loading video from \(url)")
        decoratee.load(url: url)
    }

    public func play() {
        log(.info, "Play requested")
        decoratee.play()
    }

    public func pause() {
        log(.info, "Pause requested")
        decoratee.pause()
    }

    public func seek(to time: TimeInterval) {
        log(.info, "Seek requested to \(time)s")
        decoratee.seek(to: time)
    }

    private func log(_ level: LogLevel, _ message: String) {
        let entry = LogEntry(
            level: level,
            message: message,
            context: LogContext(
                subsystem: "com.streamingvideoapp",
                category: "VideoPlayer",
                correlationID: correlationID
            )
        )
        logger.log(entry)
    }
}
```

---

## Correlation Tracking

Correlation IDs link related log entries across a session:

```
[12:34:56.789] [INFO    ] [a1b2c3d4] [VideoPlayer] Loading video from https://example.com/video.mp4
[12:34:57.123] [INFO    ] [a1b2c3d4] [VideoPlayer] Player ready
[12:34:57.456] [INFO    ] [a1b2c3d4] [VideoPlayer] Play requested
[12:35:00.000] [WARNING ] [a1b2c3d4] [VideoPlayer] Buffering started
[12:35:02.500] [INFO    ] [a1b2c3d4] [VideoPlayer] Buffering ended
[12:38:00.000] [INFO    ] [a1b2c3d4] [VideoPlayer] Playback completed
```

All entries with `[a1b2c3d4]` belong to the same playback session.

---

## Composition

```swift
// In SceneDelegate
func makeLogger() -> Logger {
    #if DEBUG
    return CompositeLogger(loggers: [
        ConsoleLogger(minimumLevel: .debug),
        OSLogLogger(subsystem: "com.streamingvideoapp", category: "General")
    ])
    #else
    return CompositeLogger(loggers: [
        OSLogLogger(subsystem: "com.streamingvideoapp", category: "General")
        // Add remote logger for production
    ])
    #endif
}

func makeVideoPlayer() -> VideoPlayer {
    let basePlayer = AVPlayerVideoPlayer(player: avPlayer)
    let correlationID = UUID()

    return LoggingVideoPlayerDecorator(
        decoratee: basePlayer,
        logger: logger,
        correlationID: correlationID
    )
}
```

---

## Log Output Example

### Console Output

```
[14:32:15.123] [INFO    ] [a1b2c3d4] [VideoPlayer] Loading video from https://example.com/video.mp4
  metadata: ["videoId": "550e8400-e29b-41d4-a716-446655440000"]
[14:32:16.456] [INFO    ] [a1b2c3d4] [VideoPlayer] Play requested
[14:32:45.789] [WARNING ] [a1b2c3d4] [VideoPlayer] Buffering started
[14:32:47.123] [INFO    ] [a1b2c3d4] [VideoPlayer] Buffering ended, duration: 2.3s
[14:35:00.000] [INFO    ] [a1b2c3d4] [VideoPlayer] Playback completed
```

### OSLog (Console.app)

```
type: info
subsystem: com.streamingvideoapp
category: VideoPlayer
message: [a1b2c3d4-...] Play requested
```

---

## Testing

### Using NullLogger

```swift
func makeSUT() -> (VideoPlayer, VideoPlayerSpy) {
    let spy = VideoPlayerSpy()
    let sut = LoggingVideoPlayerDecorator(
        decoratee: spy,
        logger: NullLogger()  // No logging noise in tests
    )
    return (sut, spy)
}
```

### Verifying Logs

```swift
final class LoggerSpy: Logger {
    var loggedEntries: [LogEntry] = []

    func log(_ entry: LogEntry) {
        loggedEntries.append(entry)
    }
}

func test_play_logsInfoMessage() {
    let loggerSpy = LoggerSpy()
    let sut = LoggingVideoPlayerDecorator(
        decoratee: VideoPlayerSpy(),
        logger: loggerSpy
    )

    sut.play()

    XCTAssertEqual(loggerSpy.loggedEntries.count, 1)
    XCTAssertEqual(loggerSpy.loggedEntries[0].level, .info)
    XCTAssertTrue(loggerSpy.loggedEntries[0].message.contains("Play"))
}
```

---

## Related Documentation

- [Video Playback](VIDEO-PLAYBACK.md) - Player integration
- [Analytics](ANALYTICS.md) - Event tracking
- [Design Patterns](../DESIGN-PATTERNS.md) - Decorator, Composite patterns
