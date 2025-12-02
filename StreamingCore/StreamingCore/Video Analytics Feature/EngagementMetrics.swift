//
//  EngagementMetrics.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct EngagementMetrics: Equatable, Sendable {
    public let sessionID: UUID
    public let watchDuration: TimeInterval
    public let videoDuration: TimeInterval
    public let seekCount: Int
    public let pauseCount: Int

    public var completionPercentage: Double {
        guard videoDuration > 0 else { return 0 }
        return min(100, (watchDuration / videoDuration) * 100)
    }

    public init(
        sessionID: UUID,
        watchDuration: TimeInterval,
        videoDuration: TimeInterval,
        seekCount: Int,
        pauseCount: Int
    ) {
        self.sessionID = sessionID
        self.watchDuration = watchDuration
        self.videoDuration = videoDuration
        self.seekCount = seekCount
        self.pauseCount = pauseCount
    }
}
