//
//  PlaybackStateObserverTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
@testable import StreamingCore

@MainActor
final class PlaybackStateObserverTests: XCTestCase {

	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		cancellables.removeAll()
		super.tearDown()
	}

	// MARK: - Filtered State Observation

	func test_observePlayingState_emitsOnlyWhenPlaying() async {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit playing state")
		var receivedStates: [PlaybackState] = []

		sut.statePublisher
			.filter { $0 == .playing }
			.sink { state in
				receivedStates.append(state)
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(anyURL()))
		sut.send(.didBecomeReady)
		sut.send(.play)

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedStates, [.playing])
	}

	func test_observePausedState_emitsOnlyWhenPaused() async {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit paused state")
		var receivedStates: [PlaybackState] = []

		sut.statePublisher
			.filter { $0 == .paused }
			.sink { state in
				receivedStates.append(state)
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(anyURL()))
		sut.send(.didBecomeReady)
		sut.send(.play)
		sut.send(.pause)

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedStates, [.paused])
	}

	// MARK: - Active State Detection

	func test_observeActivePlayback_emitsWhenPlayingOrBufferingFromPlaying() async {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit active states")
		expectation.expectedFulfillmentCount = 2
		var activeCount = 0

		sut.statePublisher
			.filter { $0.isActive }
			.sink { _ in
				activeCount += 1
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(anyURL()))
		sut.send(.didBecomeReady)
		sut.send(.play) // active
		sut.send(.didStartBuffering) // active (buffering from playing)

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(activeCount, 2)
	}

	// MARK: - Failure Observation

	func test_observeFailures_emitsOnlyErrorStates() async {
		let sut = makeSUT()
		let error = PlaybackError.networkError(reason: "Timeout")
		let expectation = expectation(description: "Emit failure")
		var receivedErrors: [PlaybackError] = []

		sut.statePublisher
			.compactMap { state -> PlaybackError? in
				if case .failed(let err) = state { return err }
				return nil
			}
			.sink { err in
				receivedErrors.append(err)
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(anyURL()))
		sut.send(.didFail(error))

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedErrors, [error])
	}

	// MARK: - Transition Filtering

	func test_filterTransitions_toPlayingFromNonPlaying() async {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit play start transition")
		var receivedTransitions: [PlaybackTransition] = []

		sut.transitionPublisher
			.filter { $0.to == .playing && $0.from != .playing }
			.sink { transition in
				receivedTransitions.append(transition)
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(anyURL()))
		sut.send(.didBecomeReady)
		sut.send(.play)

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedTransitions.count, 1)
		XCTAssertEqual(receivedTransitions.first?.from, .ready)
		XCTAssertEqual(receivedTransitions.first?.to, .playing)
	}

	// MARK: - Buffering Events

	func test_observeBufferingStarted_filtersBufferingTransitions() async {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit buffering start")
		var bufferingStartedCount = 0

		sut.transitionPublisher
			.filter { transition in
				if case .buffering = transition.to { return true }
				return false
			}
			.sink { _ in
				bufferingStartedCount += 1
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(anyURL()))
		sut.send(.didBecomeReady)
		sut.send(.play)
		sut.send(.didStartBuffering)

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(bufferingStartedCount, 1)
	}

	// MARK: - End State Detection

	func test_observeEndState_emitsOnVideoComplete() async {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit ended state")

		sut.statePublisher
			.filter { $0 == .ended }
			.sink { _ in
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(anyURL()))
		sut.send(.didBecomeReady)
		sut.send(.play)
		sut.send(.didReachEnd)

		await fulfillment(of: [expectation], timeout: 1.0)
	}

	// MARK: - State Change Detection

	func test_observeOnlyStateChanges_ignoresNoOpTransitions() async {
		let sut = makeSUT()
		let expectation = expectation(description: "Emit state changes")
		expectation.expectedFulfillmentCount = 4
		var stateChangeCount = 0

		sut.transitionPublisher
			.filter { $0.didChangeState }
			.sink { _ in
				stateChangeCount += 1
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.send(.load(anyURL())) // idle -> loading
		sut.send(.didBecomeReady) // loading -> ready
		sut.send(.play) // ready -> playing
		sut.send(.pause) // playing -> paused

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(stateChangeCount, 4)
	}

	// MARK: - Helpers

	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> DefaultPlaybackStateMachine {
		let sut = DefaultPlaybackStateMachine()
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}
