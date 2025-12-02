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

	func test_seekForwardButtonTap_seeksForward() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulateSeekForwardButtonTap()

		XCTAssertEqual(player.seekForwardCallCount, 1)
	}

	func test_seekBackwardButtonTap_seeksBackward() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulateSeekBackwardButtonTap()

		XCTAssertEqual(player.seekBackwardCallCount, 1)
	}

	func test_progressSliderValueChanged_seeksToPosition() {
		let (sut, player) = makeSUT()
		player.duration = 100

		sut.loadViewIfNeeded()
		sut.simulateProgressSliderValueChanged(to: 0.5)

		XCTAssertEqual(player.seekToTimes, [50])
	}

	func test_timeLabelsUpdate_displaysFormattedTime() {
		let (sut, player) = makeSUT()
		player.currentTime = 65
		player.duration = 3661

		sut.loadViewIfNeeded()
		sut.simulateTimeUpdate()

		XCTAssertEqual(sut.currentTimeLabel.text, "1:05")
		XCTAssertEqual(sut.durationLabel.text, "1:01:01")
	}

	func test_progressSlider_updatesWithCurrentTime() {
		let (sut, player) = makeSUT()
		player.currentTime = 30
		player.duration = 60

		sut.loadViewIfNeeded()
		sut.simulateTimeUpdate()

		XCTAssertEqual(sut.progressSlider.value, 0.5, accuracy: 0.01)
	}

	func test_muteButtonTap_togglesMute() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		XCTAssertFalse(player.isMuted)

		sut.simulateMuteButtonTap()
		XCTAssertTrue(player.isMuted)

		sut.simulateMuteButtonTap()
		XCTAssertFalse(player.isMuted)
	}

	func test_volumeSliderValueChanged_setsVolume() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		sut.simulateVolumeSliderValueChanged(to: 0.7)

		XCTAssertEqual(player.volume, 0.7, accuracy: 0.01)
	}

	func test_playbackSpeedButtonTap_cyclesThroughSpeeds() {
		let (sut, player) = makeSUT()

		sut.loadViewIfNeeded()
		XCTAssertEqual(player.playbackSpeed, 1.0, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 1.25, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 1.5, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 2.0, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 0.5, accuracy: 0.01)

		sut.simulatePlaybackSpeedButtonTap()
		XCTAssertEqual(player.playbackSpeed, 1.0, accuracy: 0.01)
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
		private(set) var seekForwardCallCount = 0
		private(set) var seekBackwardCallCount = 0
		private(set) var seekToTimes = [TimeInterval]()

		var isPlaying: Bool = false
		var currentTime: TimeInterval = 0
		var duration: TimeInterval = 0
		var volume: Float = 1.0
		var isMuted: Bool = false
		var playbackSpeed: Float = 1.0

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

		func seekForward(by seconds: TimeInterval) {
			seekForwardCallCount += 1
		}

		func seekBackward(by seconds: TimeInterval) {
			seekBackwardCallCount += 1
		}

		func seek(to time: TimeInterval) {
			seekToTimes.append(time)
		}

		func setVolume(_ volume: Float) {
			self.volume = volume
		}

		func toggleMute() {
			isMuted.toggle()
		}

		func setPlaybackSpeed(_ speed: Float) {
			playbackSpeed = speed
		}
	}
}

private extension VideoPlayerViewController {
	func simulatePlayButtonTap() {
		playButton.simulate(event: .touchUpInside)
	}

	func simulateSeekForwardButtonTap() {
		seekForwardButton.simulate(event: .touchUpInside)
	}

	func simulateSeekBackwardButtonTap() {
		seekBackwardButton.simulate(event: .touchUpInside)
	}

	func simulateProgressSliderValueChanged(to value: Float) {
		progressSlider.value = value
		progressSlider.simulate(event: .valueChanged)
	}

	func simulateTimeUpdate() {
		updateTimeDisplay()
	}

	func simulateMuteButtonTap() {
		muteButton.simulate(event: .touchUpInside)
	}

	func simulateVolumeSliderValueChanged(to value: Float) {
		volumeSlider.value = value
		volumeSlider.simulate(event: .valueChanged)
	}

	func simulatePlaybackSpeedButtonTap() {
		playbackSpeedButton.simulate(event: .touchUpInside)
	}
}

private extension UIControl {
	func simulate(event: UIControl.Event) {
		allTargets.forEach { target in
			actions(forTarget: target, forControlEvent: event)?.forEach {
				(target as NSObject).perform(Selector($0))
			}
		}
	}
}
