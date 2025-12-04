# Fox Sports AVPlayer Interview — 60-Minute Coding Guide

## Strategic Preparation for Live Coding Interview

---

## Interview Context Analysis

Based on the recruiter's email, the interviewer wants to see:

| Signal | What They're Looking For |
|--------|-------------------------|
| "questions around AVPlayer and implementing it" | Hands-on AVFoundation knowledge |
| "internals of how the player works" | Combine publishers, notifications, AVPlayerItem lifecycle |
| "different states" | State machine thinking, edge cases |
| "building a fully fledged AVPlayer" | Architecture over hacking |
| "not just making it work somehow" | Clean design, extensibility |
| Fox Sports context | Live streaming awareness, sports broadcasting needs |

---

## The 60-Minute Battle Plan

### Time Allocation

```
┌─────────────────────────────────────────────────────────────────┐
│  0-5 min   │ Clarify requirements, discuss approach            │
│  5-20 min  │ Phase 1: Protocol + Basic Implementation          │
│ 20-35 min  │ Phase 2: State Management + Combine Observation   │
│ 35-50 min  │ Phase 3: Error Handling + Buffering States        │
│ 50-60 min  │ Phase 4: Polish + Discussion of Extensions        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 0: Opening Discussion (0-5 minutes)

### Questions to Ask the Interviewer

```
"Before I start coding, let me clarify the scope:
1. Should I focus on VOD playback or also consider live streaming?
2. Do you want me to include UI, or focus on the player layer?
3. Should I handle background audio and interruptions?
4. Any specific states you want me to prioritize?"
```

### What to Say While Setting Up

> "I'm going to approach this by first defining a clean protocol abstraction for the player. This decouples our business logic from AVFoundation, making it testable and allowing us to swap implementations—for example, if Fox ever needed ExoPlayer on Android or a mock player for unit tests.
>
> Then I'll implement the core AVPlayer wrapper with proper state tracking using Combine publishers. This is the modern approach—it's more declarative than KVO and integrates naturally with SwiftUI or any reactive UI layer.
>
> In production, I'd use a formal state machine, but I'll show you a pragmatic version we can build in this time."

---

## Phase 1: Protocol + Basic Implementation (5-20 minutes)

### Step 1.1: Define the Protocol (Type First)

```swift
import Foundation
import Combine

/// Abstraction for video playback - decouples business logic from AVFoundation
protocol VideoPlayer: AnyObject {
    // MARK: - State Publishers (Reactive)
    var statePublisher: AnyPublisher<PlayerState, Never> { get }
    var timePublisher: AnyPublisher<TimeInterval, Never> { get }
    var errorPublisher: AnyPublisher<PlayerError, Never> { get }

    // MARK: - Current State
    var currentState: PlayerState { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }

    // MARK: - Playback Control
    func load(url: URL)
    func play()
    func pause()
    func seek(to time: TimeInterval) -> AnyPublisher<Bool, Never>
}
```

**SAY THIS**: *"I'm using Combine publishers for state observation instead of KVO. This is more modern and declarative—the UI can simply subscribe to `statePublisher` and react to changes. It also makes the API more testable since we can easily mock publishers in unit tests."*

### Step 1.2: Define Player States

```swift
/// Represents the lifecycle states of a video player
enum PlayerState: Equatable, CustomStringConvertible {
    case idle                    // Initial state, no content loaded
    case loading                 // Asset is being loaded
    case ready                   // Ready to play (buffered enough)
    case playing                 // Actively playing
    case paused                  // User paused
    case buffering               // Playback stalled, waiting for data
    case ended                   // Reached end of content
    case failed(PlayerError)     // Unrecoverable error

    var description: String {
        switch self {
        case .idle: return "idle"
        case .loading: return "loading"
        case .ready: return "ready"
        case .playing: return "playing"
        case .paused: return "paused"
        case .buffering: return "buffering"
        case .ended: return "ended"
        case .failed: return "failed"
        }
    }

    /// Whether playback can be started from this state
    var canPlay: Bool {
        switch self {
        case .ready, .paused, .ended: return true
        default: return false
        }
    }

    /// Whether playback can be paused from this state
    var canPause: Bool {
        switch self {
        case .playing, .buffering: return true
        default: return false
        }
    }
}

