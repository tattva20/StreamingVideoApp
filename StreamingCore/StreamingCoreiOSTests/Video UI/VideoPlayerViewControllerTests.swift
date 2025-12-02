//
//  VideoPlayerViewControllerTests.swift
//  StreamingCoreiOSTests
//
//  Created by Octavio Rojas on 02/12/25.
//

import XCTest
import StreamingCore
import StreamingCoreiOS

class VideoPlayerViewControllerTests: XCTestCase {

	func test_viewDidLoad_setsTitle() {
		let (sut, _) = makeSUT(viewModel: makeViewModel(title: "a title"))

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.title, "a title")
	}

	func test_playButtonTap_startsPlayback() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulatePlayButtonTap()

		XCTAssertEqual(player.playCallCount, 1)
	}

	func test_playButtonTap_togglesPlayPause() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulatePlayButtonTap()
		XCTAssertEqual(player.playCallCount, 1)
		XCTAssertEqual(player.pauseCallCount, 0)

		sut.simulatePlayButtonTap()
		XCTAssertEqual(player.playCallCount, 1)
		XCTAssertEqual(player.pauseCallCount, 1)
	}

	// MARK: - Helpers

	private func makeSUT(
		viewModel: VideoPlayerViewModel? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: VideoPlayerViewController, player: VideoPlayerSpy) {
		let player = VideoPlayerSpy()
		let vm = viewModel ?? makeViewModel()
		let sut = VideoPlayerViewController(viewModel: vm, player: player)
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(player, file: file, line: line)
		return (sut, player)
	}

	private func makeViewModel(
		title: String = "any title",
		videoURL: URL = URL(string: "https://any-url.com")!
	) -> VideoPlayerViewModel {
		VideoPlayerViewModel(title: title, videoURL: videoURL)
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}

	private class VideoPlayerSpy: VideoPlayer {
		private(set) var playCallCount = 0
		private(set) var pauseCallCount = 0
		private(set) var loadedURLs = [URL]()

		var isPlaying: Bool = false

		func load(url: URL) {
			loadedURLs.append(url)
		}

		func play() {
			playCallCount += 1
			isPlaying = true
		}

		func pause() {
			pauseCallCount += 1
			isPlaying = false
		}
	}
}

private extension VideoPlayerViewController {
	func simulatePlayButtonTap() {
		playButton.simulate(event: .touchUpInside)
	}
}

private extension UIButton {
	func simulate(event: UIControl.Event) {
		allTargets.forEach { target in
			actions(forTarget: target, forControlEvent: event)?.forEach {
				(target as NSObject).perform(Selector($0))
			}
		}
	}
}
