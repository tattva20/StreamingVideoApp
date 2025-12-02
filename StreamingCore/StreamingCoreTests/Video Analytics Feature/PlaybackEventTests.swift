//
//  PlaybackEventTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

@MainActor
final class PlaybackEventTests: XCTestCase {

    // MARK: - PlaybackEventType Tests

    func test_playbackEventType_playIsEquatable() {
        XCTAssertEqual(PlaybackEventType.play, PlaybackEventType.play)
    }

    func test_playbackEventType_pauseIsEquatable() {
        XCTAssertEqual(PlaybackEventType.pause, PlaybackEventType.pause)
    }

    func test_playbackEventType_seekIsEquatableWithSameValues() {
        let seek1 = PlaybackEventType.seek(from: 10.0, to: 20.0)
        let seek2 = PlaybackEventType.seek(from: 10.0, to: 20.0)
        XCTAssertEqual(seek1, seek2)
    }

    func test_playbackEventType_seekIsNotEqualWithDifferentValues() {
        let seek1 = PlaybackEventType.seek(from: 10.0, to: 20.0)
        let seek2 = PlaybackEventType.seek(from: 10.0, to: 30.0)
        XCTAssertNotEqual(seek1, seek2)
    }

    func test_playbackEventType_speedChangedIsEquatableWithSameValues() {
        let speed1 = PlaybackEventType.speedChanged(from: 1.0, to: 2.0)
        let speed2 = PlaybackEventType.speedChanged(from: 1.0, to: 2.0)
        XCTAssertEqual(speed1, speed2)
    }

    func test_playbackEventType_volumeChangedIsEquatableWithSameValues() {
        let volume1 = PlaybackEventType.volumeChanged(from: 0.5, to: 1.0)
        let volume2 = PlaybackEventType.volumeChanged(from: 0.5, to: 1.0)
        XCTAssertEqual(volume1, volume2)
    }

    func test_playbackEventType_muteToggledIsEquatableWithSameValue() {
        let mute1 = PlaybackEventType.muteToggled(isMuted: true)
        let mute2 = PlaybackEventType.muteToggled(isMuted: true)
        XCTAssertEqual(mute1, mute2)
    }

    func test_playbackEventType_muteToggledIsNotEqualWithDifferentValue() {
        let mute1 = PlaybackEventType.muteToggled(isMuted: true)
        let mute2 = PlaybackEventType.muteToggled(isMuted: false)
        XCTAssertNotEqual(mute1, mute2)
    }

    func test_playbackEventType_videoAbandonedIsEquatableWithSameValues() {
        let abandoned1 = PlaybackEventType.videoAbandoned(watchedDuration: 30.0, totalDuration: 100.0)
        let abandoned2 = PlaybackEventType.videoAbandoned(watchedDuration: 30.0, totalDuration: 100.0)
        XCTAssertEqual(abandoned1, abandoned2)
    }

    func test_playbackEventType_errorIsEquatableWithSameValues() {
        let error1 = PlaybackEventType.error(code: "404", message: "Not Found")
        let error2 = PlaybackEventType.error(code: "404", message: "Not Found")
        XCTAssertEqual(error1, error2)
    }

    func test_playbackEventType_bufferingEndedIsEquatableWithSameDuration() {
        let buffering1 = PlaybackEventType.bufferingEnded(duration: 2.5)
        let buffering2 = PlaybackEventType.bufferingEnded(duration: 2.5)
        XCTAssertEqual(buffering1, buffering2)
    }

    func test_playbackEventType_qualityChangedIsEquatableWithSameValues() {
        let quality1 = PlaybackEventType.qualityChanged(from: "720p", to: "1080p")
        let quality2 = PlaybackEventType.qualityChanged(from: "720p", to: "1080p")
        XCTAssertEqual(quality1, quality2)
    }

    func test_playbackEventType_qualityChangedSupportsNilFromValue() {
        let quality1 = PlaybackEventType.qualityChanged(from: nil, to: "1080p")
        let quality2 = PlaybackEventType.qualityChanged(from: nil, to: "1080p")
        XCTAssertEqual(quality1, quality2)
    }

