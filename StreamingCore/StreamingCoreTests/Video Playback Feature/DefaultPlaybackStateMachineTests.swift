//
//  DefaultPlaybackStateMachineTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
@testable import StreamingCore

@MainActor
final class DefaultPlaybackStateMachineTests: XCTestCase {

	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		cancellables.removeAll()
		super.tearDown()
	}

	// MARK: - Initial State

	func test_init_startsInIdleState() {
		let sut = makeSUT()

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
	}

	// MARK: - Idle State Transitions

	func test_sendLoad_fromIdle_transitionsToLoading() {
		let sut = makeSUT()
		let url = anyURL()

		let transition = sut.send(.load(url))

		let state = sut.currentState
		XCTAssertEqual(state, .loading(url))
		XCTAssertEqual(transition?.to, .loading(url))
	}

	func test_sendPlay_fromIdle_isRejected() {
		let sut = makeSUT()

		let transition = sut.send(.play)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertNil(transition)
	}

	// MARK: - Loading State Transitions

	func test_sendDidBecomeReady_fromLoading_transitionsToReady() {
		let sut = makeSUT()
		sut.send(.load(anyURL()))

		let transition = sut.send(.didBecomeReady)

		let state = sut.currentState
		XCTAssertEqual(state, .ready)
		XCTAssertEqual(transition?.to, .ready)
	}

	func test_sendDidFail_fromLoading_transitionsToFailed() {
		let sut = makeSUT()
		sut.send(.load(anyURL()))
		let error = PlaybackError.networkError(reason: "Timeout")

		let transition = sut.send(.didFail(error))

		let state = sut.currentState
		XCTAssertEqual(state, .failed(error))
		XCTAssertEqual(transition?.to, .failed(error))
	}

	func test_sendStop_fromLoading_transitionsToIdle() {
		let sut = makeSUT()
		sut.send(.load(anyURL()))

		let transition = sut.send(.stop)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	// MARK: - Ready State Transitions

	func test_sendPlay_fromReady_transitionsToPlaying() {
		let sut = makeSUTInReadyState()

		let transition = sut.send(.play)

		let state = sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendStop_fromReady_transitionsToIdle() {
		let sut = makeSUTInReadyState()

		let transition = sut.send(.stop)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendLoad_fromReady_transitionsToLoading() {
		let sut = makeSUTInReadyState()
		let newURL = URL(string: "https://example.com/video2.mp4")!

		let transition = sut.send(.load(newURL))

		let state = sut.currentState
		XCTAssertEqual(state, .loading(newURL))
		XCTAssertEqual(transition?.to, .loading(newURL))
	}

	// MARK: - Playing State Transitions

	func test_sendPause_fromPlaying_transitionsToPaused() {
		let sut = makeSUTInPlayingState()

		let transition = sut.send(.pause)

		let state = sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	func test_sendDidStartBuffering_fromPlaying_transitionsToBuffering() {
		let sut = makeSUTInPlayingState()

		let transition = sut.send(.didStartBuffering)

		let state = sut.currentState
		XCTAssertEqual(state, .buffering(previousState: .playing))
		XCTAssertEqual(transition?.to, .buffering(previousState: .playing))
	}

	func test_sendSeek_fromPlaying_transitionsToSeeking() {
		let sut = makeSUTInPlayingState()

		let transition = sut.send(.seek(to: 30.0))

		let state = sut.currentState
		XCTAssertEqual(state, .seeking(to: 30.0, previousState: .playing))
		XCTAssertEqual(transition?.to, .seeking(to: 30.0, previousState: .playing))
	}

	func test_sendDidReachEnd_fromPlaying_transitionsToEnded() {
		let sut = makeSUTInPlayingState()

		let transition = sut.send(.didReachEnd)

		let state = sut.currentState
		XCTAssertEqual(state, .ended)
		XCTAssertEqual(transition?.to, .ended)
	}

	func test_sendDidFail_fromPlaying_transitionsToFailed() {
		let sut = makeSUTInPlayingState()
		let error = PlaybackError.networkError(reason: "Lost connection")

		let transition = sut.send(.didFail(error))

		let state = sut.currentState
		XCTAssertEqual(state, .failed(error))
		XCTAssertEqual(transition?.to, .failed(error))
	}

	func test_sendStop_fromPlaying_transitionsToIdle() {
		let sut = makeSUTInPlayingState()

		let transition = sut.send(.stop)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendDidEnterBackground_fromPlaying_transitionsToPaused() {
		let sut = makeSUTInPlayingState()

		let transition = sut.send(.didEnterBackground)

		let state = sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	// MARK: - Paused State Transitions

	func test_sendPlay_fromPaused_transitionsToPlaying() {
		let sut = makeSUTInPausedState()

		let transition = sut.send(.play)

		let state = sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendDidStartBuffering_fromPaused_transitionsToBufferingWithPausedPrevious() {
		let sut = makeSUTInPausedState()

		let transition = sut.send(.didStartBuffering)

		let state = sut.currentState
		XCTAssertEqual(state, .buffering(previousState: .paused))
		XCTAssertEqual(transition?.to, .buffering(previousState: .paused))
	}

	func test_sendSeek_fromPaused_transitionsToSeekingWithPausedPrevious() {
		let sut = makeSUTInPausedState()

		let transition = sut.send(.seek(to: 15.0))

		let state = sut.currentState
		XCTAssertEqual(state, .seeking(to: 15.0, previousState: .paused))
		XCTAssertEqual(transition?.to, .seeking(to: 15.0, previousState: .paused))
	}

	func test_sendStop_fromPaused_transitionsToIdle() {
		let sut = makeSUTInPausedState()

		let transition = sut.send(.stop)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendLoad_fromPaused_transitionsToLoading() {
		let sut = makeSUTInPausedState()
		let newURL = URL(string: "https://example.com/video2.mp4")!

		let transition = sut.send(.load(newURL))

		let state = sut.currentState
		XCTAssertEqual(state, .loading(newURL))
		XCTAssertEqual(transition?.to, .loading(newURL))
	}

	// MARK: - Buffering State Transitions

	func test_sendDidFinishBuffering_fromBufferingPlaying_transitionsToPlaying() {
		let sut = makeSUTInPlayingState()
		sut.send(.didStartBuffering)

		let transition = sut.send(.didFinishBuffering)

		let state = sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendDidFinishBuffering_fromBufferingPaused_transitionsToPaused() {
		let sut = makeSUTInPausedState()
		sut.send(.didStartBuffering)

		let transition = sut.send(.didFinishBuffering)

		let state = sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	func test_sendPause_fromBufferingPlaying_changesBufferingPreviousToPaused() {
		let sut = makeSUTInPlayingState()
		sut.send(.didStartBuffering)

		let transition = sut.send(.pause)

		let state = sut.currentState
		XCTAssertEqual(state, .buffering(previousState: .paused))
		XCTAssertEqual(transition?.to, .buffering(previousState: .paused))
	}

	func test_sendPlay_fromBufferingPaused_changesBufferingPreviousToPlaying() {
		let sut = makeSUTInPausedState()
		sut.send(.didStartBuffering)

		let transition = sut.send(.play)

		let state = sut.currentState
		XCTAssertEqual(state, .buffering(previousState: .playing))
		XCTAssertEqual(transition?.to, .buffering(previousState: .playing))
	}

	func test_sendDidFail_fromBuffering_transitionsToFailed() {
		let sut = makeSUTInPlayingState()
		sut.send(.didStartBuffering)
		let error = PlaybackError.networkError(reason: "Connection lost")

		let transition = sut.send(.didFail(error))

		let state = sut.currentState
		XCTAssertEqual(state, .failed(error))
		XCTAssertEqual(transition?.to, .failed(error))
	}

	func test_sendStop_fromBuffering_transitionsToIdle() {
		let sut = makeSUTInPlayingState()
		sut.send(.didStartBuffering)

		let transition = sut.send(.stop)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	// MARK: - Seeking State Transitions

	func test_sendDidFinishSeeking_fromSeekingPlaying_transitionsToPlaying() {
		let sut = makeSUTInPlayingState()
		sut.send(.seek(to: 30.0))

		let transition = sut.send(.didFinishSeeking)

		let state = sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendDidFinishSeeking_fromSeekingPaused_transitionsToPaused() {
		let sut = makeSUTInPausedState()
		sut.send(.seek(to: 30.0))

		let transition = sut.send(.didFinishSeeking)

		let state = sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	func test_sendPause_fromSeekingPlaying_changesSeekingPreviousToPaused() {
		let sut = makeSUTInPlayingState()
		sut.send(.seek(to: 30.0))

		let transition = sut.send(.pause)

		let state = sut.currentState
		XCTAssertEqual(state, .seeking(to: 30.0, previousState: .paused))
		XCTAssertEqual(transition?.to, .seeking(to: 30.0, previousState: .paused))
	}

	func test_sendPlay_fromSeekingPaused_changesSeekingPreviousToPlaying() {
		let sut = makeSUTInPausedState()
		sut.send(.seek(to: 30.0))

		let transition = sut.send(.play)

		let state = sut.currentState
		XCTAssertEqual(state, .seeking(to: 30.0, previousState: .playing))
		XCTAssertEqual(transition?.to, .seeking(to: 30.0, previousState: .playing))
	}

	func test_sendDidFail_fromSeeking_transitionsToFailed() {
		let sut = makeSUTInPlayingState()
		sut.send(.seek(to: 30.0))
		let error = PlaybackError.decodingError(reason: "Seek failed")

		let transition = sut.send(.didFail(error))

		let state = sut.currentState
		XCTAssertEqual(state, .failed(error))
		XCTAssertEqual(transition?.to, .failed(error))
	}

	func test_sendStop_fromSeeking_transitionsToIdle() {
		let sut = makeSUTInPlayingState()
		sut.send(.seek(to: 30.0))

		let transition = sut.send(.stop)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	// MARK: - Ended State Transitions

	func test_sendPlay_fromEnded_transitionsToPlaying() {
		let sut = makeSUTInEndedState()

		let transition = sut.send(.play)

		let state = sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendSeek_fromEnded_transitionsToSeeking() {
		let sut = makeSUTInEndedState()

		let transition = sut.send(.seek(to: 0.0))

		let state = sut.currentState
		XCTAssertEqual(state, .seeking(to: 0.0, previousState: .paused))
		XCTAssertEqual(transition?.to, .seeking(to: 0.0, previousState: .paused))
	}

	func test_sendStop_fromEnded_transitionsToIdle() {
		let sut = makeSUTInEndedState()

		let transition = sut.send(.stop)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendLoad_fromEnded_transitionsToLoading() {
		let sut = makeSUTInEndedState()
		let newURL = URL(string: "https://example.com/video2.mp4")!

		let transition = sut.send(.load(newURL))

		let state = sut.currentState
		XCTAssertEqual(state, .loading(newURL))
		XCTAssertEqual(transition?.to, .loading(newURL))
	}

	// MARK: - Failed State Transitions

	func test_sendRetry_fromFailedWithRecoverableError_transitionsToIdle() {
		let sut = makeSUTInFailedState(with: .networkError(reason: "Timeout"))

		let transition = sut.send(.retry)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendRetry_fromFailedWithNonRecoverableError_isRejected() {
		let sut = makeSUTInFailedState(with: .drmError(reason: "License invalid"))

		let transition = sut.send(.retry)

		let state = sut.currentState
		XCTAssertEqual(state, .failed(.drmError(reason: "License invalid")))
		XCTAssertNil(transition)
	}

	func test_sendStop_fromFailed_transitionsToIdle() {
		let sut = makeSUTInFailedState(with: .networkError(reason: "Timeout"))

		let transition = sut.send(.stop)

		let state = sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendLoad_fromFailed_transitionsToLoading() {
		let sut = makeSUTInFailedState(with: .networkError(reason: "Timeout"))
		let newURL = URL(string: "https://example.com/video2.mp4")!

		let transition = sut.send(.load(newURL))

		let state = sut.currentState
		XCTAssertEqual(state, .loading(newURL))
		XCTAssertEqual(transition?.to, .loading(newURL))
	}

	// MARK: - Audio Session Events

	func test_sendAudioSessionInterrupted_fromPlaying_transitionsToPaused() {
		let sut = makeSUTInPlayingState()

		let transition = sut.send(.audioSessionInterrupted)

		let state = sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	func test_sendAudioSessionInterrupted_fromPaused_isRejected() {
		let sut = makeSUTInPausedState()

		let transition = sut.send(.audioSessionInterrupted)

		let state = sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertNil(transition)
	}

	func test_sendAudioSessionResumed_fromPaused_transitionsToPlaying() {
		let sut = makeSUTInPausedState()

		let transition = sut.send(.audioSessionResumed)

		let state = sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	// MARK: - canPerform

	func test_canPerform_returnsTrueForValidTransition() {
		let sut = makeSUT()

		let canLoad = sut.canPerform(.load(anyURL()))

		XCTAssertTrue(canLoad)
	}

	func test_canPerform_returnsFalseForInvalidTransition() {
		let sut = makeSUT()

		let canPlay = sut.canPerform(.play)

		XCTAssertFalse(canPlay)
	}

	// MARK: - Transition Timestamps

	func test_transition_containsCorrectTimestamp() {
		let fixedDate = Date()
		let sut = makeSUT(currentDate: { fixedDate })

		let transition = sut.send(.load(anyURL()))

		XCTAssertEqual(transition?.timestamp, fixedDate)
	}

	// MARK: - Combine Publishers

	func test_statePublisher_emitsInitialState() {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit initial state")
		var receivedStates: [PlaybackState] = []

		sut.statePublisher
			.sink { state in
				receivedStates.append(state)
				if receivedStates.count >= 1 {
					expectation.fulfill()
				}
			}
			.store(in: &cancellables)

		wait(for: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedStates, [.idle])
	}

	func test_statePublisher_emitsStateChanges() {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit state changes")
		var receivedStates: [PlaybackState] = []
		let url = anyURL()

		sut.statePublisher
			.sink { state in
				receivedStates.append(state)
				if receivedStates.count >= 2 {
					expectation.fulfill()
				}
			}
			.store(in: &cancellables)

		sut.send(.load(url))

		wait(for: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedStates, [.idle, .loading(url)])
	}

	func test_transitionPublisher_emitsTransitions() {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit transition")
		var receivedTransitions: [PlaybackTransition] = []
		let url = anyURL()

		sut.transitionPublisher
			.sink { transition in
				receivedTransitions.append(transition)
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(url))

		wait(for: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedTransitions.first?.from, .idle)
		XCTAssertEqual(receivedTransitions.first?.to, .loading(url))
		XCTAssertEqual(receivedTransitions.first?.action, .load(url))
	}

	// MARK: - Helpers

	private func makeSUT(
		currentDate: @escaping @Sendable () -> Date = Date.init,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> DefaultPlaybackStateMachine {
		let sut = DefaultPlaybackStateMachine(currentDate: currentDate)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func makeSUTInReadyState(file: StaticString = #filePath, line: UInt = #line) -> DefaultPlaybackStateMachine {
		let sut = makeSUT(file: file, line: line)
		sut.send(.load(anyURL()))
		sut.send(.didBecomeReady)
		return sut
	}

	private func makeSUTInPlayingState(file: StaticString = #filePath, line: UInt = #line) -> DefaultPlaybackStateMachine {
		let sut = makeSUTInReadyState(file: file, line: line)
		sut.send(.play)
		return sut
	}

	private func makeSUTInPausedState(file: StaticString = #filePath, line: UInt = #line) -> DefaultPlaybackStateMachine {
		let sut = makeSUTInPlayingState(file: file, line: line)
		sut.send(.pause)
		return sut
	}

	private func makeSUTInEndedState(file: StaticString = #filePath, line: UInt = #line) -> DefaultPlaybackStateMachine {
		let sut = makeSUTInPlayingState(file: file, line: line)
		sut.send(.didReachEnd)
		return sut
	}

	private func makeSUTInFailedState(with error: PlaybackError, file: StaticString = #filePath, line: UInt = #line) -> DefaultPlaybackStateMachine {
		let sut = makeSUT(file: file, line: line)
		sut.send(.load(anyURL()))
		sut.send(.didFail(error))
		return sut
	}

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}