enum PlayerError: Error, Equatable {
    case loadFailed(String)
    case playbackFailed(String)
    case networkError(String)

    /// Whether this error can potentially be recovered by retrying
    var isRecoverable: Bool {
        switch self {
        case .networkError: return true
        default: return false
        }
    }
}
```

**SAY THIS**: *"These states map directly to what AVPlayer reports, but I'm modeling them explicitly. This is critical for Fox's live sports coverage—you need to know exactly when you're buffering versus when the stream actually failed. The difference determines whether you show a spinner or an error message.*

*I've also added computed properties like `canPlay` and `canPause` to encapsulate the state transition rules. This prevents invalid operations like trying to play while still loading."*

### Step 1.3: Basic AVPlayer Implementation with Combine

```swift
import AVFoundation
import Combine

final class AVPlayerVideoPlayer: VideoPlayer {

    // MARK: - Private Properties

    private let player: AVPlayer
    private var playerItem: AVPlayerItem?
    private var cancellables = Set<AnyCancellable>()
    private var timeObserver: Any?

    // MARK: - Combine Subjects (Internal State)

    private let stateSubject = CurrentValueSubject<PlayerState, Never>(.idle)
    private let timeSubject = PassthroughSubject<TimeInterval, Never>()
    private let errorSubject = PassthroughSubject<PlayerError, Never>()

    // MARK: - VideoPlayer Protocol - Publishers

    var statePublisher: AnyPublisher<PlayerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var timePublisher: AnyPublisher<TimeInterval, Never> {
        timeSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<PlayerError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // MARK: - VideoPlayer Protocol - Current State

    var currentState: PlayerState {
        stateSubject.value
    }

    var currentTime: TimeInterval {
        player.currentTime().seconds
    }

    var duration: TimeInterval {
        player.currentItem?.duration.seconds ?? 0
    }

    // MARK: - Initialization

    init(player: AVPlayer = AVPlayer()) {
        self.player = player
        setupPlayerObservers()
        setupPeriodicTimeObserver()
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        cancellables.removeAll()
    }

    // MARK: - Playback Control

    func load(url: URL) {
        // Clean up previous item observers
        cancellables.removeAll()
        setupPlayerObservers() // Re-setup player-level observers

        stateSubject.send(.loading)

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        playerItem = item

        setupItemObservers(for: item)
        player.replaceCurrentItem(with: item)
    }

    func play() {
        guard currentState.canPlay else { return }
        player.play()
    }

    func pause() {
        guard currentState.canPause else { return }
        player.pause()
    }

    func seek(to time: TimeInterval) -> AnyPublisher<Bool, Never> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.success(false))
                return
            }

            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            self.player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
                promise(.success(finished))
            }
        }
        .eraseToAnyPublisher()
    }
}
```

**SAY THIS**: *"I'm using `CurrentValueSubject` for state because it retains the last value—new subscribers immediately get the current state. For time updates and errors, I use `PassthroughSubject` since there's no meaningful 'current' value to cache.*

*The seek method returns a publisher instead of using a completion handler. This lets callers chain operations declaratively, like `player.seek(to: 30).sink { success in ... }`.*

*I'm using preferredTimescale of 600 for frame-accurate seeking—this is important for sports replays where you need precise scrubbing. The toleranceBefore/After of .zero ensures exact positioning, though it's slower than the default approximate seek."*

---

## Phase 2: State Management + Combine Observation (20-35 minutes)

### Step 2.1: Player-Level Observation with Combine

```swift
// MARK: - Player Observation (Combine)

private func setupPlayerObservers() {
    // Observe timeControlStatus using Combine publisher
    player.publisher(for: \.timeControlStatus)
        .removeDuplicates()
        .sink { [weak self] status in
            self?.handleTimeControlStatusChange(status)
        }
        .store(in: &cancellables)
}

