# ``StreamingCorePlayback``

AVFoundation playback stack shared by the iOS and tvOS apps — the concrete
`VideoPlayer` implementation and everything that decorates, observes, and adapts it.

## Overview

StreamingCorePlayback sits between ``StreamingCore`` (pure domain, no AVKit) and
the app targets. It holds the AVFoundation-dependent playback plumbing that used
to live in the iOS app and in StreamingCoreiOS, relocated into one
platform-agnostic framework (iOS · tvOS · macOS) so both apps reuse it without
duplicating a line.

```
Tattva (iOS) ─┐
                         ├─► StreamingCorePlayback ──► StreamingCore
TattvaTV (tvOS)┘
```

The framework imports AVFoundation but **no UIKit** — it stays UI-agnostic, so
the iOS app supplies its custom controls and the tvOS app uses
`AVPlayerViewController`, both over the same player.

### The player chain

`VideoService` and the composers assemble the concrete player as a stack of
decorators over ``AVPlayerVideoPlayer``:

```
AVPlayerVideoPlayer          concrete AVPlayer-backed VideoPlayer
  → LoggingVideoPlayerDecorator      structured logging of playback events
  → AnalyticsVideoPlayerDecorator    engagement/event analytics
  → StatefulVideoPlayer              drives the validated playback state machine
```

with ``PlaybackCoordinator`` and ``VideoPlayerPerformanceAdapter`` observing
buffer, bandwidth, and performance alongside.

### Key types

| Type | Responsibility |
|------|----------------|
| ``AVPlayerVideoPlayer`` | Concrete `VideoPlayer` backed by `AVPlayer` |
| ``StatefulVideoPlayer`` | Wraps a player with the domain playback state machine |
| ``LoggingVideoPlayerDecorator`` / ``AnalyticsVideoPlayerDecorator`` | Cross-cutting logging + analytics via the Decorator pattern |
| ``PlaybackCoordinator`` | Owns the observation lifetime; `stop()` releases resources |
| ``AVPlayerStateAdapter`` | Bridges `AVPlayer` state (incl. audio-session interruptions) to the domain |
| ``AVPlayerBufferAdapter`` | Adaptive buffering over a `BufferConfigurablePlayer` |
| ``AVPlayerPerformanceObserver`` / ``VideoPlayerPerformanceAdapter`` | Performance/bandwidth observation feeding quality decisions |
| ``NetworkBandwidthEstimator`` (+ ``BandwidthEstimate`` / ``BandwidthSample``) | Throughput estimation |
| ``VideoService`` | Builds video/comment loaders + the player for a given video |

## Topics

### Playback

- ``AVPlayerVideoPlayer``
- ``StatefulVideoPlayer``
- ``PlaybackCoordinator``

### Adapters

- ``AVPlayerStateAdapter``
- ``AVPlayerBufferAdapter``
- ``VideoPlayerPerformanceAdapter``

### Bandwidth

- ``NetworkBandwidthEstimator``
- ``BandwidthEstimate``
- ``BandwidthSample``
