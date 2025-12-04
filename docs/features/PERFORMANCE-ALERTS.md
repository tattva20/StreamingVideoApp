# Performance Alerts Feature

The Performance Alerts feature monitors streaming quality metrics and generates alerts when thresholds are exceeded, enabling proactive issue detection and user experience protection.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Performance Alert System                            │
│                                                                         │
│  ┌───────────────┐    ┌─────────────────────┐    ┌─────────────────┐  │
│  │ Startup Time  │───▶│                     │    │ PerformanceAlert│  │
│  └───────────────┘    │                     │    │                 │  │
│  ┌───────────────┐    │ PerformanceThresholds│──▶│ - type          │  │
│  │ Rebuffering   │───▶│                     │    │ - severity      │  │
│  └───────────────┘    │ - check thresholds  │    │ - message       │  │
│  ┌───────────────┐    │ - determine severity│    │ - suggestion    │  │
│  │ Memory        │───▶│                     │    └─────────────────┘  │
│  └───────────────┘    └─────────────────────┘           │             │
│  ┌───────────────┐              │                       │             │
│  │ Network       │──────────────┘                       ▼             │
│  └───────────────┘                            ┌─────────────────┐     │
│                                               │ Alert Consumers │     │
│  Severity: info │ warning │ critical          │ - UI Display    │     │
│                                               │ - Analytics     │     │
│                                               │ - Auto-Response │     │
│                                               └─────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Features

- **Multiple Alert Types** - Startup, buffering, memory, network, quality
- **Severity Levels** - Info, warning, critical for prioritization
- **Actionable Suggestions** - Guidance for resolution
- **Session Correlation** - Link alerts to playback sessions
- **Configurable Thresholds** - Default and strict presets
- **Identifiable Alerts** - UUID for tracking and deduplication

---

## Architecture

### PerformanceAlert

**File:** `StreamingCore/StreamingCore/Video Performance Feature/PerformanceAlert.swift`

```swift
public struct PerformanceAlert: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let sessionID: UUID
    public let type: AlertType
    public let severity: Severity
    public let timestamp: Date
    public let message: String
    public let suggestion: String?
}
```

### Alert Types

```swift
public enum AlertType: Equatable, Sendable {
    case slowStartup(duration: TimeInterval)
    case frequentRebuffering(count: Int, ratio: Double)
    case prolongedBuffering(duration: TimeInterval)
    case memoryPressure(level: MemoryPressureLevel)
    case networkDegradation(from: NetworkQuality, to: NetworkQuality)
    case playbackStalled
    case qualityDowngrade(fromBitrate: Int, toBitrate: Int)
}
```

### Severity Levels

```swift
public enum Severity: Int, Sendable, Comparable {
    case info = 0      // Informational, no action needed
    case warning = 1   // May affect experience
    case critical = 2  // Immediate attention required

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

---

## PerformanceThresholds

**File:** `StreamingCore/StreamingCore/Video Performance Feature/PerformanceThresholds.swift`

```swift
public struct PerformanceThresholds: Equatable, Sendable {
    // Startup
    public let acceptableStartupTime: TimeInterval
    public let warningStartupTime: TimeInterval
    public let criticalStartupTime: TimeInterval

    // Rebuffering
    public let acceptableRebufferingRatio: Double
    public let warningRebufferingRatio: Double
    public let criticalRebufferingRatio: Double
    public let maxBufferingDuration: TimeInterval
    public let maxBufferingEventsPerMinute: Int

