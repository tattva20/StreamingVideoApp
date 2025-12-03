//
//  PlaybackTransitionTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PlaybackTransitionTests: XCTestCase {

	// MARK: - Initialization

	func test_init_storesFromState() {
		let transition = makeSUT(from: .idle, to: .playing, action: .play)

		XCTAssertEqual(transition.from, .idle)
	}

	func test_init_storesToState() {
		let transition = makeSUT(from: .idle, to: .playing, action: .play)

		XCTAssertEqual(transition.to, .playing)
	}

	func test_init_storesAction() {
		let action = PlaybackAction.play
		let transition = makeSUT(from: .idle, to: .playing, action: action)

		XCTAssertEqual(transition.action, action)
	}

	func test_init_storesTimestamp() {
		let timestamp = Date()
		let transition = makeSUT(from: .idle, to: .playing, action: .play, timestamp: timestamp)

		XCTAssertEqual(transition.timestamp, timestamp)
	}

	func test_init_usesCurrentDateByDefault() {
		let before = Date()
		let transition = PlaybackTransition(from: .idle, to: .playing, action: .play)
		let after = Date()

		XCTAssertTrue(transition.timestamp >= before)
		XCTAssertTrue(transition.timestamp <= after)
	}

	// MARK: - Equality

	func test_equality_sameTransitionsAreEqual() {
		let timestamp = Date()
		let transition1 = makeSUT(from: .idle, to: .playing, action: .play, timestamp: timestamp)
		let transition2 = makeSUT(from: .idle, to: .playing, action: .play, timestamp: timestamp)

		XCTAssertEqual(transition1, transition2)
	}

	func test_equality_differentFromStatesAreNotEqual() {
		let timestamp = Date()
		let transition1 = makeSUT(from: .idle, to: .playing, action: .play, timestamp: timestamp)
		let transition2 = makeSUT(from: .paused, to: .playing, action: .play, timestamp: timestamp)

		XCTAssertNotEqual(transition1, transition2)
	}

	func test_equality_differentToStatesAreNotEqual() {
		let timestamp = Date()
		let transition1 = makeSUT(from: .idle, to: .playing, action: .play, timestamp: timestamp)
		let transition2 = makeSUT(from: .idle, to: .paused, action: .play, timestamp: timestamp)

		XCTAssertNotEqual(transition1, transition2)
	}

	func test_equality_differentActionsAreNotEqual() {
		let timestamp = Date()
		let transition1 = makeSUT(from: .playing, to: .paused, action: .pause, timestamp: timestamp)
		let transition2 = makeSUT(from: .playing, to: .paused, action: .didPause, timestamp: timestamp)

		XCTAssertNotEqual(transition1, transition2)
	}

	func test_equality_differentTimestampsAreNotEqual() {
		let transition1 = makeSUT(from: .idle, to: .playing, action: .play, timestamp: Date())
		let transition2 = makeSUT(from: .idle, to: .playing, action: .play, timestamp: Date().addingTimeInterval(1))

		XCTAssertNotEqual(transition1, transition2)
	}

	// MARK: - didChangeState

	func test_didChangeState_returnsTrueWhenStateChanged() {
		let transition = makeSUT(from: .idle, to: .playing, action: .play)

		XCTAssertTrue(transition.didChangeState)
	}

	func test_didChangeState_returnsFalseWhenStateSame() {
		let transition = makeSUT(from: .playing, to: .playing, action: .play)

		XCTAssertFalse(transition.didChangeState)
	}

	func test_didChangeState_returnsTrueForIdleToLoading() {
		let url = URL(string: "https://example.com/video.mp4")!
		let transition = makeSUT(from: .idle, to: .loading(url), action: .load(url))

		XCTAssertTrue(transition.didChangeState)
	}

	func test_didChangeState_returnsTrueForBufferingToPlaying() {
		let transition = makeSUT(
			from: .buffering(previousState: .playing),
			to: .playing,
			action: .didFinishBuffering
		)

		XCTAssertTrue(transition.didChangeState)
	}

	func test_didChangeState_returnsFalseForBufferingToBuffering() {
		let transition = makeSUT(
			from: .buffering(previousState: .playing),
			to: .buffering(previousState: .playing),
			action: .didStartBuffering
		)

		XCTAssertFalse(transition.didChangeState)
	}

	// MARK: - Sendable Conformance

	func test_canBeSentAcrossConcurrencyBoundary() async {
		let transition = makeSUT(from: .idle, to: .playing, action: .play)

		let result = await Task.detached {
			return transition
		}.value

		XCTAssertEqual(result, transition)
	}

	// MARK: - Complex Transitions

	func test_transitionFromLoadingToFailed() {
		let error = PlaybackError.networkError(reason: "Timeout")
		let url = URL(string: "https://example.com/video.mp4")!
		let transition = makeSUT(from: .loading(url), to: .failed(error), action: .didFail(error))

		XCTAssertEqual(transition.from, .loading(url))
		XCTAssertEqual(transition.to, .failed(error))
		XCTAssertEqual(transition.action, .didFail(error))
		XCTAssertTrue(transition.didChangeState)
	}

	func test_transitionFromPlayingToSeeking() {
		let transition = makeSUT(
			from: .playing,
			to: .seeking(to: 30.0, previousState: .playing),
			action: .seek(to: 30.0)
		)

		XCTAssertTrue(transition.didChangeState)
		if case .seeking(let time, let previous) = transition.to {
			XCTAssertEqual(time, 30.0)
			XCTAssertEqual(previous, .playing)
		} else {
			XCTFail("Expected seeking state")
		}
	}

	// MARK: - Helpers

	private func makeSUT(
		from: PlaybackState,
		to: PlaybackState,
		action: PlaybackAction,
		timestamp: Date = Date()
	) -> PlaybackTransition {
		PlaybackTransition(from: from, to: to, action: action, timestamp: timestamp)
	}
}