private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
    switch status {
    case .playing:
        stateSubject.send(.playing)

    case .paused:
        // Only transition to paused if we were playing or buffering
        // Avoids overwriting .ready or .ended states
        let current = stateSubject.value
        if current == .playing || current == .buffering {
            stateSubject.send(.paused)
        }

    case .waitingToPlayAtSpecifiedRate:
        // This is the buffering state - only if we were playing
        if stateSubject.value == .playing {
            stateSubject.send(.buffering)
        }

    @unknown default:
        break
    }
}
```

**SAY THIS**: *"I'm using the `publisher(for:)` API which was added in iOS 13. It's the Combine equivalent of KVO—much cleaner than the old `observe()` method with key paths. The `removeDuplicates()` operator prevents redundant state updates when the value hasn't actually changed."*

### Step 2.2: PlayerItem Observation with Combine

```swift
// MARK: - PlayerItem Observation (Combine)

private func setupItemObservers(for item: AVPlayerItem) {
    // Observe item status (unknown -> readyToPlay -> failed)
    item.publisher(for: \.status)
        .removeDuplicates()
        .sink { [weak self] status in
            self?.handleItemStatusChange(status, error: item.error)
        }
        .store(in: &cancellables)

    // Observe buffer state - when buffer recovers
    item.publisher(for: \.isPlaybackLikelyToKeepUp)
        .filter { $0 == true } // Only when buffer is healthy
        .sink { [weak self] _ in
            guard let self = self else { return }
            if self.stateSubject.value == .buffering {
                self.stateSubject.send(.playing)
                self.player.play() // Resume playback
            }
        }
        .store(in: &cancellables)

    // Observe when playback reaches end
    NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
        .sink { [weak self] _ in
            self?.stateSubject.send(.ended)
        }
        .store(in: &cancellables)

    // Observe playback failures mid-stream
    NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item)
        .sink { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            let message = error?.localizedDescription ?? "Playback failed"
            let playerError = PlayerError.playbackFailed(message)
            self?.stateSubject.send(.failed(playerError))
            self?.errorSubject.send(playerError)
        }
        .store(in: &cancellables)
}

private func handleItemStatusChange(_ status: AVPlayerItem.Status, error: Error?) {
    switch status {
    case .readyToPlay:
        stateSubject.send(.ready)

    case .failed:
        let message = error?.localizedDescription ?? "Unknown error"
        let playerError = PlayerError.loadFailed(message)
        stateSubject.send(.failed(playerError))
        errorSubject.send(playerError)

    case .unknown:
        // Still loading, no state change needed
        break

    @unknown default:
        break
    }
}
```

**SAY THIS**: *"Notice how I'm using `NotificationCenter.default.publisher(for:)` to convert notifications into Combine publishers. This keeps everything in the reactive paradigm—no mixing of notification selectors with Combine subscriptions.*

*There are two different failure modes: `AVPlayerItem.status == .failed` means the asset couldn't load at all—maybe a 404 or invalid format. `AVPlayerItemFailedToPlayToEndTime` means playback started but failed mid-stream—common with live streams when the CDN has issues. For Fox's NFL coverage, distinguishing these is critical for showing the right error message."*

### Step 2.3: Periodic Time Observer

```swift
// MARK: - Time Observation

private func setupPeriodicTimeObserver() {
    // Update every 0.5 seconds for UI updates
    let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

    timeObserver = player.addPeriodicTimeObserver(
        forInterval: interval,
        queue: .main
    ) { [weak self] time in
        self?.timeSubject.send(time.seconds)
    }
}
```

**SAY THIS**: *"Periodic time observers are how you update the scrubber UI. I'm using 0.5 second intervals—fast enough for smooth UI but not so fast it wastes CPU. The updates go through `timeSubject` so the UI can subscribe with `player.timePublisher.sink { ... }`.*

*Unfortunately, there's no Combine equivalent for periodic time observation, so we bridge it manually into our subject."*

---

## Phase 3: Error Handling + Production Concerns (35-50 minutes)

### Step 3.1: Audio Session Handling with Combine

```swift
// MARK: - Audio Session Observation

private func setupAudioSessionObserver() {
    NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
        .compactMap { notification -> AVAudioSession.InterruptionType? in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else {
                return nil
            }
            return AVAudioSession.InterruptionType(rawValue: typeValue)
        }
        .sink { [weak self] interruptionType in
            self?.handleAudioSessionInterruption(interruptionType)
        }
        .store(in: &cancellables)
}

