//
//  PerformanceMetricsTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

@MainActor
final class PerformanceMetricsTests: XCTestCase {

    func test_init_createsMetricsWithCorrectProperties() {
        let sessionID = UUID()
        let metrics = PerformanceMetrics(
            sessionID: sessionID,
            timeToFirstFrame: 1.5,
            bufferingEvents: 3,
            totalBufferingDuration: 5.0,
            watchDuration: 60.0
        )

        XCTAssertEqual(metrics.sessionID, sessionID)
        XCTAssertEqual(metrics.timeToFirstFrame, 1.5)
        XCTAssertEqual(metrics.bufferingEvents, 3)
        XCTAssertEqual(metrics.totalBufferingDuration, 5.0)
        XCTAssertEqual(metrics.watchDuration, 60.0)
    }

    func test_init_supportsNilTimeToFirstFrame() {
        let metrics = PerformanceMetrics(
            sessionID: UUID(),
            timeToFirstFrame: nil,
            bufferingEvents: 0,
            totalBufferingDuration: 0,
            watchDuration: 30.0
        )

        XCTAssertNil(metrics.timeToFirstFrame)
    }

    func test_rebufferingRatio_calculatesCorrectly() {
        let metrics = PerformanceMetrics(
            sessionID: UUID(),
            timeToFirstFrame: 1.0,
            bufferingEvents: 2,
            totalBufferingDuration: 10.0,
            watchDuration: 100.0
        )

        XCTAssertEqual(metrics.rebufferingRatio, 0.1, accuracy: 0.001)
    }

    func test_rebufferingRatio_returnsZeroForZeroWatchDuration() {
        let metrics = PerformanceMetrics(
            sessionID: UUID(),
            timeToFirstFrame: 1.0,
            bufferingEvents: 2,
            totalBufferingDuration: 10.0,
            watchDuration: 0
        )

        XCTAssertEqual(metrics.rebufferingRatio, 0)
    }

    func test_rebufferingRatio_returnsZeroForZeroBufferingDuration() {
        let metrics = PerformanceMetrics(
            sessionID: UUID(),
            timeToFirstFrame: 1.0,
            bufferingEvents: 0,
            totalBufferingDuration: 0,
            watchDuration: 100.0
        )

        XCTAssertEqual(metrics.rebufferingRatio, 0)
    }

    func test_rebufferingRatio_handlesHighBufferingRatio() {
        let metrics = PerformanceMetrics(
            sessionID: UUID(),
            timeToFirstFrame: 1.0,
            bufferingEvents: 10,
            totalBufferingDuration: 50.0,
            watchDuration: 100.0
        )

        XCTAssertEqual(metrics.rebufferingRatio, 0.5, accuracy: 0.001)
    }

    func test_isEquatableWithSameValues() {
        let sessionID = UUID()

        let metrics1 = PerformanceMetrics(
            sessionID: sessionID,
            timeToFirstFrame: 1.5,
            bufferingEvents: 3,
            totalBufferingDuration: 5.0,
            watchDuration: 60.0
        )

        let metrics2 = PerformanceMetrics(
            sessionID: sessionID,
            timeToFirstFrame: 1.5,
            bufferingEvents: 3,
            totalBufferingDuration: 5.0,
            watchDuration: 60.0
        )

        XCTAssertEqual(metrics1, metrics2)
    }

    func test_isNotEqualWithDifferentSessionID() {
        let metrics1 = PerformanceMetrics(
            sessionID: UUID(),
            timeToFirstFrame: 1.5,
            bufferingEvents: 3,
            totalBufferingDuration: 5.0,
            watchDuration: 60.0
        )

        let metrics2 = PerformanceMetrics(
            sessionID: UUID(),
            timeToFirstFrame: 1.5,
            bufferingEvents: 3,
            totalBufferingDuration: 5.0,
            watchDuration: 60.0
        )

        XCTAssertNotEqual(metrics1, metrics2)
    }

    func test_isSendable() async {
        let metrics = PerformanceMetrics(
            sessionID: UUID(),
            timeToFirstFrame: 1.5,
            bufferingEvents: 3,
            totalBufferingDuration: 5.0,
            watchDuration: 60.0
        )

        let result = await Task.detached {
            return metrics
        }.value

        XCTAssertEqual(result.bufferingEvents, 3)
    }
}
