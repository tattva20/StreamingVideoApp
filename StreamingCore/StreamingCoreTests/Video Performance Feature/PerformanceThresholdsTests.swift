//
//  PerformanceThresholdsTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PerformanceThresholdsTests: XCTestCase {

	// MARK: - Initialization Tests

	func test_init_setsAllProperties() {
		let sut = PerformanceThresholds(
			acceptableStartupTime: 1.0,
			warningStartupTime: 2.0,
			criticalStartupTime: 4.0,
			acceptableRebufferingRatio: 0.01,
			warningRebufferingRatio: 0.02,
			criticalRebufferingRatio: 0.05,
			maxBufferingDuration: 8.0,
			maxBufferingEventsPerMinute: 2,
			warningMemoryMB: 100.0,
			criticalMemoryMB: 200.0
		)

		XCTAssertEqual(sut.acceptableStartupTime, 1.0)
		XCTAssertEqual(sut.warningStartupTime, 2.0)
		XCTAssertEqual(sut.criticalStartupTime, 4.0)
		XCTAssertEqual(sut.acceptableRebufferingRatio, 0.01)
		XCTAssertEqual(sut.warningRebufferingRatio, 0.02)
		XCTAssertEqual(sut.criticalRebufferingRatio, 0.05)
		XCTAssertEqual(sut.maxBufferingDuration, 8.0)
		XCTAssertEqual(sut.maxBufferingEventsPerMinute, 2)
		XCTAssertEqual(sut.warningMemoryMB, 100.0)
		XCTAssertEqual(sut.criticalMemoryMB, 200.0)
	}

	// MARK: - Default Thresholds Tests

	func test_default_hasExpectedStartupTimes() {
		let sut = PerformanceThresholds.default

		XCTAssertEqual(sut.acceptableStartupTime, 2.0)
		XCTAssertEqual(sut.warningStartupTime, 4.0)
		XCTAssertEqual(sut.criticalStartupTime, 8.0)
	}

	func test_default_hasExpectedRebufferingRatios() {
		let sut = PerformanceThresholds.default

		XCTAssertEqual(sut.acceptableRebufferingRatio, 0.01)
		XCTAssertEqual(sut.warningRebufferingRatio, 0.03)
		XCTAssertEqual(sut.criticalRebufferingRatio, 0.05)
	}

	func test_default_hasExpectedBufferingLimits() {
		let sut = PerformanceThresholds.default

		XCTAssertEqual(sut.maxBufferingDuration, 10.0)
		XCTAssertEqual(sut.maxBufferingEventsPerMinute, 3)
	}

	func test_default_hasExpectedMemoryThresholds() {
		let sut = PerformanceThresholds.default

		XCTAssertEqual(sut.warningMemoryMB, 150.0)
		XCTAssertEqual(sut.criticalMemoryMB, 250.0)
	}

	// MARK: - Strict Streaming Thresholds Tests

	func test_strictStreaming_hasLowerStartupTimes() {
		let sut = PerformanceThresholds.strictStreaming

		XCTAssertEqual(sut.acceptableStartupTime, 1.5)
		XCTAssertEqual(sut.warningStartupTime, 3.0)
		XCTAssertEqual(sut.criticalStartupTime, 5.0)
	}

	func test_strictStreaming_hasLowerRebufferingRatios() {
		let sut = PerformanceThresholds.strictStreaming

		XCTAssertEqual(sut.acceptableRebufferingRatio, 0.005)
		XCTAssertEqual(sut.warningRebufferingRatio, 0.02)
		XCTAssertEqual(sut.criticalRebufferingRatio, 0.03)
	}

	func test_strictStreaming_hasLowerBufferingLimits() {
		let sut = PerformanceThresholds.strictStreaming

		XCTAssertEqual(sut.maxBufferingDuration, 5.0)
		XCTAssertEqual(sut.maxBufferingEventsPerMinute, 2)
	}

	func test_strictStreaming_hasLowerMemoryThresholds() {
		let sut = PerformanceThresholds.strictStreaming

		XCTAssertEqual(sut.warningMemoryMB, 100.0)
		XCTAssertEqual(sut.criticalMemoryMB, 200.0)
	}

	// MARK: - Equality Tests

	func test_equality() {
		let thresholds1 = PerformanceThresholds.default
		let thresholds2 = PerformanceThresholds.default

		XCTAssertEqual(thresholds1, thresholds2)
	}

	func test_inequality() {
		XCTAssertNotEqual(PerformanceThresholds.default, PerformanceThresholds.strictStreaming)
	}

	// MARK: - Sendable Tests

	func test_performanceThresholds_isSendable() {
		let thresholds: any Sendable = PerformanceThresholds.default
		XCTAssertNotNil(thresholds)
	}
}
