//
//  MemoryThresholdsTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class MemoryThresholdsTests: XCTestCase {

	// MARK: - Initialization Tests

	func test_init_setsAllProperties() {
		let sut = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		XCTAssertEqual(sut.warningAvailableMB, 100.0)
		XCTAssertEqual(sut.criticalAvailableMB, 50.0)
		XCTAssertEqual(sut.pollingInterval, 2.0)
	}

	// MARK: - Default Values Tests

	func test_default_hasExpectedValues() {
		let sut = MemoryThresholds.default

		XCTAssertEqual(sut.warningAvailableMB, 100.0)
		XCTAssertEqual(sut.criticalAvailableMB, 50.0)
		XCTAssertEqual(sut.pollingInterval, 2.0)
	}

	// MARK: - Pressure Level Calculation Tests

	func test_pressureLevel_returnsNormalWhenAboveWarningThreshold() {
		let sut = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		XCTAssertEqual(sut.pressureLevel(for: 150.0), .normal)
	}

	func test_pressureLevel_returnsWarningWhenBelowWarningButAboveCritical() {
		let sut = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		XCTAssertEqual(sut.pressureLevel(for: 75.0), .warning)
	}

	func test_pressureLevel_returnsCriticalWhenBelowCriticalThreshold() {
		let sut = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		XCTAssertEqual(sut.pressureLevel(for: 30.0), .critical)
	}

	func test_pressureLevel_returnsNormalAtExactWarningThreshold() {
		let sut = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		// At exactly 100MB, should still be normal (< not <=)
		XCTAssertEqual(sut.pressureLevel(for: 100.0), .normal)
	}

	func test_pressureLevel_returnsWarningAtExactCriticalThreshold() {
		let sut = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		// At exactly 50MB, should still be warning (< not <=)
		XCTAssertEqual(sut.pressureLevel(for: 50.0), .warning)
	}

	func test_pressureLevel_returnsCriticalForZeroMemory() {
		let sut = MemoryThresholds.default

		XCTAssertEqual(sut.pressureLevel(for: 0), .critical)
	}

	// MARK: - Edge Case Tests

	func test_pressureLevel_handlesNegativeMemory() {
		let sut = MemoryThresholds.default

		// Negative memory should be treated as critical
		XCTAssertEqual(sut.pressureLevel(for: -10.0), .critical)
	}

	func test_pressureLevel_handlesVeryLargeMemory() {
		let sut = MemoryThresholds.default

		XCTAssertEqual(sut.pressureLevel(for: 10_000.0), .normal)
	}

	// MARK: - Equatable Tests

	func test_equality_returnsTrueForIdenticalThresholds() {
		let thresholds1 = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		let thresholds2 = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		XCTAssertEqual(thresholds1, thresholds2)
	}

	func test_equality_returnsFalseForDifferentWarningThresholds() {
		let thresholds1 = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		let thresholds2 = MemoryThresholds(
			warningAvailableMB: 150.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)

		XCTAssertNotEqual(thresholds1, thresholds2)
	}

	// MARK: - Sendable Tests

	func test_memoryThresholds_isSendable() {
		let thresholds: any Sendable = MemoryThresholds.default
		XCTAssertNotNil(thresholds)
	}
}