private func handleAudioSessionInterruption(_ type: AVAudioSession.InterruptionType) {
    switch type {
    case .began:
        // Phone call, Siri, etc. - system paused us
        pause()

    case .ended:
        // Interruption ended - could add auto-resume logic here
        // In production, check AVAudioSession.InterruptionOptions.shouldResume
        break

    @unknown default:
        break
    }
}
```

**SAY THIS**: *"Audio interruptions are critical for a sports app. Imagine someone's watching the Super Bowl and gets a phone call—when they hang up, you might want playback to resume automatically. I'm using `compactMap` to safely extract the interruption type from the notification's userInfo dictionary."*

### Step 3.2: Enhanced Audio Session with Resume Logic

```swift
// MARK: - Enhanced Audio Session (Production Version)

private func setupAudioSessionObserverEnhanced() {
    NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
        .sink { [weak self] notification in
            self?.handleAudioInterruptionNotification(notification)
        }
        .store(in: &cancellables)
}

private func handleAudioInterruptionNotification(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
        return
    }

    switch type {
    case .began:
        pause()

    case .ended:
        // Check if we should auto-resume
        if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) && currentState == .paused {
                play()
            }
        }

    @unknown default:
        break
    }
}
```

**SAY THIS**: *"This enhanced version checks the `.shouldResume` option that iOS provides. The system tells us whether it's appropriate to resume—for example, after a brief Siri interruption it might say yes, but after a long phone call it might say no."*

### Step 3.3: Buffer Health Monitoring

```swift
// MARK: - Buffer Health Publisher

var bufferHealthPublisher: AnyPublisher<Double, Never> {
    guard let item = playerItem else {
        return Just(0.0).eraseToAnyPublisher()
    }

    return item.publisher(for: \.loadedTimeRanges)
        .map { [weak self] ranges -> Double in
            guard let self = self,
                  let timeRange = ranges.first?.timeRangeValue else {
                return 0.0
            }

            let bufferedEnd = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)
            let currentTime = self.currentTime
            let bufferedAhead = bufferedEnd - currentTime

            // Return seconds of buffer ahead of playhead
            return max(0, bufferedAhead)
        }
        .eraseToAnyPublisher()
}
```

**SAY THIS**: *"This publisher exposes how many seconds of content are buffered ahead of the current playhead. For a live sports broadcast, you'd typically want 2-5 seconds of buffer. If it drops below 1 second, you might preemptively reduce quality to avoid a stall."*

### Step 3.4: Attach to View Layer

```swift
// MARK: - View Attachment

func attach(to view: UIView) {
    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.frame = view.bounds
    playerLayer.videoGravity = .resizeAspect
    view.layer.addSublayer(playerLayer)
}

