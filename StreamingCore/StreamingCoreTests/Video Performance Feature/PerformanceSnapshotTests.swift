//
//  PerformanceSnapshotTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PerformanceSnapshotTests: XCTestCase {

	// MARK: - Initialization Tests

	func test_init_setsAllProperties() {
		let sessionID = UUID()
		let timestamp = Date()
		let sessionStartTime = timestamp.addingTimeInterval(-60)

		let sut = PerformanceSnapshot(
			timestamp: timestamp,
			sessionID: sessionID,
			timeToFirstFrame: 1.5,
			isBuffering: false,
			bufferingCount: 2,
			totalBufferingDuration: 5.0,
			currentBufferingDuration: nil,
			currentBitrate: 3_000_000,
			networkQuality: .good,
			memoryUsageMB: 150.0,
			memoryPressure: .normal,
			sessionStartTime: sessionStartTime
		)

		XCTAssertEqual(sut.sessionID, sessionID)
		XCTAssertEqual(sut.timestamp, timestamp)
		XCTAssertEqual(sut.timeToFirstFrame, 1.5)
		XCTAssertFalse(sut.isBuffering)
		XCTAssertEqual(sut.bufferingCount, 2)
		XCTAssertEqual(sut.totalBufferingDuration, 5.0)
		XCTAssertNil(sut.currentBufferingDuration)
		XCTAssertEqual(sut.currentBitrate, 3_000_000)
		XCTAssertEqual(sut.networkQuality, .good)
		XCTAssertEqual(sut.memoryUsageMB, 150.0)
		XCTAssertEqual(sut.memoryPressure, .normal)
	}

	// MARK: - Rebuffering Ratio Tests

	func test_rebufferingRatio_calculatesCorrectly() {
		let sessionStartTime = Date().addingTimeInterval(-100) // 100 seconds ago
		let timestamp = Date()

		let sut = makeSnapshot(
			timestamp: timestamp,
			totalBufferingDuration: 5.0,
			sessionStartTime: sessionStartTime
		)

		// 5 seconds buffering out of 100 seconds = 5%
		XCTAssertEqual(sut.rebufferingRatio, 0.05, accuracy: 0.001)
	}

	func test_rebufferingRatio_returnsZeroWhenNoSessionDuration() {
		let now = Date()
		let sut = makeSnapshot(
			timestamp: now,
			totalBufferingDuration: 5.0,
			sessionStartTime: now
		)

		XCTAssertEqual(sut.rebufferingRatio, 0)
	}

	// MARK: - isHealthy Tests

	func test_isHealthy_returnsTrueWhenAllMetricsAreGood() {
		let sut = makeSnapshot(
			timeToFirstFrame: 1.5,
			totalBufferingDuration: 1.0,
			memoryPressure: .normal,
			sessionDuration: 100
		)

		XCTAssertTrue(sut.isHealthy)
	}

	func test_isHealthy_returnsFalseWhenRebufferingRatioIsTooHigh() {
		let sut = makeSnapshot(
			timeToFirstFrame: 1.5,
			totalBufferingDuration: 10.0, // 10% of 100 seconds
			memoryPressure: .normal,
			sessionDuration: 100
		)

		XCTAssertFalse(sut.isHealthy)
	}

	func test_isHealthy_returnsFalseWhenMemoryPressureIsNotNormal() {
		let sut = makeSnapshot(
			timeToFirstFrame: 1.5,
			totalBufferingDuration: 1.0,
			memoryPressure: .warning,
			sessionDuration: 100
		)

		XCTAssertFalse(sut.isHealthy)
	}

	func test_isHealthy_returnsFalseWhenStartupTimeIsSlow() {
		let sut = makeSnapshot(
			timeToFirstFrame: 5.0, // > 3 seconds
			totalBufferingDuration: 1.0,
			memoryPressure: .normal,
			sessionDuration: 100
		)

		XCTAssertFalse(sut.isHealthy)
	}

	func test_isHealthy_returnsTrueWhenTimeToFirstFrameIsNil() {
		let sut = makeSnapshot(
			timeToFirstFrame: nil,
			totalBufferingDuration: 1.0,
			memoryPressure: .normal,
			sessionDuration: 100
		)

		XCTAssertTrue(sut.isHealthy)
	}

	// MARK: - Equatable Tests

	func test_equality() {
		let sessionID = UUID()
		let timestamp = Date()
		let sessionStartTime = timestamp.addingTimeInterval(-60)

		let snapshot1 = PerformanceSnapshot(
			timestamp: timestamp,
			sessionID: sessionID,
			timeToFirstFrame: 1.5,
			isBuffering: false,
			bufferingCount: 2,
			totalBufferingDuration: 5.0,
			currentBufferingDuration: nil,
			currentBitrate: 3_000_000,
			networkQuality: .good,
			memoryUsageMB: 150.0,
			memoryPressure: .normal,
			sessionStartTime: sessionStartTime
		)

		let snapshot2 = PerformanceSnapshot(
			timestamp: timestamp,
			sessionID: sessionID,
			timeToFirstFrame: 1.5,
			isBuffering: false,
			bufferingCount: 2,
			totalBufferingDuration: 5.0,
			currentBufferingDuration: nil,
			currentBitrate: 3_000_000,
			networkQuality: .good,
			memoryUsageMB: 150.0,
			memoryPressure: .normal,
			sessionStartTime: sessionStartTime
		)

		XCTAssertEqual(snapshot1, snapshot2)
	}

	// MARK: - Sendable Tests

	func test_performanceSnapshot_isSendable() {
		let snapshot: any Sendable = makeSnapshot()
		XCTAssertNotNil(snapshot)
	}

	// MARK: - Helpers

	private func makeSnapshot(
		timestamp: Date = Date(),
		sessionID: UUID = UUID(),
		timeToFirstFrame: TimeInterval? = 1.5,
		isBuffering: Bool = false,
		bufferingCount: Int = 0,
		totalBufferingDuration: TimeInterval = 0,
		currentBufferingDuration: TimeInterval? = nil,
		currentBitrate: Int? = 3_000_000,
		networkQuality: NetworkQuality = .good,
		memoryUsageMB: Double = 100.0,
		memoryPressure: MemoryPressureLevel = .normal,
		sessionStartTime: Date? = nil,
		sessionDuration: TimeInterval = 60
	) -> PerformanceSnapshot {
		let effectiveSessionStartTime = sessionStartTime ?? timestamp.addingTimeInterval(-sessionDuration)

		return PerformanceSnapshot(
			timestamp: timestamp,
			sessionID: sessionID,
			timeToFirstFrame: timeToFirstFrame,
			isBuffering: isBuffering,
			bufferingCount: bufferingCount,
			totalBufferingDuration: totalBufferingDuration,
			currentBufferingDuration: currentBufferingDuration,
			currentBitrate: currentBitrate,
			networkQuality: networkQuality,
			memoryUsageMB: memoryUsageMB,
			memoryPressure: memoryPressure,
			sessionStartTime: effectiveSessionStartTime
		)
	}
}
