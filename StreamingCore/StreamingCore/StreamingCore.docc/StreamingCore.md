# ``StreamingCore``

Platform-agnostic video streaming framework providing core business logic.

## Overview

StreamingCore provides the foundation for video streaming applications with a clean, testable architecture. It contains domain models, protocols, and business logic that can be shared across platforms (iOS, macOS, tvOS).

### Key Features

- **Video Loading** - Protocol-based video fetching with caching support
- **Playback Management** - State machine-driven playback control
- **Performance Monitoring** - Real-time metrics and adaptive quality
- **Memory Management** - Automatic resource cleanup under pressure
- **Structured Logging** - Comprehensive logging infrastructure

### Architecture

StreamingCore follows Clean Architecture principles:

- **Domain Layer** - Models, protocols, and business rules
- **Use Cases** - Application-specific business logic
- **Presentation** - ViewModels and Presenters (platform-agnostic)

## Topics

### Video Loading

- ``VideoLoader``
- ``VideoCache``
- ``Video``

### Playback Management

- ``VideoPlayer``
- ``PlaybackState``
- ``PlaybackAction``
- ``PlaybackError``

### Performance Optimization

- ``PerformanceMonitor``
- ``BitrateStrategy``
- ``VideoPreloader``
- ``NetworkQuality``

### Buffer Management

- ``BufferManager``
- ``BufferSizeProvider``
- ``BufferConfiguration``

### Memory Management

- ``MemoryMonitor``
- ``MemoryStateProvider``
- ``MemoryState``
- ``MemoryThresholds``

### Resource Cleanup

- ``ResourceCleaner``
- ``CleanupPriority``
- ``CleanupResult``

### Logging

- ``Logger``
- ``LogLevel``
- ``LogEntry``
- ``LogContext``

### Analytics

- ``PlaybackAnalyticsLogger``
- ``PlaybackSession``
- ``PlaybackEventType``
