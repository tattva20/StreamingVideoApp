//
//  LoggingVideoPlayerDecorator.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import StreamingCore

/// A decorator that adds structured logging to any VideoPlayer implementation.
/// Uses Essential Feed pattern: store Tasks and cancel in deinit.
public final class LoggingVideoPlayerDecorator: VideoPlayer {
	private let decoratee: VideoPlayer
	private let logger: Logger
	private let correlationID: UUID
	private var pendingTasks = Set<Task<Void, Never>>()
	private let tasksLock = NSLock()

	public init(
		decoratee: VideoPlayer,
		logger: Logger,
		correlationID: UUID = UUID()
	) {
		self.decoratee = decoratee
		self.logger = logger
		self.correlationID = correlationID
	}

	deinit {
		tasksLock.lock()
		let tasks = pendingTasks
		tasksLock.unlock()
		for task in tasks {
			task.cancel()
		}
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
		logEvent("Loading video", metadata: ["url": url.absoluteString])
	}

	public func play() {
		decoratee.play()
		logEvent("Play requested", metadata: ["position": "\(currentTime)"])
	}

	public func pause() {
		decoratee.pause()
		logEvent("Pause requested", metadata: ["position": "\(currentTime)"])
	}

	public func seekForward(by seconds: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seekForward(by: seconds)
		logEvent("Seek forward", metadata: [
			"from": "\(fromPosition)",
			"by": "\(seconds)"
		])
	}

	public func seekBackward(by seconds: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seekBackward(by: seconds)
		logEvent("Seek backward", metadata: [
			"from": "\(fromPosition)",
			"by": "\(seconds)"
		])
	}

	public func seek(to time: TimeInterval) {
		let fromPosition = currentTime
		decoratee.seek(to: time)
		logEvent("Seek to position", metadata: [
			"from": "\(fromPosition)",
			"to": "\(time)"
		])
	}

	public func setVolume(_ volume: Float) {
		let oldVolume = self.volume
		decoratee.setVolume(volume)
		logEvent("Volume changed", metadata: [
			"from": "\(oldVolume)",
			"to": "\(volume)"
		], level: .debug)
	}

	public func toggleMute() {
		decoratee.toggleMute()
		logEvent("Mute toggled", metadata: ["isMuted": "\(isMuted)"], level: .debug)
	}

	public func setPlaybackSpeed(_ speed: Float) {
		let oldSpeed = playbackSpeed
		decoratee.setPlaybackSpeed(speed)
		logEvent("Playback speed changed", metadata: [
			"from": "\(oldSpeed)",
			"to": "\(speed)"
		], level: .debug)
	}

	// MARK: - Private Helpers

	private func logEvent(
		_ message: String,
		metadata: [String: String] = [:],
		level: LogLevel = .info
	) {
		let context = LogContext(
			subsystem: "VideoPlayer",
			category: "Playback",
			correlationID: correlationID,
			metadata: metadata
		)

		// Essential Feed pattern: store Task and cancel in deinit
		let task = Task { [weak self, logger, context, level, message] in
			guard self != nil else { return }
			await logger.log(LogEntry(level: level, message: message, context: context))
		}
		addTask(task)
	}

	private func addTask(_ task: Task<Void, Never>) {
		tasksLock.lock()
		pendingTasks.insert(task)
		tasksLock.unlock()
	}
}
