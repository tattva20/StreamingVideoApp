# Rebuffering Detection Feature

The Rebuffering Detection feature monitors playback stalls, tracks buffering events, and provides metrics for quality-of-experience analysis.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Rebuffering Detection                                │
│                                                                         │
│  ┌───────────────┐    ┌─────────────────────┐    ┌─────────────────┐  │
│  │ AVPlayer      │    │ RebufferingMonitor  │    │ Consumers       │  │
│  │ Events        │───▶│                     │───▶│                 │  │
│  └───────────────┘    │ - bufferingStarted  │    │ - ABR Strategy  │  │
│                       │ - bufferingEnded    │    │ - Analytics     │  │
│  ┌───────────────┐    │ - state             │    │ - Alerts        │  │
│  │ Buffer Empty  │───▶│ - eventsInLastMin   │    └─────────────────┘  │
│  └───────────────┘    └─────────────────────┘                         │
│                                                                         │
│  Metrics: Count │ Duration │ Events/Min │ Total Time                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Features

- **Event Tracking** - Records each buffering start/end with timestamps
- **Duration Measurement** - Calculates individual and total buffering time
- **Rate Limiting Detection** - Tracks events per minute for severity
- **State Exposure** - Real-time access to current buffering state
- **Reset Capability** - Clear metrics for new sessions
- **Thread-Safe** - @MainActor isolation for predictable behavior

---

## Architecture

### RebufferingMonitor

**File:** `StreamingCore/StreamingCore/Video Performance Feature/RebufferingMonitor.swift`

```swift
@MainActor
public final class RebufferingMonitor {

    // MARK: - State

    public struct State: Equatable, Sendable {
        public let isBuffering: Bool
        public let bufferingStartTime: Date?
        public let bufferingEvents: [BufferingEvent]
        public let totalBufferingDuration: TimeInterval

        public var currentBufferingDuration: TimeInterval? {
            guard isBuffering, let start = bufferingStartTime else { return nil }
            return Date().timeIntervalSince(start)
        }

        public var bufferingCount: Int {
            bufferingEvents.count
        }
    }

    // MARK: - Buffering Event

    public struct BufferingEvent: Equatable, Sendable {
        public let startTime: Date
        public let endTime: Date

        public var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
    }
}
```

---

## Core Methods

```swift
/// Called when buffering starts
public func bufferingStarted() {
    guard !_isBuffering else { return }
    _isBuffering = true
    bufferingStartTime = currentDate()
}

/// Called when buffering ends, returns the completed event
public func bufferingEnded() -> BufferingEvent? {
    guard _isBuffering, let startTime = bufferingStartTime else { return nil }

    _isBuffering = false
    let endTime = currentDate()
    let event = BufferingEvent(startTime: startTime, endTime: endTime)

    bufferingEvents.append(event)
    totalBufferingDuration += event.duration
    bufferingStartTime = nil

    return event
}

/// Current state snapshot
public var state: State {
    State(
        isBuffering: _isBuffering,
        bufferingStartTime: bufferingStartTime,
        bufferingEvents: bufferingEvents,
        totalBufferingDuration: totalBufferingDuration
    )
}

/// Reset all metrics
public func reset() {
    _isBuffering = false
    bufferingStartTime = nil
    bufferingEvents = []
    totalBufferingDuration = 0
}

/// Count of events in the last 60 seconds
public func eventsInLastMinute() -> Int {
    let oneMinuteAgo = currentDate().addingTimeInterval(-60)
    return bufferingEvents.filter { $0.startTime > oneMinuteAgo }.count
}
```

---

## State Properties

| Property | Type | Description |
|----------|------|-------------|
| `isBuffering` | Bool | Currently in buffering state |
| `bufferingStartTime` | Date? | When current buffering started |
| `bufferingEvents` | [BufferingEvent] | History of completed events |
| `totalBufferingDuration` | TimeInterval | Sum of all buffering time |
| `currentBufferingDuration` | TimeInterval? | Duration of ongoing buffering |
| `bufferingCount` | Int | Total number of events |

---

## Usage Example

### Basic Monitoring

```swift
@MainActor
class VideoPlayerCoordinator {
    let rebufferingMonitor = RebufferingMonitor()

    func observePlayer(_ player: AVPlayer) {
        player.observe(\.timeControlStatus) { [weak self] player, _ in
            self?.handleTimeControlStatus(player.timeControlStatus)
        }

        player.currentItem?.observe(\.isPlaybackBufferEmpty) { [weak self] item, _ in
            if item.isPlaybackBufferEmpty {
                self?.rebufferingMonitor.bufferingStarted()
            }
        }

        player.currentItem?.observe(\.isPlaybackLikelyToKeepUp) { [weak self] item, _ in
            if item.isPlaybackLikelyToKeepUp {
                if let event = self?.rebufferingMonitor.bufferingEnded() {
                    self?.handleBufferingEvent(event)
                }
            }
        }
    }

    func handleBufferingEvent(_ event: RebufferingMonitor.BufferingEvent) {
        analytics.track(.bufferingEnded(duration: event.duration))

        // Check for excessive rebuffering
        let eventsInLastMinute = rebufferingMonitor.eventsInLastMinute()
        if eventsInLastMinute >= 3 {
            // Trigger quality downgrade
            bitrateAdapter.requestDowngrade()
        }
    }
}
```

