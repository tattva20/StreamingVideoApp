//
//  VideoPlayerPresenterTests.swift
//  StreamingCoreTests
//
//  Created by Octavio Rojas on 02/12/25.
//

import XCTest
import StreamingCore

class VideoPlayerPresenterTests: XCTestCase {

	func test_map_createsViewModelWithTitle() {
		let video = makeVideo(title: "a title")

		let viewModel = VideoPlayerPresenter.map(video)

		XCTAssertEqual(viewModel.title, "a title")
	}

	func test_map_createsViewModelWithVideoURL() {
		let url = URL(string: "https://any-video-url.com/video.mp4")!
		let video = makeVideo(url: url)

		let viewModel = VideoPlayerPresenter.map(video)

		XCTAssertEqual(viewModel.videoURL, url)
	}

	func test_title_isLocalized() {
		XCTAssertEqual(VideoPlayerPresenter.title, localized("VIDEO_PLAYER_VIEW_TITLE"))
	}

	// MARK: - Helpers

	private func makeVideo(
		title: String = "any title",
		url: URL = URL(string: "https://any-url.com")!
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

	private func localized(_ key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
		let table = "VideoPlayer"
		let bundle = Bundle(for: VideoPlayerPresenter.self)
		let value = bundle.localizedString(forKey: key, value: nil, table: table)
		if value == key {
			XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
		}
		return value
	}
}
