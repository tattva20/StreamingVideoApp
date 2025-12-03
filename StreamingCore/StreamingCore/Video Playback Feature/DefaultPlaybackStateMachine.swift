//
//  DefaultPlaybackStateMachine.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import Combine

/// Thread-safe actor implementation of the playback state machine.
/// Enforces valid state transitions and emits state changes via Combine publishers.
public actor DefaultPlaybackStateMachine {

	private var _currentState: PlaybackState = .idle
	private nonisolated(unsafe) let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
	private nonisolated(unsafe) let transitionSubject = PassthroughSubject<PlaybackTransition, Never>()
	private let currentDate: @Sendable () -> Date

	/// The current playback state
	public nonisolated var currentState: PlaybackState {
		stateSubject.value
	}

	/// Publisher that emits the current state and all future state changes
	public nonisolated var statePublisher: AnyPublisher<PlaybackState, Never> {
		stateSubject.eraseToAnyPublisher()
	}

	/// Publisher that emits only state transitions (not the initial state)
	public nonisolated var transitionPublisher: AnyPublisher<PlaybackTransition, Never> {
		transitionSubject.eraseToAnyPublisher()
	}

	public init(currentDate: @escaping @Sendable () -> Date = { Date() }) {
		self.currentDate = currentDate
	}

	/// Sends an action to the state machine and returns the resulting transition if valid.
	/// Returns nil and keeps state unchanged if the action is invalid for the current state.
	@discardableResult
	public func send(_ action: PlaybackAction) -> PlaybackTransition? {
		guard let nextState = nextState(for: action, from: _currentState) else {
			return nil
		}

		let transition = PlaybackTransition(
			from: _currentState,
			to: nextState,
			action: action,
			timestamp: currentDate()
		)

		_currentState = nextState
		stateSubject.send(nextState)
		transitionSubject.send(transition)

		return transition
	}

	/// Checks if an action can be performed in the current state without actually performing it.
	public func canPerform(_ action: PlaybackAction) -> Bool {
		nextState(for: action, from: _currentState) != nil
	}

	// MARK: - State Transition Logic

	private func nextState(for action: PlaybackAction, from state: PlaybackState) -> PlaybackState? {
		switch (state, action) {
		// MARK: From idle
		case (.idle, .load(let url)):
			return .loading(url)

		// MARK: From loading
		case (.loading, .didBecomeReady):
			return .ready
		case (.loading, .didFail(let error)):
			return .failed(error)
		case (.loading, .stop):
			return .idle

		// MARK: From ready
		case (.ready, .play):
			return .playing
		case (.ready, .stop):
			return .idle
		case (.ready, .load(let url)):
			return .loading(url)

		// MARK: From playing
		case (.playing, .pause):
			return .paused
		case (.playing, .didStartBuffering):
			return .buffering(previousState: .playing)
		case (.playing, .seek(let time)):
			return .seeking(to: time, previousState: .playing)
		case (.playing, .didReachEnd):
			return .ended
		case (.playing, .didFail(let error)):
			return .failed(error)
		case (.playing, .stop):
			return .idle
		case (.playing, .didEnterBackground):
			return .paused
		case (.playing, .audioSessionInterrupted):
			return .paused

		// MARK: From paused
		case (.paused, .play):
			return .playing
		case (.paused, .didStartBuffering):
			return .buffering(previousState: .paused)
		case (.paused, .seek(let time)):
			return .seeking(to: time, previousState: .paused)
		case (.paused, .stop):
			return .idle
		case (.paused, .load(let url)):
			return .loading(url)
		case (.paused, .audioSessionResumed):
			return .playing

		// MARK: From buffering
		case (.buffering(let previous), .didFinishBuffering):
			return previous == .playing ? .playing : .paused
		case (.buffering, .pause):
			return .buffering(previousState: .paused)
		case (.buffering, .play):
			return .buffering(previousState: .playing)
		case (.buffering, .didFail(let error)):
			return .failed(error)
		case (.buffering, .stop):
			return .idle

		// MARK: From seeking
		case (.seeking(_, let previous), .didFinishSeeking):
			return previous == .playing ? .playing : .paused
		case (.seeking(let time, _), .pause):
			return .seeking(to: time, previousState: .paused)
		case (.seeking(let time, _), .play):
			return .seeking(to: time, previousState: .playing)
		case (.seeking, .didFail(let error)):
			return .failed(error)
		case (.seeking, .stop):
			return .idle

		// MARK: From ended
		case (.ended, .play):
			return .playing
		case (.ended, .seek(let time)):
			return .seeking(to: time, previousState: .paused)
		case (.ended, .stop):
			return .idle
		case (.ended, .load(let url)):
			return .loading(url)

		// MARK: From failed
		case (.failed(let error), .retry) where error.isRecoverable:
			return .idle
		case (.failed, .stop):
			return .idle
		case (.failed, .load(let url)):
			return .loading(url)

		default:
			return nil
		}
	}
}
