//
//  VideoPlayerUIIntegrationTests.swift
//  StreamingVideoAppTests
//
//  Created by Octavio Rojas on 02/12/25.
//

import XCTest
import StreamingCore
import StreamingCoreiOS
@testable import StreamingVideoApp

@MainActor
class VideoPlayerUIIntegrationTests: XCTestCase {

	func test_videoPlayerView_hasTitle() {
		let video = makeVideo(title: "a title")

		let sut = makeSUT(video: video)

		XCTAssertEqual(sut.title, "a title")
	}

	func test_videoPlayerView_hasPlayerView() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.playerView)
	}

	func test_videoPlayerView_displaysPlaybackControls() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.playButton)
		XCTAssertNotNil(sut.seekForwardButton)
		XCTAssertNotNil(sut.seekBackwardButton)
		XCTAssertNotNil(sut.progressSlider)
		XCTAssertNotNil(sut.currentTimeLabel)
		XCTAssertNotNil(sut.durationLabel)
		XCTAssertNotNil(sut.muteButton)
		XCTAssertNotNil(sut.volumeSlider)
		XCTAssertNotNil(sut.playbackSpeedButton)
		XCTAssertNotNil(sut.fullscreenButton)
	}

	func test_videoPlayerView_controlsAreVisibleInitially() {
		let sut = makeSUT()

		XCTAssertTrue(sut.areControlsVisible)
		XCTAssertEqual(sut.playButton.alpha, 1.0)
	}

	// MARK: - Helpers

	private func makeSUT(
		video: Video = makeVideo(),
		file: StaticString = #filePath,
		line: UInt = #line
	) -> VideoPlayerViewController {
		let sut = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
}

private func makeVideo(
	title: String = "any title",
	url: URL = URL(string: "https://any-url.com/video.mp4")!
) -> Video {
	Video(
		id: UUID(),
		title: title,
		description: "any description",
		url: url,
		thumbnailURL: URL(string: "https://any-thumbnail.com")!,
		duration: 120
	)
}
