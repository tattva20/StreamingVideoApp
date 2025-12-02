//
//  EngagementMetricsTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

@MainActor
final class EngagementMetricsTests: XCTestCase {

    func test_init_createsMetricsWithCorrectProperties() {
        let sessionID = UUID()
        let metrics = EngagementMetrics(
            sessionID: sessionID,
            watchDuration: 45.0,
            videoDuration: 100.0,
            seekCount: 5,
            pauseCount: 3
        )

        XCTAssertEqual(metrics.sessionID, sessionID)
        XCTAssertEqual(metrics.watchDuration, 45.0)
        XCTAssertEqual(metrics.videoDuration, 100.0)
        XCTAssertEqual(metrics.seekCount, 5)
        XCTAssertEqual(metrics.pauseCount, 3)
    }

    func test_completionPercentage_calculatesCorrectly() {
        let metrics = EngagementMetrics(
            sessionID: UUID(),
            watchDuration: 50.0,
            videoDuration: 100.0,
            seekCount: 0,
            pauseCount: 0
        )

        XCTAssertEqual(metrics.completionPercentage, 50.0, accuracy: 0.001)
    }

    func test_completionPercentage_returnsZeroForZeroVideoDuration() {
        let metrics = EngagementMetrics(
            sessionID: UUID(),
            watchDuration: 50.0,
            videoDuration: 0,
            seekCount: 0,
            pauseCount: 0
        )

        XCTAssertEqual(metrics.completionPercentage, 0)
    }

    func test_completionPercentage_clampsToHundred() {
        let metrics = EngagementMetrics(
            sessionID: UUID(),
            watchDuration: 150.0,
            videoDuration: 100.0,
            seekCount: 0,
            pauseCount: 0
        )

        XCTAssertEqual(metrics.completionPercentage, 100.0)
    }

    func test_completionPercentage_returnsHundredForFullWatch() {
        let metrics = EngagementMetrics(
            sessionID: UUID(),
            watchDuration: 100.0,
            videoDuration: 100.0,
            seekCount: 0,
            pauseCount: 0
        )

        XCTAssertEqual(metrics.completionPercentage, 100.0, accuracy: 0.001)
    }

    func test_completionPercentage_handlesSmallValues() {
        let metrics = EngagementMetrics(
            sessionID: UUID(),
            watchDuration: 1.0,
            videoDuration: 1000.0,
            seekCount: 0,
            pauseCount: 0
        )

        XCTAssertEqual(metrics.completionPercentage, 0.1, accuracy: 0.001)
    }

    func test_isEquatableWithSameValues() {
        let sessionID = UUID()

        let metrics1 = EngagementMetrics(
            sessionID: sessionID,
            watchDuration: 45.0,
            videoDuration: 100.0,
            seekCount: 5,
            pauseCount: 3
        )

        let metrics2 = EngagementMetrics(
            sessionID: sessionID,
            watchDuration: 45.0,
            videoDuration: 100.0,
            seekCount: 5,
            pauseCount: 3
        )

        XCTAssertEqual(metrics1, metrics2)
    }

    func test_isNotEqualWithDifferentSessionID() {
        let metrics1 = EngagementMetrics(
            sessionID: UUID(),
            watchDuration: 45.0,
            videoDuration: 100.0,
            seekCount: 5,
            pauseCount: 3
        )

        let metrics2 = EngagementMetrics(
            sessionID: UUID(),
            watchDuration: 45.0,
            videoDuration: 100.0,
            seekCount: 5,
            pauseCount: 3
        )

        XCTAssertNotEqual(metrics1, metrics2)
    }

    func test_isNotEqualWithDifferentSeekCount() {
        let sessionID = UUID()

        let metrics1 = EngagementMetrics(
            sessionID: sessionID,
            watchDuration: 45.0,
            videoDuration: 100.0,
            seekCount: 5,
            pauseCount: 3
        )

        let metrics2 = EngagementMetrics(
            sessionID: sessionID,
            watchDuration: 45.0,
            videoDuration: 100.0,
            seekCount: 10,
            pauseCount: 3
        )

        XCTAssertNotEqual(metrics1, metrics2)
    }

    func test_isSendable() async {
        let metrics = EngagementMetrics(
            sessionID: UUID(),
            watchDuration: 45.0,
            videoDuration: 100.0,
            seekCount: 5,
            pauseCount: 3
        )

        let result = await Task.detached {
            return metrics
        }.value

        XCTAssertEqual(result.seekCount, 5)
    }
}
