//
//  AnalyticsVideoPlayerDecoratorTests.swift
//  StreamingVideoAppTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore
@testable import StreamingVideoApp

@MainActor
final class AnalyticsVideoPlayerDecoratorTests: XCTestCase {

    // MARK: - Delegation Tests

    func test_isPlaying_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.isPlaying = true

        XCTAssertTrue(sut.isPlaying)
        await Task.yield()
    }

    func test_currentTime_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.currentTime = 42.5

        XCTAssertEqual(sut.currentTime, 42.5)
        await Task.yield()
    }

    func test_duration_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.duration = 120.0

        XCTAssertEqual(sut.duration, 120.0)
        await Task.yield()
    }

    func test_volume_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.volume = 0.75

        XCTAssertEqual(sut.volume, 0.75)
        await Task.yield()
    }

    func test_isMuted_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.isMuted = true

        XCTAssertTrue(sut.isMuted)
        await Task.yield()
    }

    func test_playbackSpeed_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.playbackSpeed = 1.5

        XCTAssertEqual(sut.playbackSpeed, 1.5)
        await Task.yield()
    }

    func test_load_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        let url = URL(string: "https://example.com/video.mp4")!

        sut.load(url: url)

        XCTAssertEqual(decoratee.loadedURL, url)
        await Task.yield()
    }

    func test_play_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)

        sut.play()

        XCTAssertTrue(decoratee.isPlaying)
        await Task.yield()
    }

    func test_pause_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.isPlaying = true

        sut.pause()

        XCTAssertFalse(decoratee.isPlaying)
        await Task.yield()
    }

    func test_seekForward_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.currentTime = 10.0

        sut.seekForward(by: 15.0)

        XCTAssertEqual(decoratee.seekForwardAmount, 15.0)
        await Task.yield()
    }

    func test_seekBackward_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.currentTime = 30.0

        sut.seekBackward(by: 10.0)

        XCTAssertEqual(decoratee.seekBackwardAmount, 10.0)
        await Task.yield()
    }

    func test_seek_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)

        sut.seek(to: 50.0)

        XCTAssertEqual(decoratee.seekToTime, 50.0)
        await Task.yield()
    }

    func test_setVolume_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)

        sut.setVolume(0.8)

        XCTAssertEqual(decoratee.volume, 0.8)
        await Task.yield()
    }

    func test_toggleMute_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)
        decoratee.isMuted = false

        sut.toggleMute()

        XCTAssertTrue(decoratee.isMuted)
        await Task.yield()
    }

    func test_setPlaybackSpeed_delegatesToDecoratee() async {
        let decoratee = VideoPlayerSpy()
        let sut = makeSUT(decoratee: decoratee)

        sut.setPlaybackSpeed(2.0)

        XCTAssertEqual(decoratee.playbackSpeed, 2.0)
        await Task.yield()
    }

    // MARK: - Analytics Logging Tests

    func test_play_logsPlayEvent() async {
        let logger = PlaybackAnalyticsLoggerSpy()
        let sut = makeSUT(logger: logger)

        sut.play()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(logger.loggedEvents.count, 1)
        XCTAssertEqual(logger.loggedEvents.first?.type, .play)
    }

    func test_pause_logsPauseEvent() async {
        let decoratee = VideoPlayerSpy()
        let logger = PlaybackAnalyticsLoggerSpy()
        let sut = makeSUT(decoratee: decoratee, logger: logger)
        decoratee.isPlaying = true

        sut.pause()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(logger.loggedEvents.count, 1)
        XCTAssertEqual(logger.loggedEvents.first?.type, .pause)
    }

    func test_seek_logsSeekEvent() async {
        let decoratee = VideoPlayerSpy()
        let logger = PlaybackAnalyticsLoggerSpy()
        let sut = makeSUT(decoratee: decoratee, logger: logger)
        decoratee.currentTime = 10.0

        sut.seek(to: 50.0)
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(logger.loggedEvents.count, 1)
        if case let .seek(from, to) = logger.loggedEvents.first?.type {
            XCTAssertEqual(from, 10.0)
            XCTAssertEqual(to, 50.0)
        } else {
            XCTFail("Expected seek event")
        }
    }

    func test_setPlaybackSpeed_logsSpeedChangedEvent() async {
        let decoratee = VideoPlayerSpy()
        let logger = PlaybackAnalyticsLoggerSpy()
        let sut = makeSUT(decoratee: decoratee, logger: logger)
        decoratee.playbackSpeed = 1.0

        sut.setPlaybackSpeed(2.0)
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(logger.loggedEvents.count, 1)
        if case let .speedChanged(from, to) = logger.loggedEvents.first?.type {
            XCTAssertEqual(from, 1.0)
            XCTAssertEqual(to, 2.0)
        } else {
            XCTFail("Expected speedChanged event")
        }
    }

    func test_setVolume_logsVolumeChangedEvent() async {
        let decoratee = VideoPlayerSpy()
        let logger = PlaybackAnalyticsLoggerSpy()
        let sut = makeSUT(decoratee: decoratee, logger: logger)
        decoratee.volume = 0.5

        sut.setVolume(1.0)
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(logger.loggedEvents.count, 1)
        if case let .volumeChanged(from, to) = logger.loggedEvents.first?.type {
            XCTAssertEqual(from, 0.5)
            XCTAssertEqual(to, 1.0)
        } else {
            XCTFail("Expected volumeChanged event")
        }
    }

    func test_toggleMute_logsMuteToggledEvent() async {
        let decoratee = VideoPlayerSpy()
        let logger = PlaybackAnalyticsLoggerSpy()
        let sut = makeSUT(decoratee: decoratee, logger: logger)
        decoratee.isMuted = false

        sut.toggleMute()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(logger.loggedEvents.count, 1)
        if case let .muteToggled(isMuted) = logger.loggedEvents.first?.type {
            XCTAssertTrue(isMuted)
        } else {
            XCTFail("Expected muteToggled event")
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        decoratee: VideoPlayerSpy = VideoPlayerSpy(),
        logger: PlaybackAnalyticsLoggerSpy = PlaybackAnalyticsLoggerSpy()
    ) -> AnalyticsVideoPlayerDecorator {
        AnalyticsVideoPlayerDecorator(decoratee: decoratee, analyticsLogger: logger)
    }

    private class VideoPlayerSpy: VideoPlayer {
        var isPlaying: Bool = false
        var currentTime: TimeInterval = 0
        var duration: TimeInterval = 0
        var volume: Float = 1.0
        var isMuted: Bool = false
        var playbackSpeed: Float = 1.0

        var loadedURL: URL?
        var seekForwardAmount: TimeInterval?
        var seekBackwardAmount: TimeInterval?
        var seekToTime: TimeInterval?

        func load(url: URL) {
            loadedURL = url
        }

        func play() {
            isPlaying = true
        }

        func pause() {
            isPlaying = false
        }

        func seekForward(by seconds: TimeInterval) {
            seekForwardAmount = seconds
            currentTime += seconds
        }

        func seekBackward(by seconds: TimeInterval) {
            seekBackwardAmount = seconds
            currentTime -= seconds
        }

        func seek(to time: TimeInterval) {
            seekToTime = time
            currentTime = time
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

    private final class PlaybackAnalyticsLoggerSpy: PlaybackAnalyticsLogger, @unchecked Sendable {
        private let lock = NSLock()
        private var _loggedEvents: [(type: PlaybackEventType, position: TimeInterval)] = []

        var loggedEvents: [(type: PlaybackEventType, position: TimeInterval)] {
            lock.withLock { _loggedEvents }
        }

        func startSession(videoID: UUID, videoTitle: String, deviceInfo: DeviceInfo, appVersion: String) async -> PlaybackSession {
            PlaybackSession(
                id: UUID(),
                videoID: videoID,
                videoTitle: videoTitle,
                startTime: Date(),
                endTime: nil,
                deviceInfo: deviceInfo,
                appVersion: appVersion
            )
        }

        func log(_ event: PlaybackEventType, position: TimeInterval) async {
            lock.withLock {
                _loggedEvents.append((event, position))
            }
        }

        func endSession(watchedDuration: TimeInterval, completed: Bool) async {}

        func getCurrentPerformanceMetrics(watchDuration: TimeInterval) async -> PerformanceMetrics? { nil }

        func trackVideoLoadStarted() async {}

        func trackFirstFrameRendered() async {}

        func trackBufferingStarted() async {}

        func trackBufferingEnded() async {}
    }
}
