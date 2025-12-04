//
//  PlaybackAnalyticsService.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Analytics service for tracking playback sessions and events.
/// Uses @MainActor isolation following Essential Feed patterns for thread-safety.
@MainActor
public final class PlaybackAnalyticsService: PlaybackAnalyticsLogger {
    private let store: AnalyticsStore
    private let currentDate: () -> Date
    private let uuidGenerator: () -> UUID

    private var currentSession: PlaybackSession?
    private var performanceTracker: PerformanceTracker?

    public init(
        store: AnalyticsStore,
        currentDate: @escaping () -> Date = { Date() },
        uuidGenerator: @escaping () -> UUID = { UUID() }
    ) {
        self.store = store
        self.currentDate = currentDate
        self.uuidGenerator = uuidGenerator
    }

    public func startSession(
        videoID: UUID,
        videoTitle: String,
        deviceInfo: DeviceInfo,
        appVersion: String
    ) async -> PlaybackSession {
        let sessionID = uuidGenerator()
        let session = PlaybackSession(
            id: sessionID,
            videoID: videoID,
            videoTitle: videoTitle,
            startTime: currentDate(),
            endTime: nil,
            deviceInfo: deviceInfo,
            appVersion: appVersion
        )

        currentSession = session
        performanceTracker = PerformanceTracker(sessionID: sessionID)

        try? await store.insert(session.toLocal())
        return session
    }

    public func log(_ event: PlaybackEventType, position: TimeInterval) async {
        guard let session = currentSession else { return }

        let playbackEvent = PlaybackEvent(
            id: uuidGenerator(),
            sessionID: session.id,
            videoID: session.videoID,
            type: event,
            timestamp: currentDate(),
            currentPosition: position
        )

        try? await store.insertEvent(playbackEvent.toLocal())
    }

    public func endSession(watchedDuration: TimeInterval, completed: Bool) async {
        guard var session = currentSession else { return }

        let eventType: PlaybackEventType = completed
            ? .videoCompleted
            : .videoAbandoned(watchedDuration: watchedDuration, totalDuration: 0)

        await log(eventType, position: watchedDuration)

        session = PlaybackSession(
            id: session.id,
            videoID: session.videoID,
            videoTitle: session.videoTitle,
            startTime: session.startTime,
            endTime: currentDate(),
            deviceInfo: session.deviceInfo,
            appVersion: session.appVersion
        )

        try? await store.updateSession(session.toLocal())

        currentSession = nil
        performanceTracker = nil
    }

    public func getCurrentPerformanceMetrics(watchDuration: TimeInterval) -> PerformanceMetrics? {
        performanceTracker?.buildMetrics(watchDuration: watchDuration)
    }

    public func trackVideoLoadStarted() {
        performanceTracker?.videoLoadStarted(at: currentDate())
    }

    public func trackFirstFrameRendered() {
        performanceTracker?.firstFrameRendered(at: currentDate())
    }

    public func trackBufferingStarted() {
        performanceTracker?.bufferingStarted(at: currentDate())
    }

    public func trackBufferingEnded() {
        performanceTracker?.bufferingEnded(at: currentDate())
    }
}
