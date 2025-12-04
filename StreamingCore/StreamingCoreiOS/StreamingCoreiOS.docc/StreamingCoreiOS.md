# ``StreamingCoreiOS``

iOS-specific UI components and platform adapters for video streaming applications.

## Overview

StreamingCoreiOS provides UIKit-based view controllers, views, and iOS platform adapters that implement the protocols defined in StreamingCore. It serves as the bridge between the platform-agnostic business logic and iOS-specific frameworks like AVFoundation and UIKit.

### Design Principles

- **Adapter Pattern**: Platform adapters implement StreamingCore protocols using iOS frameworks
- **Composition over Inheritance**: Views are composed of smaller, reusable components
- **Main Thread Safety**: All UI components are marked with `@MainActor` for thread safety
- **Accessibility**: UI components support VoiceOver and Dynamic Type

### Key Features

| Feature | Description |
|---------|-------------|
| Video Player UI | Full-featured player with controls, gestures, and fullscreen support |
| AVPlayer Integration | Seamless wrapper around AVFoundation for playback |
| Picture-in-Picture | Native PiP support for background playback |
| Network Monitoring | Real-time network quality detection using NWPathMonitor |
| Lazy Image Loading | Efficient thumbnail loading with caching |
| Comments UI | Scrollable comment list with relative timestamps |

### Architecture

```
┌─────────────────────────────────────────┐
│         StreamingCoreiOS                │
│    (UIKit Views & Platform Adapters)    │
├─────────────────────────────────────────┤
│                  │                      │
│   UI Components  │   Platform Adapters  │
│   ─────────────  │   ─────────────────  │
│   • ViewControllers  • AVPlayerStateAdapter
│   • Custom Views     • NetworkQualityMonitor
│   • Controls         • OSLogLogger         │
│                                         │
└─────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────┐
│            StreamingCore                │
│   (Platform-Agnostic Protocols)         │
└─────────────────────────────────────────┘
```

### Thread Safety

All view controllers and UI components are annotated with `@MainActor` to ensure they are accessed only from the main thread. Platform adapters that interact with AVFoundation handle thread synchronization internally.

## Topics

### Essentials

- <doc:GettingStartediOS>

### Video Player UI

Complete video player implementation with controls.

- ``VideoPlayerViewController``
- ``VideoPlayerView``
- ``VideoControlsView``
- ``VideoProgressView``

### Video List UI

Components for displaying video collections.

- ``VideosViewController``
- ``VideoCell``
- ``VideoCellController``
- ``VideoImageView``

### AVPlayer Integration

Adapters bridging AVFoundation to StreamingCore protocols.

- ``AVPlayerStateAdapter``
- ``AVPlayerBufferAdapter``

### Picture-in-Picture

Background playback support.

- ``PictureInPictureController``
- ``PictureInPictureDelegate``

### Network Monitoring

Real-time network quality tracking.

- ``NetworkQualityMonitor``
- ``NetworkBandwidthEstimator``

### Comments UI

Video comments display components.

- ``VideoCommentCell``
- ``VideoCommentCellController``

### Shared UI Components

Reusable UI building blocks.

- ``ListViewController``
- ``CellController``
- ``ErrorView``
- ``LoadingView``

### Logging

iOS-specific logging implementation.

- ``OSLogLogger``
