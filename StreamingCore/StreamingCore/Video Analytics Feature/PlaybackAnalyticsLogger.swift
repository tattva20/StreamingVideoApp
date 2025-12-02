//
//  PlaybackAnalyticsLogger.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public protocol PlaybackAnalyticsLogger: AnyObject, Sendable {
    func startSession(videoID: UUID, videoTitle: String, deviceInfo: DeviceInfo, appVersion: String) async -> PlaybackSession
    func log(_ event: PlaybackEventType, position: TimeInterval) async
    func endSession(watchedDuration: TimeInterval, completed: Bool) async
    func getCurrentPerformanceMetrics(watchDuration: TimeInterval) async -> PerformanceMetrics?
    func trackVideoLoadStarted() async
    func trackFirstFrameRendered() async
    func trackBufferingStarted() async
    func trackBufferingEnded() async
}
