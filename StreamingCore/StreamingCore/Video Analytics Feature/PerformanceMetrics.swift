//
//  PerformanceMetrics.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct PerformanceMetrics: Equatable, Sendable {
    public let sessionID: UUID
    public let timeToFirstFrame: TimeInterval?
    public let bufferingEvents: Int
    public let totalBufferingDuration: TimeInterval
    public let watchDuration: TimeInterval

    public var rebufferingRatio: Double {
        guard watchDuration > 0 else { return 0 }
        return totalBufferingDuration / watchDuration
    }

    public init(
        sessionID: UUID,
        timeToFirstFrame: TimeInterval?,
        bufferingEvents: Int,
        totalBufferingDuration: TimeInterval,
        watchDuration: TimeInterval
    ) {
        self.sessionID = sessionID
        self.timeToFirstFrame = timeToFirstFrame
        self.bufferingEvents = bufferingEvents
        self.totalBufferingDuration = totalBufferingDuration
        self.watchDuration = watchDuration
    }
}
