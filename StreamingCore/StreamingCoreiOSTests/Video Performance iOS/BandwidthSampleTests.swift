//
//  BandwidthSampleTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCoreiOS

final class BandwidthSampleTests: XCTestCase {

	// MARK: - Initialization

	func test_init_setsAllProperties() {
		let bytesTransferred: Int64 = 1_000_000
		let duration: TimeInterval = 2.0
		let timestamp = Date()

		let sut = BandwidthSample(
			bytesTransferred: bytesTransferred,
			duration: duration,
			timestamp: timestamp
		)

		XCTAssertEqual(sut.bytesTransferred, bytesTransferred)
		XCTAssertEqual(sut.duration, duration)
		XCTAssertEqual(sut.timestamp, timestamp)
	}

	// MARK: - Bits Per Second Calculation

	func test_bitsPerSecond_calculatesCorrectly_forValidDuration() {
		let sut = makeSUT(bytesTransferred: 1_000_000, duration: 1.0)

		// 1,000,000 bytes = 8,000,000 bits
		// 8,000,000 bits / 1 second = 8,000,000 bps
		XCTAssertEqual(sut.bitsPerSecond, 8_000_000.0)
	}

	func test_bitsPerSecond_calculatesCorrectly_forTwoSecondDuration() {
		let sut = makeSUT(bytesTransferred: 1_000_000, duration: 2.0)

		// 1,000,000 bytes = 8,000,000 bits
		// 8,000,000 bits / 2 seconds = 4,000,000 bps
		XCTAssertEqual(sut.bitsPerSecond, 4_000_000.0)
	}

	func test_bitsPerSecond_returnsZero_forZeroDuration() {
		let sut = makeSUT(bytesTransferred: 1_000_000, duration: 0)

		XCTAssertEqual(sut.bitsPerSecond, 0)
	}

	func test_bitsPerSecond_returnsZero_forNegativeDuration() {
		let sut = makeSUT(bytesTransferred: 1_000_000, duration: -1.0)

		XCTAssertEqual(sut.bitsPerSecond, 0)
	}

	func test_bitsPerSecond_returnsZero_forZeroBytes() {
		let sut = makeSUT(bytesTransferred: 0, duration: 1.0)

		XCTAssertEqual(sut.bitsPerSecond, 0)
	}

	// MARK: - Megabits Per Second Calculation

	func test_megabitsPerSecond_calculatesCorrectly() {
		let sut = makeSUT(bytesTransferred: 1_000_000, duration: 1.0)

		// 8,000,000 bps = 8 Mbps
		XCTAssertEqual(sut.megabitsPerSecond, 8.0)
	}

	func test_megabitsPerSecond_calculatesCorrectly_forSmallValues() {
		let sut = makeSUT(bytesTransferred: 125_000, duration: 1.0)

		// 125,000 bytes = 1,000,000 bits = 1 Mbps
		XCTAssertEqual(sut.megabitsPerSecond, 1.0)
	}

	// MARK: - Equatable

	func test_equality_returnsTrueForSameValues() {
		let timestamp = Date()
		let sut1 = BandwidthSample(bytesTransferred: 1000, duration: 1.0, timestamp: timestamp)
		let sut2 = BandwidthSample(bytesTransferred: 1000, duration: 1.0, timestamp: timestamp)

		XCTAssertEqual(sut1, sut2)
	}

	func test_equality_returnsFalseForDifferentBytes() {
		let timestamp = Date()
		let sut1 = BandwidthSample(bytesTransferred: 1000, duration: 1.0, timestamp: timestamp)
		let sut2 = BandwidthSample(bytesTransferred: 2000, duration: 1.0, timestamp: timestamp)

		XCTAssertNotEqual(sut1, sut2)
	}

	func test_equality_returnsFalseForDifferentDuration() {
		let timestamp = Date()
		let sut1 = BandwidthSample(bytesTransferred: 1000, duration: 1.0, timestamp: timestamp)
		let sut2 = BandwidthSample(bytesTransferred: 1000, duration: 2.0, timestamp: timestamp)

		XCTAssertNotEqual(sut1, sut2)
	}

	// MARK: - Helpers

	private func makeSUT(
		bytesTransferred: Int64 = 0,
		duration: TimeInterval = 1.0,
		timestamp: Date = Date(),
		file: StaticString = #filePath,
		line: UInt = #line
	) -> BandwidthSample {
		let sut = BandwidthSample(
			bytesTransferred: bytesTransferred,
			duration: duration,
			timestamp: timestamp
		)
		return sut
	}
}
