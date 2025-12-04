//
//  AnalyticsVideoPlayerDecorator.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import StreamingCore

/// A decorator that adds analytics logging to any VideoPlayer implementation.
/// Uses Essential Feed pattern: store Tasks and cancel in deinit.
public final class AnalyticsVideoPlayerDecorator: VideoPlayer {
    private let decoratee: VideoPlayer
    private let analyticsLogger: PlaybackAnalyticsLogger
    private var pendingTasks = Set<Task<Void, Never>>()
    private let tasksLock = NSLock()

    public init(decoratee: VideoPlayer, analyticsLogger: PlaybackAnalyticsLogger) {
        self.decoratee = decoratee
        self.analyticsLogger = analyticsLogger
    }

    deinit {
        tasksLock.lock()
        let tasks = pendingTasks
        tasksLock.unlock()
        for task in tasks {
            task.cancel()
        }
    }

    // MARK: - Private Task Management

    private func addTask(_ task: Task<Void, Never>) {
        tasksLock.lock()
        pendingTasks.insert(task)
        tasksLock.unlock()
    }

    private func scheduleAnalytics(_ work: @escaping @Sendable () async -> Void) {
        let task = Task { [weak self] in
            guard self != nil else { return }
            await work()
        }
        addTask(task)
    }

    // MARK: - VideoPlayer Properties

    public var isPlaying: Bool { decoratee.isPlaying }
    public var currentTime: TimeInterval { decoratee.currentTime }
    public var duration: TimeInterval { decoratee.duration }
    public var volume: Float { decoratee.volume }
    public var isMuted: Bool { decoratee.isMuted }
    public var playbackSpeed: Float { decoratee.playbackSpeed }

    // MARK: - VideoPlayer Methods

    public func load(url: URL) {
        decoratee.load(url: url)
        let logger = analyticsLogger
        scheduleAnalytics { await logger.trackVideoLoadStarted() }
    }

    public func play() {
        decoratee.play()
        let position = currentTime
        let logger = analyticsLogger
        scheduleAnalytics { await logger.log(.play, position: position) }
    }

    public func pause() {
        decoratee.pause()
        let position = currentTime
        let logger = analyticsLogger
        scheduleAnalytics { await logger.log(.pause, position: position) }
    }

    public func seekForward(by seconds: TimeInterval) {
        let fromPosition = currentTime
        decoratee.seekForward(by: seconds)
        let toPosition = currentTime
        let logger = analyticsLogger
        scheduleAnalytics { await logger.log(.seek(from: fromPosition, to: toPosition), position: toPosition) }
    }

    public func seekBackward(by seconds: TimeInterval) {
        let fromPosition = currentTime
        decoratee.seekBackward(by: seconds)
        let toPosition = currentTime
        let logger = analyticsLogger
        scheduleAnalytics { await logger.log(.seek(from: fromPosition, to: toPosition), position: toPosition) }
    }

    public func seek(to time: TimeInterval) {
        let fromPosition = currentTime
        decoratee.seek(to: time)
        let logger = analyticsLogger
        scheduleAnalytics { await logger.log(.seek(from: fromPosition, to: time), position: time) }
    }

    public func setVolume(_ volume: Float) {
        let oldVolume = self.volume
        decoratee.setVolume(volume)
        let position = currentTime
        let logger = analyticsLogger
        scheduleAnalytics { await logger.log(.volumeChanged(from: oldVolume, to: volume), position: position) }
    }

    public func toggleMute() {
        decoratee.toggleMute()
        let isMuted = self.isMuted
        let position = currentTime
        let logger = analyticsLogger
        scheduleAnalytics { await logger.log(.muteToggled(isMuted: isMuted), position: position) }
    }

    public func setPlaybackSpeed(_ speed: Float) {
        let oldSpeed = playbackSpeed
        decoratee.setPlaybackSpeed(speed)
        let position = currentTime
        let logger = analyticsLogger
        scheduleAnalytics { await logger.log(.speedChanged(from: oldSpeed, to: speed), position: position) }
    }
}
