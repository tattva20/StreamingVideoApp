//
//  AdjacentVideoPreloadStrategyTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class AdjacentVideoPreloadStrategyTests: XCTestCase {

	// MARK: - Empty Playlist

	func test_videosToPreload_returnsEmpty_forEmptyPlaylist() {
		let sut = makeSUT()

		let result = sut.videosToPreload(
			currentVideoIndex: 0,
			playlist: [],
			networkQuality: .excellent
		)

		XCTAssertTrue(result.isEmpty)
	}

	// MARK: - Single Video Playlist

	func test_videosToPreload_returnsEmpty_forSingleVideoPlaylist() {
		let sut = makeSUT()
		let playlist = [makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: 0,
			playlist: playlist,
			networkQuality: .excellent
		)

		XCTAssertTrue(result.isEmpty)
	}

	// MARK: - Next Video Preloading

	func test_videosToPreload_returnsNextVideo_whenAvailable() {
		let sut = makeSUT()
		let videos = [makeVideo(), makeVideo(), makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: 0,
			playlist: videos,
			networkQuality: .good
		)

		XCTAssertTrue(result.contains(videos[1]))
	}

	func test_videosToPreload_returnsEmpty_whenAtLastVideo() {
		let sut = makeSUT()
		let videos = [makeVideo(), makeVideo(), makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: 2,
			playlist: videos,
			networkQuality: .excellent
		)

		XCTAssertTrue(result.isEmpty)
	}

	// MARK: - Network Quality Impact

	func test_videosToPreload_returnsEmpty_forOfflineNetwork() {
		let sut = makeSUT()
		let videos = [makeVideo(), makeVideo(), makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: 0,
			playlist: videos,
			networkQuality: .offline
		)

		XCTAssertTrue(result.isEmpty)
	}

	func test_videosToPreload_returnsOneVideo_forPoorNetwork() {
		let sut = makeSUT()
		let videos = [makeVideo(), makeVideo(), makeVideo(), makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: 0,
			playlist: videos,
			networkQuality: .poor
		)

		XCTAssertEqual(result.count, 1)
	}

	func test_videosToPreload_returnsTwoVideos_forExcellentNetwork() {
		let sut = makeSUT()
		let videos = [makeVideo(), makeVideo(), makeVideo(), makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: 0,
			playlist: videos,
			networkQuality: .excellent
		)

		XCTAssertEqual(result.count, 2)
		XCTAssertEqual(result[0], videos[1])
		XCTAssertEqual(result[1], videos[2])
	}

	func test_videosToPreload_limitsToAvailableVideos() {
		let sut = makeSUT()
		let videos = [makeVideo(), makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: 0,
			playlist: videos,
			networkQuality: .excellent
		)

		// Only one video available after current
		XCTAssertEqual(result.count, 1)
	}

	// MARK: - Out of Bounds

	func test_videosToPreload_returnsEmpty_forInvalidIndex() {
		let sut = makeSUT()
		let videos = [makeVideo(), makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: 10,
			playlist: videos,
			networkQuality: .excellent
		)

		XCTAssertTrue(result.isEmpty)
	}

	func test_videosToPreload_returnsEmpty_forNegativeIndex() {
		let sut = makeSUT()
		let videos = [makeVideo(), makeVideo()]

		let result = sut.videosToPreload(
			currentVideoIndex: -1,
			playlist: videos,
			networkQuality: .excellent
		)

		XCTAssertTrue(result.isEmpty)
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> AdjacentVideoPreloadStrategy {
		let sut = AdjacentVideoPreloadStrategy()
		return sut
	}

	private func makeVideo() -> PreloadableVideo {
		PreloadableVideo(
			id: UUID(),
			url: URL(string: "https://example.com/\(UUID()).mp4")!,
			estimatedDuration: 120
		)
	}
}
