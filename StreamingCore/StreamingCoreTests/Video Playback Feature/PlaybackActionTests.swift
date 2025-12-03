//
//  PlaybackActionTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PlaybackActionTests: XCTestCase {

	// MARK: - User-Initiated Actions Equality

	func test_equality_loadActionsWithSameURLAreEqual() {
		let url = anyURL()
		XCTAssertEqual(PlaybackAction.load(url), PlaybackAction.load(url))
	}

	func test_equality_loadActionsWithDifferentURLsAreNotEqual() {
		let url1 = URL(string: "https://example.com/video1.mp4")!
		let url2 = URL(string: "https://example.com/video2.mp4")!
		XCTAssertNotEqual(PlaybackAction.load(url1), PlaybackAction.load(url2))
	}

	func test_equality_playActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.play, PlaybackAction.play)
	}

	func test_equality_pauseActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.pause, PlaybackAction.pause)
	}

	func test_equality_seekActionsWithSameTimeAreEqual() {
		XCTAssertEqual(PlaybackAction.seek(to: 10.0), PlaybackAction.seek(to: 10.0))
	}

	func test_equality_seekActionsWithDifferentTimesAreNotEqual() {
		XCTAssertNotEqual(PlaybackAction.seek(to: 10.0), PlaybackAction.seek(to: 20.0))
	}

	func test_equality_stopActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.stop, PlaybackAction.stop)
	}

	func test_equality_retryActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.retry, PlaybackAction.retry)
	}

	// MARK: - System Events Equality

	func test_equality_didBecomeReadyActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didBecomeReady, PlaybackAction.didBecomeReady)
	}

	func test_equality_didStartPlayingActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didStartPlaying, PlaybackAction.didStartPlaying)
	}

	func test_equality_didPauseActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didPause, PlaybackAction.didPause)
	}

	func test_equality_didStartBufferingActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didStartBuffering, PlaybackAction.didStartBuffering)
	}

	func test_equality_didFinishBufferingActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didFinishBuffering, PlaybackAction.didFinishBuffering)
	}

	func test_equality_didStartSeekingActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didStartSeeking, PlaybackAction.didStartSeeking)
	}

	func test_equality_didFinishSeekingActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didFinishSeeking, PlaybackAction.didFinishSeeking)
	}

	func test_equality_didReachEndActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didReachEnd, PlaybackAction.didReachEnd)
	}

	func test_equality_didFailActionsWithSameErrorAreEqual() {
		let error = PlaybackError.networkError(reason: "Timeout")
		XCTAssertEqual(PlaybackAction.didFail(error), PlaybackAction.didFail(error))
	}

	func test_equality_didFailActionsWithDifferentErrorsAreNotEqual() {
		let error1 = PlaybackError.networkError(reason: "Timeout")
		let error2 = PlaybackError.loadFailed(reason: "Not found")
		XCTAssertNotEqual(PlaybackAction.didFail(error1), PlaybackAction.didFail(error2))
	}

	// MARK: - External Events Equality

	func test_equality_didEnterBackgroundActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didEnterBackground, PlaybackAction.didEnterBackground)
	}

	func test_equality_didBecomeActiveActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.didBecomeActive, PlaybackAction.didBecomeActive)
	}

	func test_equality_audioSessionInterruptedActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.audioSessionInterrupted, PlaybackAction.audioSessionInterrupted)
	}

	func test_equality_audioSessionResumedActionsAreEqual() {
		XCTAssertEqual(PlaybackAction.audioSessionResumed, PlaybackAction.audioSessionResumed)
	}

	// MARK: - Different Action Types Are Not Equal

	func test_equality_differentActionTypesAreNotEqual() {
		XCTAssertNotEqual(PlaybackAction.play, PlaybackAction.pause)
		XCTAssertNotEqual(PlaybackAction.stop, PlaybackAction.retry)
		XCTAssertNotEqual(PlaybackAction.didBecomeReady, PlaybackAction.didReachEnd)
		XCTAssertNotEqual(PlaybackAction.didEnterBackground, PlaybackAction.didBecomeActive)
	}

	// MARK: - Sendable Conformance

	func test_canBeSentAcrossConcurrencyBoundary() async {
		let action = PlaybackAction.play

		let result = await Task.detached {
			return action
		}.value

		XCTAssertEqual(result, action)
	}

	func test_loadActionCanBeSentAcrossConcurrencyBoundary() async {
		let action = PlaybackAction.load(anyURL())

		let result = await Task.detached {
			return action
		}.value

		XCTAssertEqual(result, action)
	}

	// MARK: - Helpers

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}
