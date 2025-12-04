# Picture-in-Picture (PiP) Feature

Picture-in-Picture allows users to continue watching video in a floating window while using other apps.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    Other App Content                        │
│                                                             │
│                                                             │
│                              ┌─────────────────┐            │
│                              │  ▶  Video PiP   │            │
│                              │    Window       │            │
│                              └─────────────────┘            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Floating Video Window** - Continue playback in mini player
- **System Integration** - Uses iOS native PiP controller
- **Seamless Transition** - Smooth animation in/out of PiP
- **Playback Controls** - Play/pause, seek from PiP window
- **Return to App** - Tap to return to full player

---

## Architecture

### Protocol Abstraction

**File:** `StreamingCoreiOS/Video UI/Controllers/PictureInPictureControlling.swift`

```swift
@MainActor
public protocol PictureInPictureControlling: AnyObject {
    var isPictureInPictureActive: Bool { get }
    var isPictureInPicturePossible: Bool { get }

    func setup(with playerLayer: AVPlayerLayer)
    func togglePictureInPicture()
    func startPictureInPicture()
    func stopPictureInPicture()
}
```

### Implementation

**File:** `StreamingCoreiOS/Video UI/Controllers/PictureInPictureController.swift`

```swift
@MainActor
public final class PictureInPictureController: NSObject, PictureInPictureControlling {
    private var pipController: AVPictureInPictureController?
    public weak var delegate: PictureInPictureControllerDelegate?

    public var isPictureInPictureActive: Bool {
        pipController?.isPictureInPictureActive ?? false
    }

    public var isPictureInPicturePossible: Bool {
        pipController?.isPictureInPicturePossible ?? false
    }

    public static var isPictureInPictureSupported: Bool {
        AVPictureInPictureController.isPictureInPictureSupported()
    }

    public func setup(with playerLayer: AVPlayerLayer) {
        guard Self.isPictureInPictureSupported else { return }

        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.delegate = self
    }

    public func togglePictureInPicture() {
        if isPictureInPictureActive {
            stopPictureInPicture()
        } else {
            startPictureInPicture()
        }
    }

    public func startPictureInPicture() {
        pipController?.startPictureInPicture()
    }

    public func stopPictureInPicture() {
        pipController?.stopPictureInPicture()
    }
}
```

### Delegate

```swift
public protocol PictureInPictureControllerDelegate: AnyObject {
    func pictureInPictureControllerWillStart()
    func pictureInPictureControllerDidStart()
    func pictureInPictureControllerWillStop()
    func pictureInPictureControllerDidStop()
    func pictureInPictureControllerRestoreUserInterface(
        completionHandler: @escaping (Bool) -> Void
    )
}
```

---

## AVPictureInPictureControllerDelegate

```swift
extension PictureInPictureController: AVPictureInPictureControllerDelegate {

    public func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        delegate?.pictureInPictureControllerWillStart()
    }

    public func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        delegate?.pictureInPictureControllerDidStart()
    }

    public func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        delegate?.pictureInPictureControllerWillStop()
    }

    public func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        delegate?.pictureInPictureControllerDidStop()
    }

    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        delegate?.pictureInPictureControllerRestoreUserInterface(
            completionHandler: completionHandler
        )
    }
}
```

---

## Integration

### PlayerView Setup

**File:** `StreamingCoreiOS/Video UI/Views/PlayerView.swift`

```swift
public final class PlayerView: UIView {
    public override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    public var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    public var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    public func setupPictureInPicture(controller: PictureInPictureControlling) {
        controller.setup(with: playerLayer)
    }
}
```

### VideoPlayerViewController Integration

```swift
final class VideoPlayerViewController: UIViewController, PictureInPictureControllerDelegate {
    private let pipController: PictureInPictureControlling
    private let playerView: PlayerView

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPiP()
    }

    private func setupPiP() {
        pipController.delegate = self
        playerView.setupPictureInPicture(controller: pipController)
        updatePiPButtonVisibility()
    }

    private func updatePiPButtonVisibility() {
        controlsView.pipButton.isHidden = !PictureInPictureController.isPictureInPictureSupported
    }

    @objc func pipButtonTapped() {
        pipController.togglePictureInPicture()
    }

    // MARK: - PictureInPictureControllerDelegate

    func pictureInPictureControllerWillStart() {
        // Hide controls, prepare for PiP
    }

    func pictureInPictureControllerDidStop() {
        // Show controls, restore UI
    }

    func pictureInPictureControllerRestoreUserInterface(
        completionHandler: @escaping (Bool) -> Void
    ) {
        // Restore full player UI
        navigationController?.popToViewController(self, animated: true)
        completionHandler(true)
    }
}
```

---

## Requirements

### App Configuration

**Info.plist:**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Audio Session Setup

```swift
do {
    try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .moviePlayback
    )
    try AVAudioSession.sharedInstance().setActive(true)
} catch {
    print("Failed to configure audio session: \(error)")
}
```

---

## State Flow

```
┌─────────────────┐
│  Full Player    │
│    Active       │
└────────┬────────┘
         │ User taps PiP button
         ▼
┌─────────────────┐
│ willStart       │
│ (delegate)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ PiP Active      │
│ (floating)      │
└────────┬────────┘
         │ User taps PiP window
         ▼
┌─────────────────┐
│ restoreUI       │
│ (delegate)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Full Player    │
│    Restored     │
└─────────────────┘
```

---

## Device Support

| Device | PiP Support |
|--------|-------------|
| iPhone (iOS 14+) | Yes |
| iPad (iOS 9+) | Yes |
| iPhone (iOS < 14) | No |
| Simulator | Limited |

```swift
// Check support before showing button
if PictureInPictureController.isPictureInPictureSupported {
    pipButton.isHidden = false
}
```

---

## Testing

### Protocol-Based Testing

```swift
final class PictureInPictureControllerSpy: PictureInPictureControlling {
    var isPictureInPictureActive = false
    var isPictureInPicturePossible = true
    var setupCallCount = 0
    var toggleCallCount = 0

    func setup(with playerLayer: AVPlayerLayer) {
        setupCallCount += 1
    }

    func togglePictureInPicture() {
        toggleCallCount += 1
        isPictureInPictureActive.toggle()
    }
}

func test_pipButtonTapped_togglesPiP() {
    let pipSpy = PictureInPictureControllerSpy()
    let sut = makeVideoPlayerViewController(pipController: pipSpy)

    sut.pipButtonTapped()

    XCTAssertEqual(pipSpy.toggleCallCount, 1)
    XCTAssertTrue(pipSpy.isPictureInPictureActive)
}
```

---

## Common Issues

### PiP Not Starting

1. Check `UIBackgroundModes` includes "audio"
2. Verify audio session is configured
3. Ensure player has active content
4. Check device supports PiP

### PiP Button Not Visible

```swift
// Must check after player is ready
func playerDidBecomeReady() {
    controlsView.pipButton.isHidden = !pipController.isPictureInPicturePossible
}
```

---

## Related Documentation

- [Video Playback](VIDEO-PLAYBACK.md) - Player integration
- [Architecture](../ARCHITECTURE.md) - Protocol abstraction
- [Design Patterns](../DESIGN-PATTERNS.md) - Adapter pattern
