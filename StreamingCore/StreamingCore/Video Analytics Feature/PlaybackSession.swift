//
//  PlaybackSession.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct DeviceInfo: Equatable, Sendable, Codable {
    public let model: String
    public let osVersion: String
    public let networkType: String?

    public init(model: String, osVersion: String, networkType: String?) {
        self.model = model
        self.osVersion = osVersion
        self.networkType = networkType
    }
}

public struct PlaybackSession: Equatable, Sendable {
    public let id: UUID
    public let videoID: UUID
    public let videoTitle: String
    public let startTime: Date
    public var endTime: Date?
    public let deviceInfo: DeviceInfo
    public let appVersion: String

    public init(
        id: UUID,
        videoID: UUID,
        videoTitle: String,
        startTime: Date,
        endTime: Date?,
        deviceInfo: DeviceInfo,
        appVersion: String
    ) {
        self.id = id
        self.videoID = videoID
        self.videoTitle = videoTitle
        self.startTime = startTime
        self.endTime = endTime
        self.deviceInfo = deviceInfo
        self.appVersion = appVersion
    }
}
