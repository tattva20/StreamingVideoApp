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

	func test_init_startsInIdleState() async {
		let sut = makeSUT()

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
	}

	// MARK: - Idle State Transitions

	func test_sendLoad_fromIdle_transitionsToLoading() async {
		let sut = makeSUT()
		let url = anyURL()

		let transition = await sut.send(.load(url))

		let state = await sut.currentState
		XCTAssertEqual(state, .loading(url))
		XCTAssertEqual(transition?.to, .loading(url))
	}

	func test_sendPlay_fromIdle_isRejected() async {
		let sut = makeSUT()

		let transition = await sut.send(.play)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertNil(transition)
	}

	// MARK: - Loading State Transitions

	func test_sendDidBecomeReady_fromLoading_transitionsToReady() async {
		let sut = makeSUT()
		await sut.send(.load(anyURL()))

		let transition = await sut.send(.didBecomeReady)

		let state = await sut.currentState
		XCTAssertEqual(state, .ready)
		XCTAssertEqual(transition?.to, .ready)
	}

	func test_sendDidFail_fromLoading_transitionsToFailed() async {
		let sut = makeSUT()
		await sut.send(.load(anyURL()))
		let error = PlaybackError.networkError(reason: "Timeout")

		let transition = await sut.send(.didFail(error))

		let state = await sut.currentState
		XCTAssertEqual(state, .failed(error))
		XCTAssertEqual(transition?.to, .failed(error))
	}

	func test_sendStop_fromLoading_transitionsToIdle() async {
		let sut = makeSUT()
		await sut.send(.load(anyURL()))

		let transition = await sut.send(.stop)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	// MARK: - Ready State Transitions

	func test_sendPlay_fromReady_transitionsToPlaying() async {
		let sut = await makeSUTInReadyState()

		let transition = await sut.send(.play)

		let state = await sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendStop_fromReady_transitionsToIdle() async {
		let sut = await makeSUTInReadyState()

		let transition = await sut.send(.stop)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendLoad_fromReady_transitionsToLoading() async {
		let sut = await makeSUTInReadyState()
		let newURL = URL(string: "https://example.com/video2.mp4")!

		let transition = await sut.send(.load(newURL))

		let state = await sut.currentState
		XCTAssertEqual(state, .loading(newURL))
		XCTAssertEqual(transition?.to, .loading(newURL))
	}

	// MARK: - Playing State Transitions

	func test_sendPause_fromPlaying_transitionsToPaused() async {
		let sut = await makeSUTInPlayingState()

		let transition = await sut.send(.pause)

		let state = await sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	func test_sendDidStartBuffering_fromPlaying_transitionsToBuffering() async {
		let sut = await makeSUTInPlayingState()

		let transition = await sut.send(.didStartBuffering)

		let state = await sut.currentState
		XCTAssertEqual(state, .buffering(previousState: .playing))
		XCTAssertEqual(transition?.to, .buffering(previousState: .playing))
	}

	func test_sendSeek_fromPlaying_transitionsToSeeking() async {
		let sut = await makeSUTInPlayingState()

		let transition = await sut.send(.seek(to: 30.0))

		let state = await sut.currentState
		XCTAssertEqual(state, .seeking(to: 30.0, previousState: .playing))
		XCTAssertEqual(transition?.to, .seeking(to: 30.0, previousState: .playing))
	}

	func test_sendDidReachEnd_fromPlaying_transitionsToEnded() async {
		let sut = await makeSUTInPlayingState()

		let transition = await sut.send(.didReachEnd)

		let state = await sut.currentState
		XCTAssertEqual(state, .ended)
		XCTAssertEqual(transition?.to, .ended)
	}

	func test_sendDidFail_fromPlaying_transitionsToFailed() async {
		let sut = await makeSUTInPlayingState()
		let error = PlaybackError.networkError(reason: "Lost connection")

		let transition = await sut.send(.didFail(error))

		let state = await sut.currentState
		XCTAssertEqual(state, .failed(error))
		XCTAssertEqual(transition?.to, .failed(error))
	}

	func test_sendStop_fromPlaying_transitionsToIdle() async {
		let sut = await makeSUTInPlayingState()

		let transition = await sut.send(.stop)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendDidEnterBackground_fromPlaying_transitionsToPaused() async {
		let sut = await makeSUTInPlayingState()

		let transition = await sut.send(.didEnterBackground)

		let state = await sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	// MARK: - Paused State Transitions

	func test_sendPlay_fromPaused_transitionsToPlaying() async {
		let sut = await makeSUTInPausedState()

		let transition = await sut.send(.play)

		let state = await sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendDidStartBuffering_fromPaused_transitionsToBufferingWithPausedPrevious() async {
		let sut = await makeSUTInPausedState()

		let transition = await sut.send(.didStartBuffering)

		let state = await sut.currentState
		XCTAssertEqual(state, .buffering(previousState: .paused))
		XCTAssertEqual(transition?.to, .buffering(previousState: .paused))
	}

	func test_sendSeek_fromPaused_transitionsToSeekingWithPausedPrevious() async {
		let sut = await makeSUTInPausedState()

		let transition = await sut.send(.seek(to: 15.0))

		let state = await sut.currentState
		XCTAssertEqual(state, .seeking(to: 15.0, previousState: .paused))
		XCTAssertEqual(transition?.to, .seeking(to: 15.0, previousState: .paused))
	}

	func test_sendStop_fromPaused_transitionsToIdle() async {
		let sut = await makeSUTInPausedState()

		let transition = await sut.send(.stop)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendLoad_fromPaused_transitionsToLoading() async {
		let sut = await makeSUTInPausedState()
		let newURL = URL(string: "https://example.com/video2.mp4")!

		let transition = await sut.send(.load(newURL))

		let state = await sut.currentState
		XCTAssertEqual(state, .loading(newURL))
		XCTAssertEqual(transition?.to, .loading(newURL))
	}

	// MARK: - Buffering State Transitions

	func test_sendDidFinishBuffering_fromBufferingPlaying_transitionsToPlaying() async {
		let sut = await makeSUTInPlayingState()
		await sut.send(.didStartBuffering)

		let transition = await sut.send(.didFinishBuffering)

		let state = await sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendDidFinishBuffering_fromBufferingPaused_transitionsToPaused() async {
		let sut = await makeSUTInPausedState()
		await sut.send(.didStartBuffering)

		let transition = await sut.send(.didFinishBuffering)

		let state = await sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	func test_sendPause_fromBufferingPlaying_changesBufferingPreviousToPaused() async {
		let sut = await makeSUTInPlayingState()
		await sut.send(.didStartBuffering)

		let transition = await sut.send(.pause)

		let state = await sut.currentState
		XCTAssertEqual(state, .buffering(previousState: .paused))
		XCTAssertEqual(transition?.to, .buffering(previousState: .paused))
	}

	func test_sendPlay_fromBufferingPaused_changesBufferingPreviousToPlaying() async {
		let sut = await makeSUTInPausedState()
		await sut.send(.didStartBuffering)

		let transition = await sut.send(.play)

		let state = await sut.currentState
		XCTAssertEqual(state, .buffering(previousState: .playing))
		XCTAssertEqual(transition?.to, .buffering(previousState: .playing))
	}

	func test_sendDidFail_fromBuffering_transitionsToFailed() async {
		let sut = await makeSUTInPlayingState()
		await sut.send(.didStartBuffering)
		let error = PlaybackError.networkError(reason: "Connection lost")

		let transition = await sut.send(.didFail(error))

		let state = await sut.currentState
		XCTAssertEqual(state, .failed(error))
		XCTAssertEqual(transition?.to, .failed(error))
	}

	func test_sendStop_fromBuffering_transitionsToIdle() async {
		let sut = await makeSUTInPlayingState()
		await sut.send(.didStartBuffering)

		let transition = await sut.send(.stop)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	// MARK: - Seeking State Transitions

	func test_sendDidFinishSeeking_fromSeekingPlaying_transitionsToPlaying() async {
		let sut = await makeSUTInPlayingState()
		await sut.send(.seek(to: 30.0))

		let transition = await sut.send(.didFinishSeeking)

		let state = await sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendDidFinishSeeking_fromSeekingPaused_transitionsToPaused() async {
		let sut = await makeSUTInPausedState()
		await sut.send(.seek(to: 30.0))

		let transition = await sut.send(.didFinishSeeking)

		let state = await sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	func test_sendPause_fromSeekingPlaying_changesSeekingPreviousToPaused() async {
		let sut = await makeSUTInPlayingState()
		await sut.send(.seek(to: 30.0))

		let transition = await sut.send(.pause)

		let state = await sut.currentState
		XCTAssertEqual(state, .seeking(to: 30.0, previousState: .paused))
		XCTAssertEqual(transition?.to, .seeking(to: 30.0, previousState: .paused))
	}

	func test_sendPlay_fromSeekingPaused_changesSeekingPreviousToPlaying() async {
		let sut = await makeSUTInPausedState()
		await sut.send(.seek(to: 30.0))

		let transition = await sut.send(.play)

		let state = await sut.currentState
		XCTAssertEqual(state, .seeking(to: 30.0, previousState: .playing))
		XCTAssertEqual(transition?.to, .seeking(to: 30.0, previousState: .playing))
	}

	func test_sendDidFail_fromSeeking_transitionsToFailed() async {
		let sut = await makeSUTInPlayingState()
		await sut.send(.seek(to: 30.0))
		let error = PlaybackError.decodingError(reason: "Seek failed")

		let transition = await sut.send(.didFail(error))

		let state = await sut.currentState
		XCTAssertEqual(state, .failed(error))
		XCTAssertEqual(transition?.to, .failed(error))
	}

	func test_sendStop_fromSeeking_transitionsToIdle() async {
		let sut = await makeSUTInPlayingState()
		await sut.send(.seek(to: 30.0))

		let transition = await sut.send(.stop)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	// MARK: - Ended State Transitions

	func test_sendPlay_fromEnded_transitionsToPlaying() async {
		let sut = await makeSUTInEndedState()

		let transition = await sut.send(.play)

		let state = await sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	func test_sendSeek_fromEnded_transitionsToSeeking() async {
		let sut = await makeSUTInEndedState()

		let transition = await sut.send(.seek(to: 0.0))

		let state = await sut.currentState
		XCTAssertEqual(state, .seeking(to: 0.0, previousState: .paused))
		XCTAssertEqual(transition?.to, .seeking(to: 0.0, previousState: .paused))
	}

	func test_sendStop_fromEnded_transitionsToIdle() async {
		let sut = await makeSUTInEndedState()

		let transition = await sut.send(.stop)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendLoad_fromEnded_transitionsToLoading() async {
		let sut = await makeSUTInEndedState()
		let newURL = URL(string: "https://example.com/video2.mp4")!

		let transition = await sut.send(.load(newURL))

		let state = await sut.currentState
		XCTAssertEqual(state, .loading(newURL))
		XCTAssertEqual(transition?.to, .loading(newURL))
	}

	// MARK: - Failed State Transitions

	func test_sendRetry_fromFailedWithRecoverableError_transitionsToIdle() async {
		let sut = await makeSUTInFailedState(with: .networkError(reason: "Timeout"))

		let transition = await sut.send(.retry)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendRetry_fromFailedWithNonRecoverableError_isRejected() async {
		let sut = await makeSUTInFailedState(with: .drmError(reason: "License invalid"))

		let transition = await sut.send(.retry)

		let state = await sut.currentState
		XCTAssertEqual(state, .failed(.drmError(reason: "License invalid")))
		XCTAssertNil(transition)
	}

	func test_sendStop_fromFailed_transitionsToIdle() async {
		let sut = await makeSUTInFailedState(with: .networkError(reason: "Timeout"))

		let transition = await sut.send(.stop)

		let state = await sut.currentState
		XCTAssertEqual(state, .idle)
		XCTAssertEqual(transition?.to, .idle)
	}

	func test_sendLoad_fromFailed_transitionsToLoading() async {
		let sut = await makeSUTInFailedState(with: .networkError(reason: "Timeout"))
		let newURL = URL(string: "https://example.com/video2.mp4")!

		let transition = await sut.send(.load(newURL))

		let state = await sut.currentState
		XCTAssertEqual(state, .loading(newURL))
		XCTAssertEqual(transition?.to, .loading(newURL))
	}

	// MARK: - Audio Session Events

	func test_sendAudioSessionInterrupted_fromPlaying_transitionsToPaused() async {
		let sut = await makeSUTInPlayingState()

		let transition = await sut.send(.audioSessionInterrupted)

		let state = await sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertEqual(transition?.to, .paused)
	}

	func test_sendAudioSessionInterrupted_fromPaused_isRejected() async {
		let sut = await makeSUTInPausedState()

		let transition = await sut.send(.audioSessionInterrupted)

		let state = await sut.currentState
		XCTAssertEqual(state, .paused)
		XCTAssertNil(transition)
	}

	func test_sendAudioSessionResumed_fromPaused_transitionsToPlaying() async {
		let sut = await makeSUTInPausedState()

		let transition = await sut.send(.audioSessionResumed)

		let state = await sut.currentState
		XCTAssertEqual(state, .playing)
		XCTAssertEqual(transition?.to, .playing)
	}

	// MARK: - canPerform

	func test_canPerform_returnsTrueForValidTransition() async {
		let sut = makeSUT()

		let canLoad = await sut.canPerform(.load(anyURL()))

		XCTAssertTrue(canLoad)
	}

	func test_canPerform_returnsFalseForInvalidTransition() async {
		let sut = makeSUT()

		let canPlay = await sut.canPerform(.play)

		XCTAssertFalse(canPlay)
	}

	// MARK: - Transition Timestamps

	func test_transition_containsCorrectTimestamp() async {
		let fixedDate = Date()
		let sut = makeSUT(currentDate: { fixedDate })

		let transition = await sut.send(.load(anyURL()))

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

	func test_statePublisher_emitsStateChanges() async {
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

		await sut.send(.load(url))

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedStates, [.idle, .loading(url)])
	}

	func test_transitionPublisher_emitsTransitions() async {
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

		await sut.send(.load(url))

		await fulfillment(of: [expectation], timeout: 1.0)
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

	private func makeSUTInReadyState(file: StaticString = #filePath, line: UInt = #line) async -> DefaultPlaybackStateMachine {
		let sut = makeSUT(file: file, line: line)
		await sut.send(.load(anyURL()))
		await sut.send(.didBecomeReady)
		return sut
	}

	private func makeSUTInPlayingState(file: StaticString = #filePath, line: UInt = #line) async -> DefaultPlaybackStateMachine {
		let sut = await makeSUTInReadyState(file: file, line: line)
		await sut.send(.play)
		return sut
	}

	private func makeSUTInPausedState(file: StaticString = #filePath, line: UInt = #line) async -> DefaultPlaybackStateMachine {
		let sut = await makeSUTInPlayingState(file: file, line: line)
		await sut.send(.pause)
		return sut
	}

	private func makeSUTInEndedState(file: StaticString = #filePath, line: UInt = #line) async -> DefaultPlaybackStateMachine {
		let sut = await makeSUTInPlayingState(file: file, line: line)
		await sut.send(.didReachEnd)
		return sut
	}

	private func makeSUTInFailedState(with error: PlaybackError, file: StaticString = #filePath, line: UInt = #line) async -> DefaultPlaybackStateMachine {
		let sut = makeSUT(file: file, line: line)
		await sut.send(.load(anyURL()))
		await sut.send(.didFail(error))
		return sut
	}

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}
