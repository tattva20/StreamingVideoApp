//
//  PlaybackStateTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PlaybackStateTests: XCTestCase {

	// MARK: - Equality

	func test_equality_idleStatesAreEqual() {
		XCTAssertEqual(PlaybackState.idle, PlaybackState.idle)
	}

	func test_equality_loadingStatesWithSameURLAreEqual() {
		let url = anyURL()
		XCTAssertEqual(PlaybackState.loading(url), PlaybackState.loading(url))
	}

	func test_equality_loadingStatesWithDifferentURLsAreNotEqual() {
		let url1 = URL(string: "https://example.com/video1.mp4")!
		let url2 = URL(string: "https://example.com/video2.mp4")!
		XCTAssertNotEqual(PlaybackState.loading(url1), PlaybackState.loading(url2))
	}

	func test_equality_readyStatesAreEqual() {
		XCTAssertEqual(PlaybackState.ready, PlaybackState.ready)
	}

	func test_equality_playingStatesAreEqual() {
		XCTAssertEqual(PlaybackState.playing, PlaybackState.playing)
	}

	func test_equality_pausedStatesAreEqual() {
		XCTAssertEqual(PlaybackState.paused, PlaybackState.paused)
	}

	func test_equality_bufferingWithSamePreviousStateAreEqual() {
		XCTAssertEqual(
			PlaybackState.buffering(previousState: .playing),
			PlaybackState.buffering(previousState: .playing)
		)
	}

	func test_equality_bufferingWithDifferentPreviousStatesAreNotEqual() {
		XCTAssertNotEqual(
			PlaybackState.buffering(previousState: .playing),
			PlaybackState.buffering(previousState: .paused)
		)
	}

	func test_equality_seekingWithSameParametersAreEqual() {
		XCTAssertEqual(
			PlaybackState.seeking(to: 10.0, previousState: .playing),
			PlaybackState.seeking(to: 10.0, previousState: .playing)
		)
	}

	func test_equality_seekingWithDifferentTimesAreNotEqual() {
		XCTAssertNotEqual(
			PlaybackState.seeking(to: 10.0, previousState: .playing),
			PlaybackState.seeking(to: 20.0, previousState: .playing)
		)
	}

	func test_equality_endedStatesAreEqual() {
		XCTAssertEqual(PlaybackState.ended, PlaybackState.ended)
	}

	func test_equality_failedStatesWithSameErrorAreEqual() {
		let error = PlaybackError.networkError(reason: "Timeout")
		XCTAssertEqual(PlaybackState.failed(error), PlaybackState.failed(error))
	}

	func test_equality_differentStatesAreNotEqual() {
		XCTAssertNotEqual(PlaybackState.idle, PlaybackState.ready)
		XCTAssertNotEqual(PlaybackState.playing, PlaybackState.paused)
		XCTAssertNotEqual(PlaybackState.ready, PlaybackState.ended)
	}

	// MARK: - isActive

	func test_isActive_returnsTrueForPlaying() {
		XCTAssertTrue(PlaybackState.playing.isActive)
	}

	func test_isActive_returnsTrueForBufferingFromPlaying() {
		XCTAssertTrue(PlaybackState.buffering(previousState: .playing).isActive)
	}

	func test_isActive_returnsTrueForSeekingFromPlaying() {
		XCTAssertTrue(PlaybackState.seeking(to: 10.0, previousState: .playing).isActive)
	}

	func test_isActive_returnsFalseForIdle() {
		XCTAssertFalse(PlaybackState.idle.isActive)
	}

	func test_isActive_returnsFalseForPaused() {
		XCTAssertFalse(PlaybackState.paused.isActive)
	}

	func test_isActive_returnsFalseForBufferingFromPaused() {
		XCTAssertFalse(PlaybackState.buffering(previousState: .paused).isActive)
	}

	func test_isActive_returnsFalseForLoading() {
		XCTAssertFalse(PlaybackState.loading(anyURL()).isActive)
	}

	func test_isActive_returnsFalseForEnded() {
		XCTAssertFalse(PlaybackState.ended.isActive)
	}

	func test_isActive_returnsFalseForFailed() {
		XCTAssertFalse(PlaybackState.failed(.networkError(reason: "Error")).isActive)
	}

	// MARK: - canPlay

	func test_canPlay_returnsTrueForReady() {
		XCTAssertTrue(PlaybackState.ready.canPlay)
	}

	func test_canPlay_returnsTrueForPaused() {
		XCTAssertTrue(PlaybackState.paused.canPlay)
	}

	func test_canPlay_returnsTrueForEnded() {
		XCTAssertTrue(PlaybackState.ended.canPlay)
	}

	func test_canPlay_returnsFalseForIdle() {
		XCTAssertFalse(PlaybackState.idle.canPlay)
	}

	func test_canPlay_returnsFalseForLoading() {
		XCTAssertFalse(PlaybackState.loading(anyURL()).canPlay)
	}

	func test_canPlay_returnsFalseForPlaying() {
		XCTAssertFalse(PlaybackState.playing.canPlay)
	}

	func test_canPlay_returnsFalseForBuffering() {
		XCTAssertFalse(PlaybackState.buffering(previousState: .playing).canPlay)
	}

	func test_canPlay_returnsFalseForFailed() {
		XCTAssertFalse(PlaybackState.failed(.networkError(reason: "Error")).canPlay)
	}

	// MARK: - canPause

	func test_canPause_returnsTrueForPlaying() {
		XCTAssertTrue(PlaybackState.playing.canPause)
	}

	func test_canPause_returnsTrueForBufferingFromPlaying() {
		XCTAssertTrue(PlaybackState.buffering(previousState: .playing).canPause)
	}

	func test_canPause_returnsFalseForIdle() {
		XCTAssertFalse(PlaybackState.idle.canPause)
	}

	func test_canPause_returnsFalseForPaused() {
		XCTAssertFalse(PlaybackState.paused.canPause)
	}

	func test_canPause_returnsFalseForReady() {
		XCTAssertFalse(PlaybackState.ready.canPause)
	}

	func test_canPause_returnsFalseForBufferingFromPaused() {
		XCTAssertFalse(PlaybackState.buffering(previousState: .paused).canPause)
	}

	// MARK: - Description

	func test_description_returnsExpectedStrings() {
		XCTAssertEqual(PlaybackState.idle.description, "idle")
		XCTAssertEqual(PlaybackState.loading(anyURL()).description, "loading")
		XCTAssertEqual(PlaybackState.ready.description, "ready")
		XCTAssertEqual(PlaybackState.playing.description, "playing")
		XCTAssertEqual(PlaybackState.paused.description, "paused")
		XCTAssertEqual(PlaybackState.buffering(previousState: .playing).description, "buffering")
		XCTAssertEqual(PlaybackState.seeking(to: 10, previousState: .playing).description, "seeking")
		XCTAssertEqual(PlaybackState.ended.description, "ended")
		XCTAssertEqual(PlaybackState.failed(.networkError(reason: "Error")).description, "failed")
	}

	// MARK: - Helpers

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}
