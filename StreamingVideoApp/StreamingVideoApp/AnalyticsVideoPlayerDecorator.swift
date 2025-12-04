//
//  AnalyticsVideoPlayerDecorator.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import StreamingCore

/// A decorator that adds analytics logging to any VideoPlayer implementation.
/// Uses @MainActor isolation following Essential Feed patterns for thread-safety.
@MainActor
public final class AnalyticsVideoPlayerDecorator: VideoPlayer {
	private let decoratee: VideoPlayer
	private let analyticsLogger: PlaybackAnalyticsLogger

	public init(decoratee: VideoPlayer, analyticsLogger: PlaybackAnalyticsLogger) {
		self.decoratee = decoratee
		self.analyticsLogger = analyticsLogger
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
		Task { await logger.trackVideoLoadStarted() }
	}

	public func play() {
		decoratee.play()
		let position = currentTime
		let logger = analyticsLogger
		Task { await logger.log(.play, position: position) }
	}

	public func pause() {
		decoratee.pause()
		let position = currentTime
		let logger = analyticsLogger
		Task { await logger.log(.pause, position: position) }
	}

	public func seekForward(by seconds: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seekForward(by: seconds)
		let toPosition = currentTime
		let logger = analyticsLogger
		Task { await logger.log(.seek(from: fromPosition, to: toPosition), position: toPosition) }
	}

	public func seekBackward(by seconds: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seekBackward(by: seconds)
		let toPosition = currentTime
		let logger = analyticsLogger
		Task { await logger.log(.seek(from: fromPosition, to: toPosition), position: toPosition) }
	}

	public func seek(to time: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seek(to: time)
		let logger = analyticsLogger
		Task { await logger.log(.seek(from: fromPosition, to: time), position: time) }
	}

	public func setVolume(_ volume: Float) {
		let oldVolume = self.volume
		decoratee.setVolume(volume)
		let position = currentTime
		let logger = analyticsLogger
		Task { await logger.log(.volumeChanged(from: oldVolume, to: volume), position: position) }
	}

	public func toggleMute() {
		decoratee.toggleMute()
		let isMuted = self.isMuted
		let position = currentTime
		let logger = analyticsLogger
		Task { await logger.log(.muteToggled(isMuted: isMuted), position: position) }
	}

	public func setPlaybackSpeed(_ speed: Float) {
		let oldSpeed = playbackSpeed
		decoratee.setPlaybackSpeed(speed)
		let position = currentTime
		let logger = analyticsLogger
		Task { await logger.log(.speedChanged(from: oldSpeed, to: speed), position: position) }
	}
}
