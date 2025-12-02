//
//  PerformanceTrackerTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

@MainActor
final class PerformanceTrackerTests: XCTestCase {

    func test_init_createsTrackerWithSessionID() {
        let sessionID = UUID()
        let sut = makeSUT(sessionID: sessionID)

        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertEqual(metrics.sessionID, sessionID)
    }

    func test_buildMetrics_deliversNilTimeToFirstFrameWhenNeverSet() {
        let sut = makeSUT()

        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertNil(metrics.timeToFirstFrame)
    }

    func test_buildMetrics_deliversTimeToFirstFrameWhenSet() {
        let sut = makeSUT()
        let loadStart = Date()
        let firstFrame = loadStart.addingTimeInterval(1.5)

        sut.videoLoadStarted(at: loadStart)
        sut.firstFrameRendered(at: firstFrame)
        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertNotNil(metrics.timeToFirstFrame)
        XCTAssertEqual(metrics.timeToFirstFrame!, 1.5, accuracy: 0.001)
    }

    func test_buildMetrics_deliversZeroBufferingEventsOnNoBuffering() {
        let sut = makeSUT()

        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertEqual(metrics.bufferingEvents, 0)
        XCTAssertEqual(metrics.totalBufferingDuration, 0)
    }

    func test_bufferingStartedAndEnded_tracksBufferingEvent() {
        let sut = makeSUT()
        let bufferingStart = Date()
        let bufferingEnd = bufferingStart.addingTimeInterval(2.0)

        sut.bufferingStarted(at: bufferingStart)
        sut.bufferingEnded(at: bufferingEnd)
        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertEqual(metrics.bufferingEvents, 1)
        XCTAssertEqual(metrics.totalBufferingDuration, 2.0, accuracy: 0.001)
    }

    func test_multipleBufferingEvents_accumulatesDuration() {
        let sut = makeSUT()
        let baseTime = Date()

        sut.bufferingStarted(at: baseTime)
        sut.bufferingEnded(at: baseTime.addingTimeInterval(2.0))

        sut.bufferingStarted(at: baseTime.addingTimeInterval(10.0))
        sut.bufferingEnded(at: baseTime.addingTimeInterval(13.0))

        sut.bufferingStarted(at: baseTime.addingTimeInterval(20.0))
        sut.bufferingEnded(at: baseTime.addingTimeInterval(21.0))

        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertEqual(metrics.bufferingEvents, 3)
        XCTAssertEqual(metrics.totalBufferingDuration, 6.0, accuracy: 0.001) // 2 + 3 + 1
    }

    func test_bufferingStartedWithoutEnd_doesNotCountAsEvent() {
        let sut = makeSUT()

        sut.bufferingStarted(at: Date())
        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertEqual(metrics.bufferingEvents, 0)
        XCTAssertEqual(metrics.totalBufferingDuration, 0)
    }

    func test_bufferingEndedWithoutStart_isIgnored() {
        let sut = makeSUT()

        sut.bufferingEnded(at: Date())
        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertEqual(metrics.bufferingEvents, 0)
        XCTAssertEqual(metrics.totalBufferingDuration, 0)
    }

    func test_buildMetrics_deliversCorrectWatchDuration() {
        let sut = makeSUT()

        let metrics = sut.buildMetrics(watchDuration: 120.5)

        XCTAssertEqual(metrics.watchDuration, 120.5)
    }

    func test_firstFrameRenderedBeforeLoadStart_isIgnored() {
        let sut = makeSUT()
        let time = Date()

        sut.firstFrameRendered(at: time)
        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertNil(metrics.timeToFirstFrame)
    }

    func test_doubleVideoLoadStarted_usesFirstStartTime() {
        let sut = makeSUT()
        let firstLoadStart = Date()
        let secondLoadStart = firstLoadStart.addingTimeInterval(1.0)
        let firstFrame = firstLoadStart.addingTimeInterval(2.0)

        sut.videoLoadStarted(at: firstLoadStart)
        sut.videoLoadStarted(at: secondLoadStart)
        sut.firstFrameRendered(at: firstFrame)
        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertNotNil(metrics.timeToFirstFrame)
        XCTAssertEqual(metrics.timeToFirstFrame!, 2.0, accuracy: 0.001)
    }

    func test_doubleFirstFrameRendered_usesFirstFrameTime() {
        let sut = makeSUT()
        let loadStart = Date()
        let firstFrame = loadStart.addingTimeInterval(1.0)
        let secondFrame = loadStart.addingTimeInterval(2.0)

        sut.videoLoadStarted(at: loadStart)
        sut.firstFrameRendered(at: firstFrame)
        sut.firstFrameRendered(at: secondFrame)
        let metrics = sut.buildMetrics(watchDuration: 60.0)

        XCTAssertNotNil(metrics.timeToFirstFrame)
        XCTAssertEqual(metrics.timeToFirstFrame!, 1.0, accuracy: 0.001)
    }

    func test_rebufferingRatio_calculatesCorrectly() {
        let sut = makeSUT()
        let baseTime = Date()

        sut.bufferingStarted(at: baseTime)
        sut.bufferingEnded(at: baseTime.addingTimeInterval(10.0))

        let metrics = sut.buildMetrics(watchDuration: 100.0)

        XCTAssertEqual(metrics.rebufferingRatio, 0.1, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeSUT(sessionID: UUID = UUID(), file: StaticString = #filePath, line: UInt = #line) -> PerformanceTracker {
        let sut = PerformanceTracker(sessionID: sessionID)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
