//
//  LocalPlaybackSession.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct LocalPlaybackSession: Equatable, Sendable {
    public let id: UUID
    public let videoID: UUID
    public let videoTitle: String
    public let startTime: Date
    public var endTime: Date?
    public let deviceModel: String
    public let osVersion: String
    public let networkType: String?
    public let appVersion: String

    public init(
        id: UUID,
        videoID: UUID,
        videoTitle: String,
        startTime: Date,
        endTime: Date?,
        deviceModel: String,
        osVersion: String,
        networkType: String?,
        appVersion: String
    ) {
        self.id = id
        self.videoID = videoID
        self.videoTitle = videoTitle
        self.startTime = startTime
        self.endTime = endTime
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.networkType = networkType
        self.appVersion = appVersion
    }
}

public extension PlaybackSession {
    func toLocal() -> LocalPlaybackSession {
        LocalPlaybackSession(
            id: id,
            videoID: videoID,
            videoTitle: videoTitle,
            startTime: startTime,
            endTime: endTime,
            deviceModel: deviceInfo.model,
            osVersion: deviceInfo.osVersion,
            networkType: deviceInfo.networkType,
            appVersion: appVersion
        )
    }
}

public extension LocalPlaybackSession {
    func toModel() -> PlaybackSession {
        PlaybackSession(
            id: id,
            videoID: videoID,
            videoTitle: videoTitle,
            startTime: startTime,
            endTime: endTime,
            deviceInfo: DeviceInfo(
                model: deviceModel,
                osVersion: osVersion,
                networkType: networkType
            ),
            appVersion: appVersion
        )
    }
}
