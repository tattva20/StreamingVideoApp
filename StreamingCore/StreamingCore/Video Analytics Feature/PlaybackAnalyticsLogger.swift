//
//  PlaybackAnalyticsLogger.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

@MainActor
public protocol PlaybackAnalyticsLogger: AnyObject {
    func startSession(videoID: UUID, videoTitle: String, deviceInfo: DeviceInfo, appVersion: String) async -> PlaybackSession
    func log(_ event: PlaybackEventType, position: TimeInterval) async
    func endSession(watchedDuration: TimeInterval, completed: Bool) async
    func getCurrentPerformanceMetrics(watchDuration: TimeInterval) -> PerformanceMetrics?
    func trackVideoLoadStarted()
    func trackFirstFrameRendered()
    func trackBufferingStarted()
    func trackBufferingEnded()
}
