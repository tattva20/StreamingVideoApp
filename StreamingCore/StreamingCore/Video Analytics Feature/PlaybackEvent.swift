//
//  PlaybackEvent.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public enum PlaybackEventType: Equatable, Sendable, Codable {
    case videoStarted
    case play
    case pause
    case seek(from: TimeInterval, to: TimeInterval)
    case speedChanged(from: Float, to: Float)
    case volumeChanged(from: Float, to: Float)
    case muteToggled(isMuted: Bool)
    case videoCompleted
    case videoAbandoned(watchedDuration: TimeInterval, totalDuration: TimeInterval)
    case fullscreenEntered
    case fullscreenExited
    case pipEntered
    case pipExited
    case error(code: String, message: String)
    case bufferingStarted
    case bufferingEnded(duration: TimeInterval)
    case qualityChanged(from: String?, to: String)
}

public struct PlaybackEvent: Equatable, Sendable {
    public let id: UUID
    public let sessionID: UUID
    public let videoID: UUID
    public let type: PlaybackEventType
    public let timestamp: Date
    public let currentPosition: TimeInterval

    public init(
        id: UUID,
        sessionID: UUID,
        videoID: UUID,
        type: PlaybackEventType,
        timestamp: Date,
        currentPosition: TimeInterval
    ) {
        self.id = id
        self.sessionID = sessionID
        self.videoID = videoID
        self.type = type
        self.timestamp = timestamp
        self.currentPosition = currentPosition
    }
}