### Integration with ABR

```swift
func evaluateBitrateDecision() {
    let state = rebufferingMonitor.state
    let playbackDuration = player.currentTime().seconds

    // Calculate rebuffering ratio
    let rebufferingRatio = playbackDuration > 0
        ? state.totalBufferingDuration / playbackDuration
        : 0

    // Use ratio in bitrate decision
    if let newBitrate = bitrateStrategy.shouldDowngrade(
        currentBitrate: currentBitrate,
        rebufferingRatio: rebufferingRatio,
        networkQuality: networkMonitor.currentQuality,
        availableLevels: availableLevels
    ) {
        applyBitrate(newBitrate)
    }
}
```

---

## Rebuffering Metrics

### Key Performance Indicators

| Metric | Formula | Target |
|--------|---------|--------|
| Rebuffering Ratio | Total Buffering / Total Playback | < 1% |
| Events Per Minute | Count in last 60s | < 2 |
| Average Duration | Total Duration / Event Count | < 3s |
| Max Duration | Longest single event | < 10s |

### Severity Levels

```
Excellent: Ratio < 0.01, Events/min < 1
Good:      Ratio < 0.03, Events/min < 2
Warning:   Ratio < 0.05, Events/min < 3
Critical:  Ratio >= 0.05 OR Events/min >= 3
```

---

## Event Timeline Example

```
Time    Event               State
─────────────────────────────────────────────────
0:00    Video starts        isBuffering: false
0:45    Buffer empty        isBuffering: true, start: 0:45
0:48    Buffer ready        Event recorded (3s), total: 3s
1:30    Buffer empty        isBuffering: true, start: 1:30
1:32    Buffer ready        Event recorded (2s), total: 5s
2:00    Check metrics       bufferingCount: 2, ratio: 4.2%
```

---

## Testing

### Unit Tests

```swift
@MainActor
func test_bufferingStarted_setsIsBufferingTrue() {
    let sut = RebufferingMonitor()

    sut.bufferingStarted()

    XCTAssertTrue(sut.state.isBuffering)
}

@MainActor
func test_bufferingEnded_recordsEvent() {
    let fixedDate = Date()
    var callCount = 0
    let sut = RebufferingMonitor(currentDate: {
        callCount += 1
        return fixedDate.addingTimeInterval(Double(callCount) * 2)
    })

    sut.bufferingStarted()
    let event = sut.bufferingEnded()

    XCTAssertNotNil(event)
    XCTAssertEqual(event?.duration, 2.0, accuracy: 0.1)
    XCTAssertEqual(sut.state.bufferingCount, 1)
}

@MainActor
func test_totalBufferingDuration_sumsAllEvents() {
    let sut = RebufferingMonitor()

    // First event (2s)
    sut.bufferingStarted()
    _ = sut.bufferingEnded()

    // Second event (3s)
    sut.bufferingStarted()
    _ = sut.bufferingEnded()

    XCTAssertGreaterThan(sut.state.totalBufferingDuration, 0)
}

@MainActor
func test_eventsInLastMinute_filtersOldEvents() {
    let baseTime = Date()
    var currentTime = baseTime
    let sut = RebufferingMonitor(currentDate: { currentTime })

    // Event 90 seconds ago
    currentTime = baseTime.addingTimeInterval(-90)
    sut.bufferingStarted()
    currentTime = baseTime.addingTimeInterval(-89)
    _ = sut.bufferingEnded()

    // Event 30 seconds ago
    currentTime = baseTime.addingTimeInterval(-30)
    sut.bufferingStarted()
    currentTime = baseTime.addingTimeInterval(-29)
    _ = sut.bufferingEnded()

    currentTime = baseTime
    XCTAssertEqual(sut.eventsInLastMinute(), 1)
}

@MainActor
func test_reset_clearsAllState() {
    let sut = RebufferingMonitor()

    sut.bufferingStarted()
    _ = sut.bufferingEnded()
    sut.reset()

    XCTAssertFalse(sut.state.isBuffering)
    XCTAssertEqual(sut.state.bufferingCount, 0)
    XCTAssertEqual(sut.state.totalBufferingDuration, 0)
}
```

---

## Integration Points

```
┌─────────────────────────────────────────────────────────────┐
│                    Integration Flow                         │
│                                                             │
│  AVPlayerPerformanceObserver                                │
│         │                                                   │
│         │ bufferingStarted/Ended                           │
│         ▼                                                   │
│  RebufferingMonitor                                        │
│         │                                                   │
│         ├──▶ BitrateStrategy (rebufferingRatio)           │
│         ├──▶ PerformanceAlerts (threshold checks)          │
│         ├──▶ Analytics (event tracking)                    │
│         └──▶ Dashboard (QoE metrics)                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Related Documentation

- [Adaptive Bitrate](ADAPTIVE-BITRATE.md) - Uses rebuffering ratio
- [Performance Alerts](PERFORMANCE-ALERTS.md) - Threshold monitoring
- [Analytics](ANALYTICS.md) - Event tracking
- [AVPlayer Integration](AVPLAYER-INTEGRATION.md) - Event source
