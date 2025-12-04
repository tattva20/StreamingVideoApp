# Audio Session Feature

The Audio Session feature manages iOS audio session configuration for video playback, handling interruptions, routing changes, and proper audio category setup.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      Audio Session Management                           │
│                                                                         │
│  ┌─────────────────────┐    ┌─────────────────────┐                    │
│  │ AudioSession        │    │ AVAudioSession      │                    │
│  │ Configuring         │───▶│ Adapter             │                    │
│  └─────────────────────┘    └─────────────────────┘                    │
│                                      │                                  │
│                                      ▼                                  │
│                             ┌─────────────────────┐                    │
│                             │ AVAudioSession      │                    │
│                             │ .sharedInstance()   │                    │
│                             └─────────────────────┘                    │
│                                      │                                  │
│  Interruptions:                      │                                  │
│  ┌─────────────────────┐            │                                  │
│  │ Phone Call          │──┐         │                                  │
│  │ Siri                │  │         │                                  │
│  │ Alarm               │  ├────────▶│ Pause/Resume Playback           │
│  │ Other App Audio     │──┘         │                                  │
│  └─────────────────────┘            │                                  │
│                                      │                                  │
│  Category: .playback                 │                                  │
│  Mode: .moviePlayback (optional)     │                                  │
│  Options: .mixWithOthers (optional)  │                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Features

- **Category Configuration** - Set appropriate audio category for video playback
- **Session Activation** - Properly activate/deactivate the audio session
- **Protocol-Based Design** - Testable abstraction over AVAudioSession
- **Interruption Handling** - Respond to phone calls, Siri, alarms
- **Clean Architecture** - Separated from player implementation

---

## Architecture

### AudioSessionConfiguring Protocol

**File:** `StreamingCoreiOS/Video UI/Controllers/AudioSessionConfiguring.swift`

```swift
public protocol AudioSessionConfiguring {
    func configureForPlayback() throws
}
```

### AudioSessionProtocol

**File:** `StreamingCoreiOS/Video UI/Controllers/AudioSessionProtocol.swift`

```swift
public protocol AudioSessionProtocol {
    func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws
    func setActive(_ active: Bool) throws
}

extension AVAudioSession: AudioSessionProtocol {
    public func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws {
        try setCategory(category, mode: .default, options: options)
    }
}
```

---

## AVAudioSessionAdapter

**File:** `StreamingCoreiOS/Video UI/Controllers/AVAudioSessionAdapter.swift`

```swift
public final class AVAudioSessionAdapter: AudioSessionConfiguring {
    private let session: AudioSessionProtocol

    public convenience init() {
        self.init(session: AVAudioSession.sharedInstance())
    }

    init(session: AudioSessionProtocol) {
        self.session = session
    }

    public func configureForPlayback() throws {
        try session.setCategory(.playback, options: [])
        try session.setActive(true)
    }
}
```

---

## Audio Session Categories

| Category | Description | Use Case |
|----------|-------------|----------|
| `.playback` | Continues during silent mode | Video/music playback |
| `.ambient` | Mixable, silenced in silent mode | Background sounds |
| `.soloAmbient` | Default, silenced in silent mode | Single app audio |
| `.playAndRecord` | For recording and playback | Video calls |

For video streaming, `.playback` is the correct choice as it:
- Continues audio when the device is in silent mode
- Stops other app's audio when playing
- Works with lock screen controls

---

## Interruption Handling

Interruptions are handled by the `AVPlayerStateAdapter` through notification observation:

```swift
private func setupNotificationObservers() {
    NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
        .sink { [weak self] notification in
            self?.handleAudioSessionInterruption(notification)
        }
        .store(in: &cancellables)
}

private func handleAudioSessionInterruption(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
        return
    }

    switch type {
    case .began:
        // Interruption started (phone call, Siri, etc.)
        sendAction(.audioSessionInterrupted)

    case .ended:
        // Interruption ended
        if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                sendAction(.audioSessionResumed)
            }
        }

    @unknown default:
        break
    }
}
```

---

## Interruption Flow

```
Normal Playback                Phone Call Begins
     │                              │
     │                              ▼
     │                    ┌─────────────────────┐
     │                    │ .interruptionNotification │
     │                    │ type: .began        │
     │                    └─────────────────────┘
     │                              │
     │                              ▼
     │                    ┌─────────────────────┐
     │                    │ State Machine:      │
     │                    │ audioSessionInterrupted │
     │                    │ playing -> paused   │
     │                    └─────────────────────┘
     │                              │
     │                        Phone Call Ends
     │                              │
     │                              ▼
     │                    ┌─────────────────────┐
     │                    │ .interruptionNotification │
     │                    │ type: .ended        │
     │                    │ shouldResume: true  │
     │                    └─────────────────────┘
     │                              │
     │                              ▼
     │                    ┌─────────────────────┐
     │                    │ State Machine:      │
     │                    │ audioSessionResumed │
     │                    │ paused -> playing   │
     │                    └─────────────────────┘
     │                              │
     │◀─────────────────────────────┘
     │
Playback Resumes
```