// For SwiftUI, you'd expose the player for use in AVPlayerViewController
var avPlayer: AVPlayer {
    player
}
```

---

## Phase 4: Discussion + Extensions (50-60 minutes)

### What to Say When Wrapping Up

> "So we've built a functional video player with proper state management using Combine. The reactive approach gives us clean data flow—the UI simply subscribes to publishers and reacts to changes. If I had more time, here's what I'd add next, in priority order for a sports streaming app like Fox's:"

### Extensions to Discuss (Don't Code, Just Explain)

**1. Formal State Machine with Actor Isolation**
> "In production, I'd wrap the state logic in a Swift actor. This prevents race conditions when Combine callbacks arrive from different queues. The state machine would have explicit transition rules—for example, you can only go from `.loading` to `.ready` or `.failed`, never directly to `.playing`."

**2. Adaptive Bitrate Monitoring**
> "For live sports, I'd add a publisher for `AVPlayerItem.accessLog()` to track bitrate switches. You can observe when the player downgrades quality due to network conditions and surface that to analytics."

```swift
// Example: Bitrate monitoring publisher
var bitratePublisher: AnyPublisher<Double, Never> {
    Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .compactMap { [weak self] _ -> Double? in
            guard let event = self?.playerItem?.accessLog()?.events.last else {
                return nil
            }
            return event.indicatedBitrate
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
}
```

**3. Performance Metrics**
> "I'd track time-to-first-frame and rebuffering ratio. Industry standard is TTFF under 2 seconds and rebuffering under 1% of watch time. For live NFL games, you might accept slightly more buffering for higher quality."

**4. Live Stream Specifics**
```swift
// For live content, you'd configure:
player.automaticallyWaitsToMinimizeStalling = false // Prioritize liveness
playerItem.preferredForwardBufferDuration = 2.0 // Shorter buffer for lower latency

// And add a live edge publisher:
var liveEdgeOffsetPublisher: AnyPublisher<TimeInterval, Never> {
    timePublisher
        .map { [weak self] currentTime -> TimeInterval in
            guard let duration = self?.duration, duration.isFinite else {
                return 0
            }
            return duration - currentTime // How far behind live
        }
        .eraseToAnyPublisher()
}
```

**5. Picture-in-Picture**
> "For iOS, I'd wrap `AVPictureInPictureController`. It requires the player layer and background audio entitlement. I'd expose a `pipStatePublisher` so the UI knows when PiP is active."

---

## Complete Implementation Reference

Here's the full implementation assembled together:

```swift
import AVFoundation
import Combine

// MARK: - Protocol

protocol VideoPlayer: AnyObject {
    var statePublisher: AnyPublisher<PlayerState, Never> { get }
    var timePublisher: AnyPublisher<TimeInterval, Never> { get }
    var errorPublisher: AnyPublisher<PlayerError, Never> { get }

    var currentState: PlayerState { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }

    func load(url: URL)
    func play()
    func pause()
    func seek(to time: TimeInterval) -> AnyPublisher<Bool, Never>
}

// MARK: - State

enum PlayerState: Equatable, CustomStringConvertible {
    case idle
    case loading
    case ready
    case playing
    case paused
    case buffering
    case ended
    case failed(PlayerError)

    var description: String {
        switch self {
        case .idle: return "idle"
        case .loading: return "loading"
        case .ready: return "ready"
        case .playing: return "playing"
        case .paused: return "paused"
        case .buffering: return "buffering"
        case .ended: return "ended"
        case .failed: return "failed"
        }
    }

    var canPlay: Bool {
        switch self {
        case .ready, .paused, .ended: return true
        default: return false
        }
    }

    var canPause: Bool {
        switch self {
        case .playing, .buffering: return true
        default: return false
        }
    }
}

enum PlayerError: Error, Equatable {
    case loadFailed(String)
    case playbackFailed(String)
    case networkError(String)

    var isRecoverable: Bool {
        switch self {
        case .networkError: return true
        default: return false
        }
    }
}

// MARK: - Implementation

final class AVPlayerVideoPlayer: VideoPlayer {

    private let player: AVPlayer
    private var playerItem: AVPlayerItem?
    private var cancellables = Set<AnyCancellable>()
    private var timeObserver: Any?

    private let stateSubject = CurrentValueSubject<PlayerState, Never>(.idle)
    private let timeSubject = PassthroughSubject<TimeInterval, Never>()
    private let errorSubject = PassthroughSubject<PlayerError, Never>()

    var statePublisher: AnyPublisher<PlayerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var timePublisher: AnyPublisher<TimeInterval, Never> {
        timeSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<PlayerError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var currentState: PlayerState { stateSubject.value }
    var currentTime: TimeInterval { player.currentTime().seconds }
    var duration: TimeInterval { player.currentItem?.duration.seconds ?? 0 }

    init(player: AVPlayer = AVPlayer()) {
        self.player = player
        setupPlayerObservers()
        setupPeriodicTimeObserver()
        setupAudioSessionObserver()
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
    }

    func load(url: URL) {
        cancellables.removeAll()
        setupPlayerObservers()
        setupAudioSessionObserver()

        stateSubject.send(.loading)

        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        playerItem = item
        setupItemObservers(for: item)
        player.replaceCurrentItem(with: item)
    }

    func play() {
        guard currentState.canPlay else { return }
        player.play()
    }

    func pause() {
        guard currentState.canPause else { return }
        player.pause()
    }

    func seek(to time: TimeInterval) -> AnyPublisher<Bool, Never> {
        Future { [weak self] promise in
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            self?.player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
                promise(.success(finished))
            }
        }
        .eraseToAnyPublisher()
    }

    func attach(to view: UIView) {
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
    }

    // MARK: - Private: Player Observation

    private func setupPlayerObservers() {
        player.publisher(for: \.timeControlStatus)
            .removeDuplicates()
            .sink { [weak self] status in
                self?.handleTimeControlStatusChange(status)
            }
            .store(in: &cancellables)
    }

    private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            stateSubject.send(.playing)
        case .paused:
            let current = stateSubject.value
            if current == .playing || current == .buffering {
                stateSubject.send(.paused)
            }
        case .waitingToPlayAtSpecifiedRate:
            if stateSubject.value == .playing {
                stateSubject.send(.buffering)
            }
        @unknown default:
            break
        }
    }

    // MARK: - Private: Item Observation

    private func setupItemObservers(for item: AVPlayerItem) {
        item.publisher(for: \.status)
            .removeDuplicates()
            .sink { [weak self] status in
                self?.handleItemStatusChange(status, error: item.error)
            }
            .store(in: &cancellables)

        item.publisher(for: \.isPlaybackLikelyToKeepUp)
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self = self, self.stateSubject.value == .buffering else { return }
                self.stateSubject.send(.playing)
                self.player.play()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { [weak self] _ in
                self?.stateSubject.send(.ended)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item)
            .sink { [weak self] notification in
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                let playerError = PlayerError.playbackFailed(error?.localizedDescription ?? "Playback failed")
                self?.stateSubject.send(.failed(playerError))
                self?.errorSubject.send(playerError)
            }
            .store(in: &cancellables)
    }

    private func handleItemStatusChange(_ status: AVPlayerItem.Status, error: Error?) {
        switch status {
        case .readyToPlay:
            stateSubject.send(.ready)
        case .failed:
            let playerError = PlayerError.loadFailed(error?.localizedDescription ?? "Unknown error")
            stateSubject.send(.failed(playerError))
            errorSubject.send(playerError)
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Private: Time Observation

    private func setupPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.timeSubject.send(time.seconds)
        }
    }

    // MARK: - Private: Audio Session

    private func setupAudioSessionObserver() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                guard let userInfo = notification.userInfo,
                      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

                switch type {
                case .began:
                    self?.pause()
                case .ended:
                    if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                        if options.contains(.shouldResume) {
                            self?.play()
                        }
                    }
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
```

---

## Key Interview Questions & Answers

### Q: "What are the different states AVPlayer can be in?"

**Answer**:
> "AVPlayer itself has `timeControlStatus` which can be `.paused`, `.playing`, or `.waitingToPlayAtSpecifiedRate` (buffering). But `AVPlayerItem` has its own `status`: `.unknown`, `.readyToPlay`, or `.failed`.
>
> In my implementation, I combine these into a unified state model: idle, loading, ready, playing, paused, buffering, ended, and failed. I expose this through a Combine publisher so the UI has a single source of truth to subscribe to."

### Q: "Why use Combine instead of KVO?"

**Answer**:
> "Combine offers several advantages:
> 1. **Declarative** — Subscriptions are clearer than KVO observation blocks
> 2. **Composable** — I can use operators like `removeDuplicates()`, `filter()`, `map()`
> 3. **Memory management** — `store(in: &cancellables)` handles cleanup automatically
> 4. **SwiftUI ready** — Publishers integrate directly with SwiftUI's `onReceive`
> 5. **Testable** — I can mock publishers in unit tests
>
> The `publisher(for:)` API on NSObject gives us KVO observation as a Combine publisher, so we get the best of both worlds."

### Q: "How do you handle buffering?"

**Answer**:
> "I observe `timeControlStatus == .waitingToPlayAtSpecifiedRate` to detect when we're buffering. To know when buffering ends, I watch `isPlaybackLikelyToKeepUp` becoming true via a Combine publisher with a `filter { $0 }` to only react when the buffer is healthy.
>
> For deeper buffer health, I'd add a publisher for `loadedTimeRanges` that calculates how many seconds are buffered ahead of the playhead."

### Q: "What's the difference between AVPlayer and AVPlayerItem?"

**Answer**:
> "AVPlayer is the playback controller—it handles play/pause/seek and manages the render pipeline. AVPlayerItem represents the content being played—it owns the asset, tracks, and timing information.
>
> One AVPlayer can switch between multiple AVPlayerItems, which is useful for playlists. The separation also allows you to pre-create AVPlayerItems for upcoming videos while the current one plays—important for seamless transitions in a sports highlight reel."

### Q: "How would you handle live streaming differently?"

**Answer**:
> "For live, I'd:
> 1. Set `automaticallyWaitsToMinimizeStalling = false` to prioritize liveness over buffering
> 2. Set `preferredForwardBufferDuration` to a smaller value (2-3 seconds) for lower latency
> 3. Add a publisher that tracks how far behind the live edge we are
> 4. Use `seekToDate()` instead of `seek(to:)` for program-time positioning
> 5. Handle stream discontinuities that are common in live broadcasts"

### Q: "How do you handle errors?"

**Answer**:
> "There are three error surfaces, all converted to Combine publishers:
> 1. `AVPlayerItem.status == .failed` — asset couldn't load (I observe this via `publisher(for: \.status)`)
> 2. `AVPlayerItemFailedToPlayToEndTime` notification — mid-stream failure
> 3. `AVPlayerItem.errorLog()` — for recoverable errors during playback
>
> I categorize errors by recoverability. Network errors can be retried; DRM or format errors typically can't. The state enum has an `isRecoverable` property that drives retry logic."

### Q: "How would you test this?"

**Answer**:
> "The protocol abstraction makes testing straightforward:
> 1. **Unit tests** — Create a `MockVideoPlayer` conforming to the protocol with controllable publishers
> 2. **Integration tests** — Use a real `AVPlayerVideoPlayer` with local test assets
> 3. **UI tests** — Inject the mock player to simulate loading, buffering, errors
>
> I can also test the state transitions by subscribing to `statePublisher` and asserting the sequence of states after calling `load()`, `play()`, etc."

---

## Quick Reference: AVPlayer + Combine

| What to Observe | Combine Approach |
|-----------------|------------------|
| Player status | `player.publisher(for: \.timeControlStatus)` |
| Item status | `item.publisher(for: \.status)` |
| Buffer health | `item.publisher(for: \.isPlaybackLikelyToKeepUp)` |
| Loaded ranges | `item.publisher(for: \.loadedTimeRanges)` |
| End of playback | `NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)` |
| Playback failure | `NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime)` |
| Audio interruption | `NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)` |
| Periodic time | Manual bridge via `addPeriodicTimeObserver` → Subject |

---

## Final Code Structure

```
VideoPlayer.swift (Protocol)
├── statePublisher: AnyPublisher<PlayerState, Never>
├── timePublisher: AnyPublisher<TimeInterval, Never>
├── errorPublisher: AnyPublisher<PlayerError, Never>
└── Playback control methods

