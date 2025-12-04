//
//  StatefulVideoPlayerTests.swift
//  StreamingVideoAppTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
import StreamingCore
@testable import StreamingVideoApp

// Tests re-enabled for nonisolated actor isolation experiment

@MainActor
final class StatefulVideoPlayerTests: XCTestCase {

	private var cancellables = Set<AnyCancellable>()

	override func tearDown() async throws {
		cancellables.removeAll()
		await Task.yield()
		try await super.tearDown()
	}

	// MARK: - Initialization

	func test_init_startsInIdleState() {
		let (sut, _) = makeSUT()

		XCTAssertEqual(sut.currentPlaybackState, .idle)
	}

	func test_init_doesNotPlayVideo() {
		let (sut, _) = makeSUT()

		XCTAssertFalse(sut.isPlaying)
	}

	// MARK: - Load

	func test_load_transitionsToLoadingState() async {
		let (sut, _) = makeSUT()
		let url = anyURL()

		sut.load(url: url)
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(sut.currentPlaybackState, .loading(url))
	}

	func test_load_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		let url = anyURL()

		sut.load(url: url)

		XCTAssertEqual(spy.loadedURLs, [url])
	}

	// MARK: - Play

	func test_play_whenReady_transitionsToPlaying() async {
		let (sut, _) = makeSUT()
		await prepareForPlayback(sut)

		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(sut.currentPlaybackState, .playing)
	}

	func test_play_whenIdle_doesNotTransition() async {
		let (sut, _) = makeSUT()

		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(sut.currentPlaybackState, .idle)
	}

	func test_play_whenReady_forwardsToDecoratee() async {
		let (sut, spy) = makeSUT()
		await prepareForPlayback(sut)

		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(spy.playCallCount, 1)
	}

	// MARK: - Pause

	func test_pause_whenPlaying_transitionsToPaused() async {
		let (sut, _) = makeSUT()
		await prepareForPlayback(sut)
		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		sut.pause()
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(sut.currentPlaybackState, .paused)
	}

	func test_pause_whenNotPlaying_doesNotTransition() async {
		let (sut, _) = makeSUT()
		await prepareForPlayback(sut)

		sut.pause()
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(sut.currentPlaybackState, .ready)
	}

	func test_pause_forwardsToDecoratee() async {
		let (sut, spy) = makeSUT()
		await prepareForPlayback(sut)
		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		sut.pause()
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(spy.pauseCallCount, 1)
	}

	// MARK: - Seek

	func test_seek_fromPlaying_transitionsToSeeking() async {
		let (sut, _) = makeSUT()
		await prepareForPlayback(sut)
		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		sut.seek(to: 30.0)
		try? await Task.sleep(nanoseconds: 50_000_000)

		// After seek completes, should return to playing
		XCTAssertEqual(sut.currentPlaybackState, .playing)
	}

	func test_seek_forwardsToDecoratee() async {
		let (sut, spy) = makeSUT()
		await prepareForPlayback(sut)
		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		sut.seek(to: 30.0)
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(spy.seekTimes, [30.0])
	}

	// MARK: - Stop

	func test_stop_transitionsToIdle() async {
		let (sut, _) = makeSUT()
		await prepareForPlayback(sut)
		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		sut.stop()
		try? await Task.sleep(nanoseconds: 50_000_000)

		XCTAssertEqual(sut.currentPlaybackState, .idle)
	}

	// MARK: - State Publisher

	func test_statePublisher_emitsStateChanges() async {
		let (sut, _) = makeSUT()
		let expectation = expectation(description: "Emit states")
		expectation.expectedFulfillmentCount = 3
		var receivedStates: [PlaybackState] = []

		sut.statePublisher
			.dropFirst() // Skip initial idle
			.sink { state in
				receivedStates.append(state)
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.load(url: anyURL())
		try? await Task.sleep(nanoseconds: 50_000_000)
		sut.simulateDidBecomeReady()
		try? await Task.sleep(nanoseconds: 50_000_000)
		sut.play()
		try? await Task.sleep(nanoseconds: 50_000_000)

		await fulfillment(of: [expectation], timeout: 1.0)
		XCTAssertEqual(receivedStates.count, 3)
	}

	// MARK: - Properties Forwarding

	func test_currentTime_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()
		spy.stubbedCurrentTime = 45.0

		XCTAssertEqual(sut.currentTime, 45.0)
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

	// MARK: - Method Forwarding

	func test_seekForward_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.seekForward(by: 10)

		XCTAssertEqual(spy.seekForwardSeconds, [10])
	}

	func test_seekBackward_forwardsToDecoratee() {
		let (sut, spy) = makeSUT()

		sut.seekBackward(by: 10)

		XCTAssertEqual(spy.seekBackwardSeconds, [10])
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

		sut.setPlaybackSpeed(2.0)

		XCTAssertEqual(spy.setPlaybackSpeedValues, [2.0])
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: StatefulVideoPlayer, spy: VideoPlayerSpy) {
		let spy = VideoPlayerSpy()
		let stateMachine = DefaultPlaybackStateMachine()
		let sut = StatefulVideoPlayer(decoratee: spy, stateMachine: stateMachine)
		// Note: Cannot use trackForMemoryLeaks because StatefulVideoPlayer uses
		// Task.immediate which may still be in flight when teardown runs.
		// The [weak self] pattern ensures no retain cycle exists.
		return (sut, spy)
	}

	private func prepareForPlayback(_ sut: StatefulVideoPlayer) async {
		sut.load(url: anyURL())
		try? await Task.sleep(nanoseconds: 50_000_000)
		sut.simulateDidBecomeReady()
		try? await Task.sleep(nanoseconds: 50_000_000)
	}

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}

// MARK: - Test Doubles

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
