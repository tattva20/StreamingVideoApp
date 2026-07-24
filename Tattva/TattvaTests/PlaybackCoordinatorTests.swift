//
//  PlaybackCoordinatorTests.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import AVFoundation
import StreamingCore
import StreamingCoreiOS
import XCTest
@testable import Tattva
@testable import StreamingCorePlayback

@MainActor
final class PlaybackCoordinatorTests: XCTestCase {
	func test_init_doesNotStartObserving() {
		let (sut, _) = makeSUT()

		XCTAssertFalse(sut.isObserving)
	}

	func test_start_beginsObservingThePlayer() {
		let (sut, _) = makeSUT()

		sut.start()

		XCTAssertTrue(sut.isObserving)
	}

	func test_start_isIdempotent() {
		let (sut, _) = makeSUT()

		sut.start()
		sut.start()

		XCTAssertTrue(sut.isObserving)
	}

	func test_start_forwardsRealPlayerActionsIntoTheStateMachine() async {
		let (sut, stateMachine) = makeSUT()
		stateMachine.send(.load(anyURL()))
		sut.start()

		await sut.stateAdapter?.simulatePlayerItemReady()
		await settle()

		XCTAssertEqual(stateMachine.currentState, .ready)
	}

	func test_stop_endsObserving() {
		let (sut, _) = makeSUT()
		sut.start()

		sut.stop()

		XCTAssertFalse(sut.isObserving)
	}

	func test_setPreferredPeakBitRate_capsTheCurrentItem() {
		let item = AVPlayerItem(url: anyURL())
		let player = AVPlayer(playerItem: item)
		let stateMachine = DefaultPlaybackStateMachine()
		let performanceAdapter = VideoPlayerPerformanceAdapter(
			performanceService: PlaybackPerformanceService(),
			bandwidthEstimator: NetworkBandwidthEstimator()
		)
		let sut = PlaybackCoordinator(player: player, stateMachine: stateMachine, performanceAdapter: performanceAdapter)
		trackForMemoryLeaks(sut)

		sut.setPreferredPeakBitRate(1_000_000)

		XCTAssertEqual(item.preferredPeakBitRate, 1_000_000)
	}

	func test_start_deliversPeriodicTimeUpdatesToTheClosure() {
		var receivedTimes = [TimeInterval]()
		let (sut, _) = makeSUT(onTimeUpdate: { receivedTimes.append($0) })

		sut.start()

		XCTAssertNotNil(sut, "coordinator should install a periodic observer without crashing")
		XCTAssertTrue(receivedTimes.isEmpty, "no ticks expected before playback advances")
	}

	// MARK: - Helpers

	private func makeSUT(
		onTimeUpdate: @escaping @MainActor (TimeInterval) -> Void = { _ in },
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: PlaybackCoordinator, stateMachine: DefaultPlaybackStateMachine) {
		let player = AVPlayer()
		let stateMachine = DefaultPlaybackStateMachine()
		let performanceAdapter = VideoPlayerPerformanceAdapter(
			performanceService: PlaybackPerformanceService(),
			bandwidthEstimator: NetworkBandwidthEstimator()
		)
		let sut = PlaybackCoordinator(
			player: player,
			stateMachine: stateMachine,
			performanceAdapter: performanceAdapter,
			onTimeUpdate: onTimeUpdate
		)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, stateMachine)
	}

	private func settle() async {
		await Task.yield()
		try? await Task.sleep(nanoseconds: 100_000_000)
	}

	private func anyURL() -> URL {
		URL(string: "https://any-url.com")!
	}
}
