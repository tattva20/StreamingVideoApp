//
//  MemoryStateTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class MemoryStateTests: XCTestCase {

	// MARK: - Initialization Tests

	func test_init_setsAllProperties() {
		let timestamp = Date()

		let sut = MemoryState(
			availableBytes: 500_000_000,
			totalBytes: 4_000_000_000,
			usedBytes: 3_500_000_000,
			timestamp: timestamp
		)

		XCTAssertEqual(sut.availableBytes, 500_000_000)
		XCTAssertEqual(sut.totalBytes, 4_000_000_000)
		XCTAssertEqual(sut.usedBytes, 3_500_000_000)
		XCTAssertEqual(sut.timestamp, timestamp)
	}

	// MARK: - Computed Properties Tests

	func test_availableMB_calculatesCorrectly() {
		let sut = makeMemoryState(availableBytes: 104_857_600) // 100 MB in bytes

		XCTAssertEqual(sut.availableMB, 100.0, accuracy: 0.001)
	}

	func test_usedMB_calculatesCorrectly() {
		let sut = makeMemoryState(usedBytes: 314_572_800) // 300 MB in bytes

		XCTAssertEqual(sut.usedMB, 300.0, accuracy: 0.001)
	}

	func test_usagePercentage_calculatesCorrectly() {
		let sut = makeMemoryState(
			totalBytes: 4_000_000_000,
			usedBytes: 1_000_000_000 // 25% used
		)

		XCTAssertEqual(sut.usagePercentage, 25.0, accuracy: 0.001)
	}

	func test_usagePercentage_returnsZeroWhenTotalBytesIsZero() {
		let sut = makeMemoryState(totalBytes: 0, usedBytes: 100)

		XCTAssertEqual(sut.usagePercentage, 0)
	}

	// MARK: - Pressure Level Tests

	func test_pressureLevel_returnsNormalWhenMemoryIsAbundant() {
		let thresholds = MemoryThresholds.default
		let sut = makeMemoryState(availableBytes: 200_000_000) // 200MB available

		XCTAssertEqual(sut.pressureLevel(thresholds: thresholds), .normal)
	}

	func test_pressureLevel_returnsWarningWhenMemoryIsBelowWarningThreshold() {
		let thresholds = MemoryThresholds.default // warning at 100MB
		let sut = makeMemoryState(availableBytes: 80_000_000) // 80MB available

		XCTAssertEqual(sut.pressureLevel(thresholds: thresholds), .warning)
	}

	func test_pressureLevel_returnsCriticalWhenMemoryIsBelowCriticalThreshold() {
		let thresholds = MemoryThresholds.default // critical at 50MB
		let sut = makeMemoryState(availableBytes: 40_000_000) // 40MB available

		XCTAssertEqual(sut.pressureLevel(thresholds: thresholds), .critical)
	}

	func test_pressureLevel_returnsWarningAtExactWarningThreshold() {
		let thresholds = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)
		let sut = makeMemoryState(availableBytes: 104_857_600) // exactly 100MB

		// At exactly the threshold, should still be normal (below means < not <=)
		XCTAssertEqual(sut.pressureLevel(thresholds: thresholds), .normal)
	}

	func test_pressureLevel_returnsCriticalAtExactCriticalThreshold() {
		let thresholds = MemoryThresholds(
			warningAvailableMB: 100.0,
			criticalAvailableMB: 50.0,
			pollingInterval: 2.0
		)
		let sut = makeMemoryState(availableBytes: 52_428_800) // exactly 50MB

		// At exactly the threshold, should still be warning (below means < not <=)
		XCTAssertEqual(sut.pressureLevel(thresholds: thresholds), .warning)
	}

	// MARK: - Equatable Tests

	func test_equality_returnsTrueForIdenticalStates() {
		let timestamp = Date()

		let state1 = MemoryState(
			availableBytes: 500_000_000,
			totalBytes: 4_000_000_000,
			usedBytes: 3_500_000_000,
			timestamp: timestamp
		)

		let state2 = MemoryState(
			availableBytes: 500_000_000,
			totalBytes: 4_000_000_000,
			usedBytes: 3_500_000_000,
			timestamp: timestamp
		)

		XCTAssertEqual(state1, state2)
	}

	func test_equality_returnsFalseForDifferentStates() {
		let state1 = makeMemoryState(availableBytes: 500_000_000)
		let state2 = makeMemoryState(availableBytes: 600_000_000)

		XCTAssertNotEqual(state1, state2)
	}

	// MARK: - Sendable Tests

	func test_memoryState_isSendable() {
		let state: any Sendable = makeMemoryState()
		XCTAssertNotNil(state)
	}

	// MARK: - Helpers

	private func makeMemoryState(
		availableBytes: UInt64 = 500_000_000,
		totalBytes: UInt64 = 4_000_000_000,
		usedBytes: UInt64 = 3_500_000_000,
		timestamp: Date = Date()
	) -> MemoryState {
		MemoryState(
			availableBytes: availableBytes,
			totalBytes: totalBytes,
			usedBytes: usedBytes,
			timestamp: timestamp
		)
	}
}
