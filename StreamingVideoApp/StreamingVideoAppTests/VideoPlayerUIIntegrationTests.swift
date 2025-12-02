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

	func test_videoPlayerView_autoPlaysOnAppear() {
		let player = VideoPlayerSpy()
		let sut = makeSUT(player: player)

		sut.simulateViewDidAppear()

		XCTAssertTrue(player.isPlaying, "Expected video to auto-play when view appears")
	}

	func test_videoPlayerView_allControlsHideWhenAutoHideTriggersWhilePlaying() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateControlsAutoHide()

		XCTAssertEqual(sut.playButton.alpha, 0.0, "Expected play button to hide")
		XCTAssertEqual(sut.muteButton.alpha, 0.0, "Expected mute button to hide")
		XCTAssertEqual(sut.volumeSlider.alpha, 0.0, "Expected volume slider to hide")
		XCTAssertEqual(sut.playbackSpeedButton.alpha, 0.0, "Expected playback speed button to hide")
		XCTAssertEqual(sut.fullscreenButton.alpha, 0.0, "Expected fullscreen button to hide")
	}

	func test_videoPlayerView_controlsRemainVisibleWhenPaused() {
		let player = VideoPlayerSpy()
		player.isPlaying = false
		let sut = makeSUT(player: player)

		sut.simulateControlsAutoHide()

		XCTAssertEqual(sut.playButton.alpha, 1.0, "Expected play button to remain visible when paused")
		XCTAssertEqual(sut.muteButton.alpha, 1.0, "Expected mute button to remain visible when paused")
	}

	func test_videoPlayerView_showsControlsWhenVideoIsPaused() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateControlsAutoHide()
		XCTAssertEqual(sut.playButton.alpha, 0.0, "Precondition: controls should be hidden")

		player.isPlaying = false
		sut.simulatePauseTriggered()

		XCTAssertEqual(sut.playButton.alpha, 1.0, "Expected controls to show when video is paused")
	}

	func test_videoPlayerView_landscapeLayoutExpandsPlayerView() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(sut.isPlayerViewFullscreen, "Expected playerView to be fullscreen in landscape")
	}

	func test_videoPlayerView_hidesCommentsInLandscape() {
		let commentsController = UIViewController()
		let sut = makeSUT(commentsController: commentsController)

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(sut.commentsContainerView?.isHidden ?? true, "Expected comments to be hidden in landscape")
	}

	func test_videoPlayerView_hidesBottomControlsInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(sut.bottomControlsContainerView?.isHidden ?? true, "Expected bottom controls container to be hidden in landscape")
	}

	func test_videoPlayerView_showsTitleLabelInLandscape() {
		let video = makeVideo(title: "Test Title")
		let sut = makeSUT(video: video)

		sut.simulateLandscapeOrientation()

		XCTAssertNotNil(sut.landscapeTitleLabel, "Expected landscape title label to exist")
		XCTAssertEqual(sut.landscapeTitleLabel?.text, "Test Title", "Expected title label to show video title")
		XCTAssertFalse(sut.landscapeTitleLabel?.isHidden ?? true, "Expected title label to be visible in landscape")
	}

	func test_videoPlayerView_titleLabelHasLowAlphaWhiteInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertEqual(sut.landscapeTitleLabel?.textColor, UIColor.white.withAlphaComponent(0.7), "Expected title label to have low alpha white color")
	}

	func test_videoPlayerView_titleLabelAutoHidesWithControlsInLandscape() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateLandscapeOrientation()
		XCTAssertEqual(sut.landscapeTitleLabel?.alpha, 1.0, "Precondition: title should be visible initially")

		sut.simulateControlsAutoHide()

		XCTAssertEqual(sut.landscapeTitleLabel?.alpha, 0.0, "Expected title label to auto-hide with controls")
	}

	func test_videoPlayerView_titleLabelShowsWithControlsWhenPaused() {
		let player = VideoPlayerSpy()
		player.isPlaying = true
		let sut = makeSUT(player: player)

		sut.simulateLandscapeOrientation()
		sut.simulateControlsAutoHide()
		XCTAssertEqual(sut.landscapeTitleLabel?.alpha, 0.0, "Precondition: title should be hidden")

		player.isPlaying = false
		sut.simulatePauseTriggered()

		XCTAssertEqual(sut.landscapeTitleLabel?.alpha, 1.0, "Expected title label to show with controls when paused")
	}

	func test_videoPlayerView_hidesTitleLabelInPortrait() {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertTrue(sut.landscapeTitleLabel?.isHidden ?? true, "Expected landscape title label to be hidden in portrait")
	}

	func test_videoPlayerView_hidesNavigationBarInLandscape() {
		let sut = makeUnTrackedSUT()
		let nav = UINavigationController(rootViewController: sut)
		nav.loadViewIfNeeded()
		sut.loadViewIfNeeded()

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(nav.isNavigationBarHidden, "Expected navigation bar to be hidden in landscape")
	}

	func test_videoPlayerView_showsNavigationBarInPortrait() {
		let sut = makeUnTrackedSUT()
		let nav = UINavigationController(rootViewController: sut)
		nav.loadViewIfNeeded()
		sut.loadViewIfNeeded()
		sut.simulateLandscapeOrientation()

		sut.simulatePortraitOrientation()

		XCTAssertFalse(nav.isNavigationBarHidden, "Expected navigation bar to be visible in portrait")
	}

	func test_videoPlayerView_landscapeTitleLabelIsCentered() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let titleCenterX = sut.landscapeTitleLabel?.center.x ?? 0
		let viewCenterX = sut.view.bounds.width / 2
		XCTAssertEqual(titleCenterX, viewCenterX, accuracy: 1.0, "Expected title label to be centered horizontally")
	}

	func test_videoPlayerView_fullscreenButtonVisibleInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertEqual(sut.fullscreenButton.alpha, 1.0, "Expected fullscreen button to be visible in landscape")
		XCTAssertFalse(sut.fullscreenButton.isHidden, "Expected fullscreen button to not be hidden in landscape")
	}

	func test_videoPlayerView_fullscreenButtonCallsToggleHandler() {
		let sut = makeSUT()
		var toggleCallCount = 0
		sut.onFullscreenToggle = { toggleCallCount += 1 }

		sut.loadViewIfNeeded()
		sut.fullscreenButton.simulateTap()

		XCTAssertEqual(toggleCallCount, 1, "Expected fullscreen toggle handler to be called once")
	}

	func test_videoPlayerView_fullscreenButtonIsPositionedNextToDurationLabelInLandscape() {
		let sut = makeSUT()
		sut.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)

		sut.simulateLandscapeOrientation()
		sut.view.layoutIfNeeded()

		let fullscreenX = sut.fullscreenButton.frame.minX
		let durationMaxX = sut.durationLabel.frame.maxX
		XCTAssertGreaterThan(fullscreenX, durationMaxX, "Expected fullscreen button to be positioned after duration label")
	}

	func test_videoPlayerView_isFullscreenIsFalseInPortrait() {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertFalse(sut.isFullscreen, "Expected isFullscreen to be false in portrait")
	}

	func test_videoPlayerView_isFullscreenIsTrueInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		XCTAssertTrue(sut.isFullscreen, "Expected isFullscreen to be true in landscape")
	}

	func test_videoPlayerView_fullscreenButtonShowsExpandIconInPortrait() {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		let expectedImage = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
		XCTAssertEqual(sut.fullscreenButton.image(for: .normal), expectedImage, "Expected expand icon in portrait")
	}

	func test_videoPlayerView_fullscreenButtonShowsCollapseIconInLandscape() {
		let sut = makeSUT()

		sut.simulateLandscapeOrientation()

		let expectedImage = UIImage(systemName: "arrow.down.right.and.arrow.up.left")
		XCTAssertEqual(sut.fullscreenButton.image(for: .normal), expectedImage, "Expected collapse icon in landscape")
	}

	func test_videoPlayerView_fullscreenButtonIconUpdatesOnOrientationChange() {
		let sut = makeSUT()
		sut.loadViewIfNeeded()

		let expandIcon = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
		let collapseIcon = UIImage(systemName: "arrow.down.right.and.arrow.up.left")

		XCTAssertEqual(sut.fullscreenButton.image(for: .normal), expandIcon, "Precondition: should show expand icon")

		sut.simulateLandscapeOrientation()
		XCTAssertEqual(sut.fullscreenButton.image(for: .normal), collapseIcon, "Expected collapse icon after landscape")

		sut.simulatePortraitOrientation()
		XCTAssertEqual(sut.fullscreenButton.image(for: .normal), expandIcon, "Expected expand icon after portrait")
	}

	// MARK: - Helpers

	private func makeSUT(
		video: Video = makeVideo(),
		player: VideoPlayer? = nil,
		commentsController: UIViewController? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> VideoPlayerViewController {
		let sut = VideoPlayerUIComposer.videoPlayerComposedWith(
			video: video,
			player: player,
			commentsController: commentsController
		)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func makeUnTrackedSUT(
		video: Video = makeVideo(),
		player: VideoPlayer? = nil,
		commentsController: UIViewController? = nil
	) -> VideoPlayerViewController {
		return VideoPlayerUIComposer.videoPlayerComposedWith(
			video: video,
			player: player,
			commentsController: commentsController
		)
	}

	private class VideoPlayerSpy: VideoPlayer {
		var isPlaying: Bool = false
		var currentTime: TimeInterval = 0
		var duration: TimeInterval = 100
		var volume: Float = 1.0
		var isMuted: Bool = false
		var playbackSpeed: Float = 1.0

		private(set) var loadedURLs: [URL] = []
		private(set) var playCallCount = 0
		private(set) var pauseCallCount = 0

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

		func seekForward(by seconds: TimeInterval) {}
		func seekBackward(by seconds: TimeInterval) {}
		func seek(to time: TimeInterval) {}
		func setVolume(_ volume: Float) {}
		func toggleMute() {}
		func setPlaybackSpeed(_ speed: Float) {}
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

extension VideoPlayerViewController {
	func simulateViewDidAppear() {
		loadViewIfNeeded()
		beginAppearanceTransition(true, animated: false)
		endAppearanceTransition()
	}

	func simulateControlsAutoHide() {
		loadViewIfNeeded()
		triggerAutoHide()
	}

	func simulatePauseTriggered() {
		showControlsOnPause()
		onPlaybackPaused?()
	}

	func simulateLandscapeOrientation() {
		loadViewIfNeeded()
		updateLayoutForOrientation(isLandscape: true)
	}

	func simulatePortraitOrientation() {
		loadViewIfNeeded()
		updateLayoutForOrientation(isLandscape: false)
	}

	var commentsContainerView: UIView? {
		view.subviews.first { $0.tag == 999 }
	}

	var bottomControlsContainerView: UIView? {
		view.subviews.first { $0.tag == 998 }
	}

	var isPlayerViewFullscreen: Bool {
		playerView.frame.width == view.bounds.width &&
		playerView.frame.height >= view.bounds.height * 0.9
	}

	var landscapeTitleLabel: UILabel? {
		view.subviews.compactMap { $0 as? UILabel }.first { $0.tag == 997 }
	}
}
