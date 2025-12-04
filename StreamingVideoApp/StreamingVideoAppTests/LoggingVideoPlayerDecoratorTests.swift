//
//  LoggingVideoPlayerDecoratorTests.swift
//  StreamingVideoAppTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore
@testable import StreamingVideoApp

// Tests re-enabled for nonisolated actor isolation experiment

@MainActor
final class LoggingVideoPlayerDecoratorTests: XCTestCase {

	// MARK: - Property Forwarding

	func test_isPlaying_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		spy.stubbedIsPlaying = true

		XCTAssertTrue(sut.isPlaying)
	}

	func test_currentTime_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		spy.stubbedCurrentTime = 42.0

		XCTAssertEqual(sut.currentTime, 42.0)
	}

	func test_duration_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		spy.stubbedDuration = 120.0

		XCTAssertEqual(sut.duration, 120.0)
	}

	func test_volume_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		spy.stubbedVolume = 0.5

		XCTAssertEqual(sut.volume, 0.5)
	}

	func test_isMuted_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		spy.stubbedIsMuted = true

		XCTAssertTrue(sut.isMuted)
	}

	func test_playbackSpeed_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		spy.stubbedPlaybackSpeed = 2.0

		XCTAssertEqual(sut.playbackSpeed, 2.0)
	}

	// MARK: - Method Forwarding

	func test_load_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		let url = anyURL()

		sut.load(url: url)

		XCTAssertEqual(spy.loadedURLs, [url])
	}

	func test_play_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.play()

		XCTAssertEqual(spy.playCallCount, 1)
	}

	func test_pause_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.pause()

		XCTAssertEqual(spy.pauseCallCount, 1)
	}

	func test_seekForward_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.seekForward(by: 10)

		XCTAssertEqual(spy.seekForwardSeconds, [10])
	}

	func test_seekBackward_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.seekBackward(by: 15)

		XCTAssertEqual(spy.seekBackwardSeconds, [15])
	}

	func test_seek_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.seek(to: 30.0)

		XCTAssertEqual(spy.seekTimes, [30.0])
	}

	func test_setVolume_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.setVolume(0.7)

		XCTAssertEqual(spy.setVolumeValues, [0.7])
	}

	func test_toggleMute_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.toggleMute()

		XCTAssertEqual(spy.toggleMuteCallCount, 1)
	}

	func test_setPlaybackSpeed_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.setPlaybackSpeed(1.5)

		XCTAssertEqual(spy.setPlaybackSpeedValues, [1.5])
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: LoggingVideoPlayerDecorator, spy: VideoPlayerSpy) {
		let spy = VideoPlayerSpy()
		let logger = NullLoggerStub()
		let sut = LoggingVideoPlayerDecorator(decoratee: spy, logger: logger)
		return (sut, spy)
	}

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}

// MARK: - Test Helpers

@MainActor
private final class VideoPlayerSpy: VideoPlayer {
	var loadedURLs: [URL] = []
	var playCallCount = 0
	var pauseCallCount = 0
	var seekTimes: [TimeInterval] = []
	var seekForwardSeconds: [TimeInterval] = []
	var seekBackwardSeconds: [TimeInterval] = []
	var setVolumeValues: [Float] = []
	var toggleMuteCallCount = 0
	var setPlaybackSpeedValues: [Float] = []

	var stubbedIsPlaying = false
	var stubbedCurrentTime: TimeInterval = 0
	var stubbedDuration: TimeInterval = 0
	var stubbedVolume: Float = 1.0
	var stubbedIsMuted = false
	var stubbedPlaybackSpeed: Float = 1.0

	var isPlaying: Bool { stubbedIsPlaying }
	var currentTime: TimeInterval { stubbedCurrentTime }
	var duration: TimeInterval { stubbedDuration }
	var volume: Float { stubbedVolume }
	var isMuted: Bool { stubbedIsMuted }
	var playbackSpeed: Float { stubbedPlaybackSpeed }

	func load(url: URL) {
		loadedURLs.append(url)
	}

	func play() {
		playCallCount += 1
		stubbedIsPlaying = true
	}

	func pause() {
		pauseCallCount += 1
		stubbedIsPlaying = false
	}

	func seekForward(by seconds: TimeInterval) {
		seekForwardSeconds.append(seconds)
	}

	func seekBackward(by seconds: TimeInterval) {
		seekBackwardSeconds.append(seconds)
	}

	func seek(to time: TimeInterval) {
		seekTimes.append(time)
	}

	func setVolume(_ volume: Float) {
		setVolumeValues.append(volume)
	}

	func toggleMute() {
		toggleMuteCallCount += 1
	}

	func setPlaybackSpeed(_ speed: Float) {
		setPlaybackSpeedValues.append(speed)
	}
}

/// Simple null logger for forwarding tests - does nothing
/// Following Essential Feed pattern - @MainActor class with sync log
@MainActor
final class NullLoggerStub: Logger {
	nonisolated let minimumLevel: LogLevel = .debug
	nonisolated func log(_ entry: LogEntry) {}
}