    // Memory
    public let warningMemoryMB: Double
    public let criticalMemoryMB: Double
}
```

### Default Thresholds

```swift
public static let `default` = PerformanceThresholds(
    acceptableStartupTime: 2.0,
    warningStartupTime: 4.0,
    criticalStartupTime: 8.0,
    acceptableRebufferingRatio: 0.01,  // 1%
    warningRebufferingRatio: 0.03,     // 3%
    criticalRebufferingRatio: 0.05,    // 5%
    maxBufferingDuration: 10.0,
    maxBufferingEventsPerMinute: 3,
    warningMemoryMB: 150.0,
    criticalMemoryMB: 250.0
)
```

### Strict Streaming Thresholds

```swift
public static let strictStreaming = PerformanceThresholds(
    acceptableStartupTime: 1.5,
    warningStartupTime: 3.0,
    criticalStartupTime: 5.0,
    acceptableRebufferingRatio: 0.005, // 0.5%
    warningRebufferingRatio: 0.02,     // 2%
    criticalRebufferingRatio: 0.03,    // 3%
    maxBufferingDuration: 5.0,
    maxBufferingEventsPerMinute: 2,
    warningMemoryMB: 100.0,
    criticalMemoryMB: 200.0
)
```

---

## Alert Type Details

### Slow Startup

| Threshold | Severity | Action |
|-----------|----------|--------|
| < 2s | None | Excellent |
| 2-4s | Info | Monitor |
| 4-8s | Warning | Consider preloading |
| > 8s | Critical | Lower initial quality |

### Frequent Rebuffering

| Events/Min | Ratio | Severity | Action |
|------------|-------|----------|--------|
| < 1 | < 1% | None | Healthy |
| 1-2 | 1-3% | Warning | Monitor bitrate |
| 3+ | > 3% | Critical | Downgrade quality |

### Prolonged Buffering

| Duration | Severity | Action |
|----------|----------|--------|
| < 5s | Info | Normal |
| 5-10s | Warning | Check network |
| > 10s | Critical | Network issue |

### Memory Pressure

| Memory (MB) | Level | Severity | Action |
|-------------|-------|----------|--------|
| < 150 | Normal | None | Healthy |
| 150-250 | Warning | Warning | Reduce caches |
| > 250 | Critical | Critical | Clear all caches |

### Network Degradation

| Change | Severity | Action |
|--------|----------|--------|
| Excellent -> Good | Info | Monitor |
| Good -> Fair | Warning | Prepare downgrade |
| Any -> Poor/Offline | Critical | Immediate action |

---

## Usage Example

### Alert Generation

```swift
@MainActor
class PerformanceAlertGenerator {
    let thresholds: PerformanceThresholds
    let alertSubject = PassthroughSubject<PerformanceAlert, Never>()

    func checkStartupTime(_ ttff: TimeInterval, sessionID: UUID) {
        guard ttff > thresholds.acceptableStartupTime else { return }

        let severity: PerformanceAlert.Severity
        if ttff > thresholds.criticalStartupTime {
            severity = .critical
        } else if ttff > thresholds.warningStartupTime {
            severity = .warning
        } else {
            severity = .info
        }

        let alert = PerformanceAlert(
            id: UUID(),
            sessionID: sessionID,
            type: .slowStartup(duration: ttff),
            severity: severity,
            timestamp: Date(),
            message: "Video took \(String(format: "%.1f", ttff))s to start",
            suggestion: severity == .critical
                ? "Consider lowering initial bitrate or enabling preloading"
                : nil
        )

        alertSubject.send(alert)
    }

    func checkRebuffering(
        count: Int,
        ratio: Double,
        sessionID: UUID
    ) {
        guard count > 0 else { return }

        let severity: PerformanceAlert.Severity
        if ratio > thresholds.criticalRebufferingRatio ||
           count > thresholds.maxBufferingEventsPerMinute {
            severity = .critical
        } else if ratio > thresholds.warningRebufferingRatio {
            severity = .warning
        } else {
            return // Acceptable
        }

        let alert = PerformanceAlert(
            id: UUID(),
            sessionID: sessionID,
            type: .frequentRebuffering(count: count, ratio: ratio),
            severity: severity,
            timestamp: Date(),
            message: "\(count) buffering events (\(String(format: "%.1f", ratio * 100))% of playback)",
            suggestion: "Network conditions degraded. Quality reduction recommended."
        )

        alertSubject.send(alert)
    }

    func checkMemoryPressure(
        level: MemoryPressureLevel,
        sessionID: UUID
    ) {
        guard level != .normal else { return }

        let severity: PerformanceAlert.Severity = level == .critical ? .critical : .warning

        let alert = PerformanceAlert(
            id: UUID(),
            sessionID: sessionID,
            type: .memoryPressure(level: level),
            severity: severity,
            timestamp: Date(),
            message: "Memory pressure: \(level)",
            suggestion: "Clearing caches to free memory"
        )

        alertSubject.send(alert)
    }
}
```

### Alert Consumption

```swift
class AlertConsumer {
    private var cancellables = Set<AnyCancellable>()

