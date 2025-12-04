//
//  StatefulVideoPlayer.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamingCore

/// A video player decorator that integrates with the playback state machine.
/// Enforces valid state transitions and exposes state via Combine publishers.
/// Uses Essential Feed pattern: store Tasks and cancel in deinit.
public final class StatefulVideoPlayer: VideoPlayer {
	private let decoratee: VideoPlayer
	private let stateMachine: DefaultPlaybackStateMachine
	private var cancellables = Set<AnyCancellable>()
	private var pendingTasks = Set<Task<Void, Never>>()
	private let tasksLock = NSLock()

	deinit {
		tasksLock.lock()
		let tasks = pendingTasks
		tasksLock.unlock()
		for task in tasks {
			task.cancel()
		}
	}

	private func addTask(_ task: Task<Void, Never>) {
		tasksLock.lock()
		pendingTasks.insert(task)
		tasksLock.unlock()
	}

	private func scheduleStateMachineAction(_ work: @escaping @MainActor @Sendable () -> Void) {
		let task = Task { @MainActor [weak self] in
			guard self != nil else { return }
			work()
		}
		addTask(task)
	}

	/// Publisher that emits the current playback state
	public var statePublisher: AnyPublisher<PlaybackState, Never> {
		stateMachine.statePublisher
	}

	/// Publisher that emits state transitions
	public var transitionPublisher: AnyPublisher<PlaybackTransition, Never> {
		stateMachine.transitionPublisher
	}

	/// The current playback state
	public var currentPlaybackState: PlaybackState {
		stateMachine.currentState
	}

	// MARK: - VideoPlayer Protocol Properties

	public var isPlaying: Bool {
		currentPlaybackState == .playing
	}

	public var currentTime: TimeInterval {
		decoratee.currentTime
	}

	public var duration: TimeInterval {
		decoratee.duration
	}

	public var volume: Float {
		decoratee.volume
	}

	public var isMuted: Bool {
		decoratee.isMuted
	}

	public var playbackSpeed: Float {
		decoratee.playbackSpeed
	}

	// MARK: - Initialization

	public init(decoratee: VideoPlayer, stateMachine: DefaultPlaybackStateMachine) {
		self.decoratee = decoratee
		self.stateMachine = stateMachine
	}

	// MARK: - VideoPlayer Protocol Methods

	public func load(url: URL) {
		decoratee.load(url: url)
		let machine = stateMachine
		scheduleStateMachineAction {
			machine.send(.load(url))
		}
	}

	public func play() {
		let machine = stateMachine
		let player = decoratee
		scheduleStateMachineAction {
			if machine.canPerform(.play) {
				machine.send(.play)
				player.play()
			}
		}
	}

	public func pause() {
		let machine = stateMachine
		let player = decoratee
		scheduleStateMachineAction {
			if machine.canPerform(.pause) {
				machine.send(.pause)
				player.pause()
			}
		}
	}

	public func seek(to time: TimeInterval) {
		let machine = stateMachine
		let player = decoratee
		scheduleStateMachineAction {
			let currentState = machine.currentState
			if case .playing = currentState {
				machine.send(.seek(to: time))
				player.seek(to: time)
				machine.send(.didFinishSeeking)
			} else if case .paused = currentState {
				machine.send(.seek(to: time))
				player.seek(to: time)
				machine.send(.didFinishSeeking)
			} else {
				player.seek(to: time)
			}
		}
	}

	public func seekForward(by seconds: TimeInterval) {
		decoratee.seekForward(by: seconds)
	}

	public func seekBackward(by seconds: TimeInterval) {
		decoratee.seekBackward(by: seconds)
	}

	public func setVolume(_ volume: Float) {
		decoratee.setVolume(volume)
	}

	public func toggleMute() {
		decoratee.toggleMute()
	}

	public func setPlaybackSpeed(_ speed: Float) {
		decoratee.setPlaybackSpeed(speed)
	}

	/// Stops playback and returns to idle state
	public func stop() {
		let machine = stateMachine
		let player = decoratee
		scheduleStateMachineAction {
			machine.send(.stop)
			player.pause()
		}
	}

	// MARK: - State Machine Event Simulation (for external events)

	/// Call when the player item becomes ready to play
	@MainActor
	public func simulateDidBecomeReady() {
		stateMachine.send(.didBecomeReady)
	}

	/// Call when playback reaches the end
	@MainActor
	public func simulateDidReachEnd() {
		stateMachine.send(.didReachEnd)
	}

	/// Call when buffering starts
	@MainActor
	public func simulateDidStartBuffering() {
		stateMachine.send(.didStartBuffering)
	}

	/// Call when buffering ends
	@MainActor
	public func simulateDidFinishBuffering() {
		stateMachine.send(.didFinishBuffering)
	}

	/// Call when a playback error occurs
	@MainActor
	public func simulateDidFail(_ error: PlaybackError) {
		stateMachine.send(.didFail(error))
	}

	/// Call when the app enters background
	@MainActor
	public func simulateDidEnterBackground() {
		stateMachine.send(.didEnterBackground)
	}

	/// Call when audio session is interrupted
	@MainActor
	public func simulateAudioSessionInterrupted() {
		stateMachine.send(.audioSessionInterrupted)
	}

	/// Call when audio session interruption ends
	@MainActor
	public func simulateAudioSessionResumed() {
		stateMachine.send(.audioSessionResumed)
	}
}