---

## Usage Example

### Initial Setup

```swift
@MainActor
class VideoPlayerComposer {
    private let audioSessionAdapter: AudioSessionConfiguring

    init(audioSessionAdapter: AudioSessionConfiguring = AVAudioSessionAdapter()) {
        self.audioSessionAdapter = audioSessionAdapter
    }

    func setupPlayer() throws -> AVPlayer {
        // Configure audio session first
        try audioSessionAdapter.configureForPlayback()

        // Create player
        let player = AVPlayer()

        return player
    }
}
```

### In SceneDelegate

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }

    do {
        // Configure audio session at app launch
        let audioAdapter = AVAudioSessionAdapter()
        try audioAdapter.configureForPlayback()
    } catch {
        print("Failed to configure audio session: \(error)")
    }

    // Continue with UI setup...
}
```

---

## State Machine Integration

The playback state machine handles audio interruptions as external events:

```swift
// From paused state
case (.paused, .audioSessionResumed):
    return .playing

// From playing state
case (.playing, .audioSessionInterrupted):
    return .paused
```

This ensures:
- Automatic pause when interrupted
- Automatic resume when interruption ends (if permitted)
- Proper state tracking for analytics

---

## Testing

### Protocol-Based Testing

```swift
final class AudioSessionSpy: AudioSessionProtocol {
    var setCategoryCallCount = 0
    var lastCategory: AVAudioSession.Category?
    var lastOptions: AVAudioSession.CategoryOptions?
    var setActiveCallCount = 0
    var lastActiveState: Bool?
    var shouldThrowError: Error?

    func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws {
        if let error = shouldThrowError { throw error }
        setCategoryCallCount += 1
        lastCategory = category
        lastOptions = options
    }

    func setActive(_ active: Bool) throws {
        if let error = shouldThrowError { throw error }
        setActiveCallCount += 1
        lastActiveState = active
    }
}

// Unit Tests
final class AVAudioSessionAdapterTests: XCTestCase {
    func test_configureForPlayback_setsCategoryToPlayback() throws {
        let spy = AudioSessionSpy()
        let sut = AVAudioSessionAdapter(session: spy)

        try sut.configureForPlayback()

        XCTAssertEqual(spy.lastCategory, .playback)
    }

    func test_configureForPlayback_activatesSession() throws {
        let spy = AudioSessionSpy()
        let sut = AVAudioSessionAdapter(session: spy)

        try sut.configureForPlayback()

        XCTAssertEqual(spy.lastActiveState, true)
    }

    func test_configureForPlayback_propagatesError() {
        let spy = AudioSessionSpy()
        spy.shouldThrowError = NSError(domain: "test", code: 1)
        let sut = AVAudioSessionAdapter(session: spy)

        XCTAssertThrowsError(try sut.configureForPlayback())
    }
}
```

### State Machine Interruption Tests

```swift
@MainActor
func test_audioSessionInterrupted_fromPlaying_transitionsToPaused() {
    let sut = DefaultPlaybackStateMachine()
    sut.send(.load(anyURL()))
    sut.send(.didBecomeReady)
    sut.send(.play)

    sut.send(.audioSessionInterrupted)

    XCTAssertEqual(sut.currentState, .paused)
}

@MainActor
func test_audioSessionResumed_fromPaused_transitionsToPlaying() {
    let sut = DefaultPlaybackStateMachine()
    sut.send(.load(anyURL()))
    sut.send(.didBecomeReady)
    sut.send(.play)
    sut.send(.audioSessionInterrupted)

    sut.send(.audioSessionResumed)

    XCTAssertEqual(sut.currentState, .playing)
}
```

---

## Common Issues

### Audio Not Playing in Silent Mode

Ensure `.playback` category is set before playback starts:
```swift
try AVAudioSession.sharedInstance().setCategory(.playback)
try AVAudioSession.sharedInstance().setActive(true)
```

### Audio Stops When App Backgrounds

Enable background audio in `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### No Resume After Interruption

Check if `shouldResume` option is present:
```swift
if options.contains(.shouldResume) {
    player.play()
}
```

---

## Related Documentation

- [Player State Machine](PLAYER-STATE-MACHINE.md) - Interruption handling
- [AVPlayer Integration](AVPLAYER-INTEGRATION.md) - Player observation
- [Video Playback](VIDEO-PLAYBACK.md) - Playback features