    func test_playbackEventType_differentTypesAreNotEqual() {
        XCTAssertNotEqual(PlaybackEventType.play, PlaybackEventType.pause)
        XCTAssertNotEqual(PlaybackEventType.videoStarted, PlaybackEventType.videoCompleted)
        XCTAssertNotEqual(PlaybackEventType.fullscreenEntered, PlaybackEventType.fullscreenExited)
        XCTAssertNotEqual(PlaybackEventType.pipEntered, PlaybackEventType.pipExited)
        XCTAssertNotEqual(PlaybackEventType.bufferingStarted, PlaybackEventType.bufferingEnded(duration: 1.0))
    }

    // MARK: - PlaybackEvent Tests

    func test_playbackEvent_initCreatesEventWithCorrectProperties() {
        let id = UUID()
        let sessionID = UUID()
        let videoID = UUID()
        let type = PlaybackEventType.play
        let timestamp = Date()
        let position: TimeInterval = 30.5

        let event = PlaybackEvent(
            id: id,
            sessionID: sessionID,
            videoID: videoID,
            type: type,
            timestamp: timestamp,
            currentPosition: position
        )

        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.sessionID, sessionID)
        XCTAssertEqual(event.videoID, videoID)
        XCTAssertEqual(event.type, type)
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertEqual(event.currentPosition, position)
    }

    func test_playbackEvent_isEquatableWithSameValues() {
        let id = UUID()
        let sessionID = UUID()
        let videoID = UUID()
        let timestamp = Date()

        let event1 = PlaybackEvent(
            id: id,
            sessionID: sessionID,
            videoID: videoID,
            type: .play,
            timestamp: timestamp,
            currentPosition: 10.0
        )

        let event2 = PlaybackEvent(
            id: id,
            sessionID: sessionID,
            videoID: videoID,
            type: .play,
            timestamp: timestamp,
            currentPosition: 10.0
        )

        XCTAssertEqual(event1, event2)
    }

    func test_playbackEvent_isNotEqualWithDifferentID() {
        let sessionID = UUID()
        let videoID = UUID()
        let timestamp = Date()

        let event1 = PlaybackEvent(
            id: UUID(),
            sessionID: sessionID,
            videoID: videoID,
            type: .play,
            timestamp: timestamp,
            currentPosition: 10.0
        )

        let event2 = PlaybackEvent(
            id: UUID(),
            sessionID: sessionID,
            videoID: videoID,
            type: .play,
            timestamp: timestamp,
            currentPosition: 10.0
        )

        XCTAssertNotEqual(event1, event2)
    }

    func test_playbackEvent_isNotEqualWithDifferentType() {
        let id = UUID()
        let sessionID = UUID()
        let videoID = UUID()
        let timestamp = Date()

        let event1 = PlaybackEvent(
            id: id,
            sessionID: sessionID,
            videoID: videoID,
            type: .play,
            timestamp: timestamp,
            currentPosition: 10.0
        )

        let event2 = PlaybackEvent(
            id: id,
            sessionID: sessionID,
            videoID: videoID,
            type: .pause,
            timestamp: timestamp,
            currentPosition: 10.0
        )

        XCTAssertNotEqual(event1, event2)
    }

    // MARK: - Sendable Conformance

    func test_playbackEventType_isSendable() async {
        let eventType = PlaybackEventType.play

        let result = await Task.detached {
            return eventType
        }.value

        XCTAssertEqual(result, PlaybackEventType.play)
    }

    func test_playbackEvent_isSendable() async {
        let event = PlaybackEvent(
            id: UUID(),
            sessionID: UUID(),
            videoID: UUID(),
            type: .play,
            timestamp: Date(),
            currentPosition: 0
        )

        let result = await Task.detached {
            return event
        }.value

        XCTAssertEqual(result.type, .play)
    }
}
