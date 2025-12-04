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
/// Uses @MainActor isolation following Essential Feed patterns for thread-safety.
@MainActor
public final class StatefulVideoPlayer: VideoPlayer {
	private let decoratee: VideoPlayer
	private let stateMachine: DefaultPlaybackStateMachine
	private var cancellables = Set<AnyCancellable>()

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
		decoratee.isPlaying
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
		stateMachine.send(.load(url))
	}

	public func play() {
		decoratee.play()
		if stateMachine.canPerform(.play) {
			stateMachine.send(.play)
		}
	}

	public func pause() {
		decoratee.pause()
		if stateMachine.canPerform(.pause) {
			stateMachine.send(.pause)
		}
	}

	public func seek(to time: TimeInterval) {
		let currentState = stateMachine.currentState
		if case .playing = currentState {
			stateMachine.send(.seek(to: time))
			decoratee.seek(to: time)
			stateMachine.send(.didFinishSeeking)
		} else if case .paused = currentState {
			stateMachine.send(.seek(to: time))
			decoratee.seek(to: time)
			stateMachine.send(.didFinishSeeking)
		} else {
			decoratee.seek(to: time)
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
		stateMachine.send(.stop)
		decoratee.pause()
	}

	// MARK: - State Machine Event Simulation (for external events)

	/// Call when the player item becomes ready to play
	public func simulateDidBecomeReady() {
		stateMachine.send(.didBecomeReady)
	}

	/// Call when playback reaches the end
	public func simulateDidReachEnd() {
		stateMachine.send(.didReachEnd)
	}

	/// Call when buffering starts
	public func simulateDidStartBuffering() {
		stateMachine.send(.didStartBuffering)
	}

	/// Call when buffering ends
	public func simulateDidFinishBuffering() {
		stateMachine.send(.didFinishBuffering)
	}

	/// Call when a playback error occurs
	public func simulateDidFail(_ error: PlaybackError) {
		stateMachine.send(.didFail(error))
	}

	/// Call when the app enters background
	public func simulateDidEnterBackground() {
		stateMachine.send(.didEnterBackground)
	}

	/// Call when audio session is interrupted
	public func simulateAudioSessionInterrupted() {
		stateMachine.send(.audioSessionInterrupted)
	}

	/// Call when audio session interruption ends
	public func simulateAudioSessionResumed() {
		stateMachine.send(.audioSessionResumed)
	}
}
