# ``StreamingCoreiOS``

iOS-specific implementations for video streaming.

## Overview

StreamingCoreiOS provides UIKit components and AVFoundation integrations for the StreamingCore framework. It contains platform-specific implementations that work with iOS, iPadOS, and macOS Catalyst.

### Key Features

- **AVPlayer Integration** - Full-featured video player implementation
- **UI Components** - Ready-to-use view controllers and controls
- **Picture-in-Picture** - Native PiP support
- **Network Monitoring** - Real-time network quality tracking

### Architecture

StreamingCoreiOS acts as the iOS adapter layer:

- **UI Components** - UIKit-based view controllers and views
- **Platform Adapters** - AVFoundation implementations of core protocols
- **System Integration** - iOS-specific features (PiP, background modes)

## Topics

### AVPlayer Integration

- ``AVPlayerVideoPlayer``
- ``AVPlayerStateAdapter``
- ``AVPlayerBufferAdapter``

### UI Components

- ``VideoPlayerViewController``
- ``VideoPlayerControlsView``
- ``VideosViewController``
- ``VideoCell``

### Picture-in-Picture

- ``PictureInPictureController``

### Network Monitoring

- ``NetworkQualityMonitor``
- ``NetworkBandwidthEstimator``

### Comments UI

- ``VideoCommentsViewController``
- ``VideoCommentCell``
