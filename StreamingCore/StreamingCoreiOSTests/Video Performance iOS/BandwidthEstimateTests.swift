//
//  BandwidthEstimateTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCoreiOS

final class BandwidthEstimateTests: XCTestCase {

	// MARK: - Initialization

	func test_init_setsAllProperties() {
		let sut = makeSUT(
			averageBandwidthBps: 10_000_000,
			peakBandwidthBps: 15_000_000,
			minimumBandwidthBps: 5_000_000,
			stability: 0.8,
			confidence: 0.9,
			sampleCount: 10
		)

		XCTAssertEqual(sut.averageBandwidthBps, 10_000_000)
		XCTAssertEqual(sut.peakBandwidthBps, 15_000_000)
		XCTAssertEqual(sut.minimumBandwidthBps, 5_000_000)
		XCTAssertEqual(sut.stability, 0.8)
		XCTAssertEqual(sut.confidence, 0.9)
		XCTAssertEqual(sut.sampleCount, 10)
	}

	// MARK: - Recommended Max Bitrate

	func test_recommendedMaxBitrate_returns70PercentOfMinimum() {
		let sut = makeSUT(minimumBandwidthBps: 10_000_000)

		// 10,000,000 * 0.7 = 7,000,000
		XCTAssertEqual(sut.recommendedMaxBitrate, 7_000_000)
	}

	func test_recommendedMaxBitrate_returns70Percent_forHighBandwidth() {
		let sut = makeSUT(minimumBandwidthBps: 50_000_000)

		// 50,000,000 * 0.7 = 35,000,000
		XCTAssertEqual(sut.recommendedMaxBitrate, 35_000_000)
	}

	func test_recommendedMaxBitrate_returnsZero_forZeroBandwidth() {
		let sut = makeSUT(minimumBandwidthBps: 0)

		XCTAssertEqual(sut.recommendedMaxBitrate, 0)
	}

	// MARK: - Average Megabits Per Second

	func test_averageMegabitsPerSecond_calculatesCorrectly() {
		let sut = makeSUT(averageBandwidthBps: 10_000_000)

		XCTAssertEqual(sut.averageMegabitsPerSecond, 10.0)
	}

	func test_averageMegabitsPerSecond_calculatesCorrectly_forFractionalValues() {
		let sut = makeSUT(averageBandwidthBps: 5_500_000)

		XCTAssertEqual(sut.averageMegabitsPerSecond, 5.5)
	}

	// MARK: - Is Reliable

	func test_isReliable_returnsTrueForHighConfidenceAndStability() {
		let sut = makeSUT(stability: 0.8, confidence: 0.8, sampleCount: 5)

		XCTAssertTrue(sut.isReliable)
	}

	func test_isReliable_returnsFalseForLowConfidence() {
		let sut = makeSUT(stability: 0.8, confidence: 0.4, sampleCount: 5)

		XCTAssertFalse(sut.isReliable)
	}

	func test_isReliable_returnsFalseForLowStability() {
		let sut = makeSUT(stability: 0.4, confidence: 0.8, sampleCount: 5)

		XCTAssertFalse(sut.isReliable)
	}

	func test_isReliable_returnsFalseForLowSampleCount() {
		let sut = makeSUT(stability: 0.8, confidence: 0.8, sampleCount: 2)

		XCTAssertFalse(sut.isReliable)
	}

	// MARK: - Equatable

	func test_equality_returnsTrueForSameValues() {
		let sut1 = makeSUT(averageBandwidthBps: 10_000_000)
		let sut2 = makeSUT(averageBandwidthBps: 10_000_000)

		XCTAssertEqual(sut1, sut2)
	}

	func test_equality_returnsFalseForDifferentValues() {
		let sut1 = makeSUT(averageBandwidthBps: 10_000_000)
		let sut2 = makeSUT(averageBandwidthBps: 20_000_000)

		XCTAssertNotEqual(sut1, sut2)
	}

	// MARK: - Empty Estimate

	func test_empty_returnsEstimateWithZeroValues() {
		let sut = BandwidthEstimate.empty

		XCTAssertEqual(sut.averageBandwidthBps, 0)
		XCTAssertEqual(sut.peakBandwidthBps, 0)
		XCTAssertEqual(sut.minimumBandwidthBps, 0)
		XCTAssertEqual(sut.stability, 0)
		XCTAssertEqual(sut.confidence, 0)
		XCTAssertEqual(sut.sampleCount, 0)
	}

	// MARK: - Helpers

	private func makeSUT(
		averageBandwidthBps: Double = 10_000_000,
		peakBandwidthBps: Double = 15_000_000,
		minimumBandwidthBps: Double = 5_000_000,
		stability: Double = 0.8,
		confidence: Double = 0.9,
		sampleCount: Int = 10,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> BandwidthEstimate {
		let sut = BandwidthEstimate(
			averageBandwidthBps: averageBandwidthBps,
			peakBandwidthBps: peakBandwidthBps,
			minimumBandwidthBps: minimumBandwidthBps,
			stability: stability,
			confidence: confidence,
			sampleCount: sampleCount
		)
		return sut
	}
}
