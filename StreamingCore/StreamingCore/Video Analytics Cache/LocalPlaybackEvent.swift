//
//  LocalPlaybackEvent.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct LocalPlaybackEvent: Equatable, Sendable {
    public let id: UUID
    public let sessionID: UUID
    public let videoID: UUID
    public let eventType: String
    public let eventData: Data?
    public let timestamp: Date
    public let currentPosition: TimeInterval

    public init(
        id: UUID,
        sessionID: UUID,
        videoID: UUID,
        eventType: String,
        eventData: Data?,
        timestamp: Date,
        currentPosition: TimeInterval
    ) {
        self.id = id
        self.sessionID = sessionID
        self.videoID = videoID
        self.eventType = eventType
        self.eventData = eventData
        self.timestamp = timestamp
        self.currentPosition = currentPosition
    }
}

public extension PlaybackEvent {
    func toLocal() -> LocalPlaybackEvent {
        let encoder = JSONEncoder()
        let eventData = try? encoder.encode(type)

        return LocalPlaybackEvent(
            id: id,
            sessionID: sessionID,
            videoID: videoID,
            eventType: type.typeIdentifier,
            eventData: eventData,
            timestamp: timestamp,
            currentPosition: currentPosition
        )
    }
}

public extension LocalPlaybackEvent {
    func toModel() -> PlaybackEvent? {
        guard let eventData = eventData else { return nil }

        let decoder = JSONDecoder()
        guard let eventType = try? decoder.decode(PlaybackEventType.self, from: eventData) else {
            return nil
        }

        return PlaybackEvent(
            id: id,
            sessionID: sessionID,
            videoID: videoID,
            type: eventType,
            timestamp: timestamp,
            currentPosition: currentPosition
        )
    }
}

public extension PlaybackEventType {
    var typeIdentifier: String {
        switch self {
        case .videoStarted: return "videoStarted"
        case .play: return "play"
        case .pause: return "pause"
        case .seek: return "seek"
        case .speedChanged: return "speedChanged"
        case .volumeChanged: return "volumeChanged"
        case .muteToggled: return "muteToggled"
        case .videoCompleted: return "videoCompleted"
        case .videoAbandoned: return "videoAbandoned"
        case .fullscreenEntered: return "fullscreenEntered"
        case .fullscreenExited: return "fullscreenExited"
        case .pipEntered: return "pipEntered"
        case .pipExited: return "pipExited"
        case .error: return "error"
        case .bufferingStarted: return "bufferingStarted"
        case .bufferingEnded: return "bufferingEnded"
        case .qualityChanged: return "qualityChanged"
        }
    }
}
