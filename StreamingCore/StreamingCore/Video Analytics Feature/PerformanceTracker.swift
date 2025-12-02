//
//  PerformanceTracker.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public final class PerformanceTracker: @unchecked Sendable {
    private let sessionID: UUID
    private let lock = NSLock()

    private var loadStartTime: Date?
    private var firstFrameTime: Date?
    private var bufferingStartTime: Date?
    private var bufferingEventsCount: Int = 0
    private var totalBufferingDuration: TimeInterval = 0

    public init(sessionID: UUID) {
        self.sessionID = sessionID
    }

    public func videoLoadStarted(at time: Date) {
        lock.withLock {
            guard loadStartTime == nil else { return }
            loadStartTime = time
        }
    }

    public func firstFrameRendered(at time: Date) {
        lock.withLock {
            guard loadStartTime != nil, firstFrameTime == nil else { return }
            firstFrameTime = time
        }
    }

    public func bufferingStarted(at time: Date) {
        lock.withLock {
            bufferingStartTime = time
        }
    }

    public func bufferingEnded(at time: Date) {
        lock.withLock {
            guard let startTime = bufferingStartTime else { return }
            let duration = time.timeIntervalSince(startTime)
            totalBufferingDuration += duration
            bufferingEventsCount += 1
            bufferingStartTime = nil
        }
    }

    public func buildMetrics(watchDuration: TimeInterval) -> PerformanceMetrics {
        lock.withLock {
            let timeToFirstFrame: TimeInterval? = {
                guard let loadStart = loadStartTime, let firstFrame = firstFrameTime else { return nil }
                return firstFrame.timeIntervalSince(loadStart)
            }()

            return PerformanceMetrics(
                sessionID: sessionID,
                timeToFirstFrame: timeToFirstFrame,
                bufferingEvents: bufferingEventsCount,
                totalBufferingDuration: totalBufferingDuration,
                watchDuration: watchDuration
            )
        }
    }
}