PlayerState.swift (Enum)
├── idle, loading, ready, playing
├── paused, buffering, ended
├── failed(PlayerError)
└── canPlay, canPause computed properties

AVPlayerVideoPlayer.swift (Implementation)
├── Combine subjects for state broadcasting
├── publisher(for:) on timeControlStatus
├── publisher(for:) on AVPlayerItem.status
├── publisher(for:) on isPlaybackLikelyToKeepUp
├── NotificationCenter publishers for end/fail
├── Audio session interruption handling
└── Periodic time observer → subject bridge
```

---

## Closing Statement for the Interview

> "What I've built here is a solid foundation—protocol-driven, reactive with Combine, with explicit state management. The publisher-based API means any UI layer can subscribe to exactly the data it needs.
>
> In a production environment like Fox Sports, I'd extend this with:
>
> 1. An actor-based state machine for thread safety
> 2. Analytics decorators tracking TTFF and rebuffering
> 3. Live stream specific handling with DVR controls
> 4. A bitrate publisher for adaptive quality monitoring
>
> The architecture I've shown scales to those requirements because we started with clean abstractions and reactive data flow rather than just 'making it work.'"

---

## About Your Background Project

If the interviewer asks about your experience, you can reference your StreamingVideoApp:

> "I've actually built a production-grade video streaming architecture in a personal project. It includes:
> - A formal playback state machine using Swift actors
> - Analytics decorators tracking every playback event
> - Bandwidth estimation with statistical confidence scoring
> - Adaptive bitrate strategy patterns
> - Full TDD coverage with proper test doubles
>
> The patterns I've shown today are simplified versions of what I've implemented there. I'd be happy to walk through the full architecture if you're interested."

---

**Good luck with the interview! You've got both the live-coding skills and the production-grade codebase to back up everything you'll discuss.**
