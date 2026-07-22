//
//  AnalyticsVideoPlayerDecorator.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import StreamingCore

@MainActor
public final class AnalyticsVideoPlayerDecorator: VideoPlayer {
	private let decoratee: VideoPlayer
	private let analyticsLogger: PlaybackAnalyticsLogger
	private let continuation: AsyncStream<LoggedEvent>.Continuation
	private let processingTask: Task<Void, Never>

	public init(decoratee: VideoPlayer, analyticsLogger: PlaybackAnalyticsLogger) {
		self.decoratee = decoratee
		self.analyticsLogger = analyticsLogger

		let (stream, continuation) = AsyncStream<LoggedEvent>.makeStream()
		self.continuation = continuation
		self.processingTask = Task {
			for await event in stream {
				await analyticsLogger.log(event.type, position: event.position)
			}
		}
	}

	deinit {
		continuation.finish()
		processingTask.cancel()
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
		analyticsLogger.trackVideoLoadStarted()
	}

	public func play() {
		decoratee.play()
		enqueue(.play, position: currentTime)
	}

	public func pause() {
		decoratee.pause()
		enqueue(.pause, position: currentTime)
	}

	public func seekForward(by seconds: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seekForward(by: seconds)
		let toPosition = currentTime
		enqueue(.seek(from: fromPosition, to: toPosition), position: toPosition)
	}

	public func seekBackward(by seconds: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seekBackward(by: seconds)
		let toPosition = currentTime
		enqueue(.seek(from: fromPosition, to: toPosition), position: toPosition)
	}

	public func seek(to time: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seek(to: time)
		enqueue(.seek(from: fromPosition, to: time), position: time)
	}

	public func setVolume(_ volume: Float) {
		let oldVolume = self.volume
		decoratee.setVolume(volume)
		enqueue(.volumeChanged(from: oldVolume, to: volume), position: currentTime)
	}

	public func toggleMute() {
		decoratee.toggleMute()
		enqueue(.muteToggled(isMuted: isMuted), position: currentTime)
	}

	public func setPlaybackSpeed(_ speed: Float) {
		let oldSpeed = playbackSpeed
		decoratee.setPlaybackSpeed(speed)
		enqueue(.speedChanged(from: oldSpeed, to: speed), position: currentTime)
	}

	private func enqueue(_ type: PlaybackEventType, position: TimeInterval) {
		continuation.yield(LoggedEvent(type: type, position: position))
	}
}

private struct LoggedEvent: Sendable {
	let type: PlaybackEventType
	let position: TimeInterval
}