    func observeAlerts(_ alertPublisher: AnyPublisher<PerformanceAlert, Never>) {
        alertPublisher
            .sink { [weak self] alert in
                self?.handleAlert(alert)
            }
            .store(in: &cancellables)
    }

    private func handleAlert(_ alert: PerformanceAlert) {
        // Log for analytics
        analytics.track(.performanceAlert(
            type: alert.type,
            severity: alert.severity,
            sessionID: alert.sessionID
        ))

        // Take automatic action based on severity
        switch alert.severity {
        case .critical:
            handleCriticalAlert(alert)
        case .warning:
            handleWarningAlert(alert)
        case .info:
            // Log only
            break
        }

        // Show UI notification for critical
        if alert.severity == .critical {
            notificationService.show(
                title: "Playback Issue",
                message: alert.message
            )
        }
    }

    private func handleCriticalAlert(_ alert: PerformanceAlert) {
        switch alert.type {
        case .slowStartup:
            bitrateAdapter.setInitialBitrateLevel(.low)

        case .frequentRebuffering:
            bitrateAdapter.requestDowngrade()

        case .memoryPressure:
            resourceCleanupCoordinator.cleanupAll()

        case .networkDegradation(_, let to) where to <= .poor:
            bitrateAdapter.setMaxBitrateLevel(.low)

        default:
            break
        }
    }
}
```

---

## Alert Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      Alert Flow                             │
│                                                             │
│  Performance Event                                          │
│         │                                                   │
│         ▼                                                   │
│  ┌─────────────────────┐                                   │
│  │ Check Thresholds    │                                   │
│  │ - acceptable?       │─── Yes ──▶ No alert              │
│  │ - warning?          │                                   │
│  │ - critical?         │                                   │
│  └─────────────────────┘                                   │
│         │ No                                                │
│         ▼                                                   │
│  ┌─────────────────────┐                                   │
│  │ Create Alert        │                                   │
│  │ - type              │                                   │
│  │ - severity          │                                   │
│  │ - message           │                                   │
│  │ - suggestion        │                                   │
│  └─────────────────────┘                                   │
│         │                                                   │
│         ▼                                                   │
│  ┌─────────────────────┐                                   │
│  │ Dispatch Alert      │                                   │
│  │ - Analytics         │                                   │
│  │ - Auto-response     │                                   │
│  │ - UI notification   │                                   │
│  └─────────────────────┘                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Testing

### Unit Tests

```swift
func test_slowStartupAlert_critical_exceedsCriticalThreshold() {
    let thresholds = PerformanceThresholds.default
    let ttff: TimeInterval = 10.0 // > 8s critical

    let severity = evaluateStartupSeverity(ttff, thresholds: thresholds)

    XCTAssertEqual(severity, .critical)
}

func test_rebufferingAlert_warning_exceedsWarningRatio() {
    let thresholds = PerformanceThresholds.default
    let ratio = 0.04 // 4%, between warning (3%) and critical (5%)

    let severity = evaluateRebufferingSeverity(ratio: ratio, thresholds: thresholds)

    XCTAssertEqual(severity, .warning)
}

func test_alert_containsSessionID() {
    let sessionID = UUID()
    let alert = PerformanceAlert(
        id: UUID(),
        sessionID: sessionID,
        type: .slowStartup(duration: 5.0),
        severity: .warning,
        timestamp: Date(),
        message: "Test",
        suggestion: nil
    )

    XCTAssertEqual(alert.sessionID, sessionID)
}

func test_severity_comparison() {
    XCTAssertTrue(PerformanceAlert.Severity.info < .warning)
    XCTAssertTrue(PerformanceAlert.Severity.warning < .critical)
}
```

---

## Related Documentation

- [Startup Performance](STARTUP-PERFORMANCE.md) - TTFF monitoring
- [Rebuffering Detection](REBUFFERING-DETECTION.md) - Stall tracking
- [Memory Management](MEMORY-MANAGEMENT.md) - Pressure handling
- [Network Quality](NETWORK-QUALITY.md) - Connection monitoring
