//
//  NetworkBandwidthEstimatorTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCoreiOS

@MainActor
final class NetworkBandwidthEstimatorTests: XCTestCase {

	// MARK: - Initial State

	func test_init_startsWithEmptyEstimate() {
		let sut = makeSUT()

		XCTAssertEqual(sut.currentEstimate, .empty)
	}

	func test_init_startsWithNoSamples() {
		let sut = makeSUT()

		XCTAssertEqual(sut.sampleCount, 0)
	}

	// MARK: - Recording Samples

	func test_recordSample_incrementsSampleCount() {
		let sut = makeSUT()
		let sample = makeSample(bytesTransferred: 1_000_000, duration: 1.0)

		sut.recordSample(sample)

		XCTAssertEqual(sut.sampleCount, 1)
	}

	func test_recordSample_multipleTimesIncrementsSampleCount() {
		let sut = makeSUT()

		sut.recordSample(makeSample())
		sut.recordSample(makeSample())
		sut.recordSample(makeSample())

		XCTAssertEqual(sut.sampleCount, 3)
	}

	// MARK: - Estimate Calculation

	func test_currentEstimate_afterSingleSample_calculatesCorrectAverage() {
		let sut = makeSUT()
		// 1,000,000 bytes in 1 second = 8,000,000 bps
		sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))

		XCTAssertEqual(sut.currentEstimate.averageBandwidthBps, 8_000_000)
	}

	func test_currentEstimate_afterMultipleSamples_calculatesCorrectAverage() {
		let sut = makeSUT()
		// Sample 1: 1,000,000 bytes / 1 sec = 8,000,000 bps
		sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))
		// Sample 2: 2,000,000 bytes / 1 sec = 16,000,000 bps
		sut.recordSample(makeSample(bytesTransferred: 2_000_000, duration: 1.0))

		// Average: (8,000,000 + 16,000,000) / 2 = 12,000,000 bps
		XCTAssertEqual(sut.currentEstimate.averageBandwidthBps, 12_000_000)
	}

	func test_currentEstimate_tracksPeakBandwidth() {
		let sut = makeSUT()
		sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0)) // 8 Mbps
		sut.recordSample(makeSample(bytesTransferred: 2_000_000, duration: 1.0)) // 16 Mbps
		sut.recordSample(makeSample(bytesTransferred: 500_000, duration: 1.0))   // 4 Mbps

		XCTAssertEqual(sut.currentEstimate.peakBandwidthBps, 16_000_000)
	}

	func test_currentEstimate_tracksMinimumBandwidth() {
		let sut = makeSUT()
		sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0)) // 8 Mbps
		sut.recordSample(makeSample(bytesTransferred: 2_000_000, duration: 1.0)) // 16 Mbps
		sut.recordSample(makeSample(bytesTransferred: 500_000, duration: 1.0))   // 4 Mbps

		XCTAssertEqual(sut.currentEstimate.minimumBandwidthBps, 4_000_000)
	}

	func test_currentEstimate_tracksSampleCount() {
		let sut = makeSUT()
		sut.recordSample(makeSample())
		sut.recordSample(makeSample())
		sut.recordSample(makeSample())

		XCTAssertEqual(sut.currentEstimate.sampleCount, 3)
	}

	// MARK: - Stability Calculation

	func test_currentEstimate_stableConnectionHasHighStability() {
		let sut = makeSUT()
		// All samples have same bandwidth (8 Mbps)
		for _ in 0..<5 {
			sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))
		}

		XCTAssertGreaterThan(sut.currentEstimate.stability, 0.9, "Stable connection should have high stability")
	}

	func test_currentEstimate_unstableConnectionHasLowStability() {
		let sut = makeSUT()
		// Highly variable bandwidth
		sut.recordSample(makeSample(bytesTransferred: 100_000, duration: 1.0))   // 0.8 Mbps
		sut.recordSample(makeSample(bytesTransferred: 5_000_000, duration: 1.0)) // 40 Mbps
		sut.recordSample(makeSample(bytesTransferred: 200_000, duration: 1.0))   // 1.6 Mbps
		sut.recordSample(makeSample(bytesTransferred: 4_000_000, duration: 1.0)) // 32 Mbps
		sut.recordSample(makeSample(bytesTransferred: 300_000, duration: 1.0))   // 2.4 Mbps

		XCTAssertLessThan(sut.currentEstimate.stability, 0.5, "Unstable connection should have low stability")
	}

	// MARK: - Confidence Calculation

	func test_currentEstimate_lowSampleCountHasLowConfidence() {
		let sut = makeSUT()
		sut.recordSample(makeSample())

		XCTAssertLessThan(sut.currentEstimate.confidence, 0.5, "Single sample should have low confidence")
	}

	func test_currentEstimate_highSampleCountHasHighConfidence() {
		let sut = makeSUT()
		for _ in 0..<10 {
			sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))
		}

		XCTAssertGreaterThan(sut.currentEstimate.confidence, 0.7, "Many samples should have high confidence")
	}

	// MARK: - Maximum Samples

	func test_recordSample_limitsToMaxSamples() {
		let sut = makeSUT(maxSamples: 5)

		for _ in 0..<10 {
			sut.recordSample(makeSample())
		}

		XCTAssertEqual(sut.sampleCount, 5)
	}

	func test_recordSample_removesOldestSamplesWhenFull() {
		let sut = makeSUT(maxSamples: 3)

		// Add 3 samples with 8 Mbps bandwidth
		for _ in 0..<3 {
			sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))
		}

		// Add 3 more samples with 16 Mbps bandwidth - should push out old samples
		for _ in 0..<3 {
			sut.recordSample(makeSample(bytesTransferred: 2_000_000, duration: 1.0))
		}

		// Should now have average of 16 Mbps (only new samples)
		XCTAssertEqual(sut.currentEstimate.averageBandwidthBps, 16_000_000)
	}

	// MARK: - Clear

	func test_clear_resetsToEmptyEstimate() {
		let sut = makeSUT()
		sut.recordSample(makeSample())
		sut.recordSample(makeSample())

		sut.clear()

		XCTAssertEqual(sut.currentEstimate, .empty)
	}

	func test_clear_resetsSampleCount() {
		let sut = makeSUT()
		sut.recordSample(makeSample())
		sut.recordSample(makeSample())

		sut.clear()

		XCTAssertEqual(sut.sampleCount, 0)
	}

	// MARK: - Ignores Invalid Samples

	func test_recordSample_ignoresZeroDurationSamples() {
		let sut = makeSUT()

		sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 0))

		XCTAssertEqual(sut.sampleCount, 0)
	}

	func test_recordSample_ignoresNegativeDurationSamples() {
		let sut = makeSUT()

		sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: -1.0))

		XCTAssertEqual(sut.sampleCount, 0)
	}

	func test_recordSample_ignoresZeroBytesSamples() {
		let sut = makeSUT()

		sut.recordSample(makeSample(bytesTransferred: 0, duration: 1.0))

		XCTAssertEqual(sut.sampleCount, 0)
	}

	// MARK: - Helpers

	private func makeSUT(
		maxSamples: Int = 30,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> NetworkBandwidthEstimator {
		NetworkBandwidthEstimator(maxSamples: maxSamples)
	}

	private func makeSample(
		bytesTransferred: Int64 = 1_000_000,
		duration: TimeInterval = 1.0,
		timestamp: Date = Date()
	) -> BandwidthSample {
		BandwidthSample(
			bytesTransferred: bytesTransferred,
			duration: duration,
			timestamp: timestamp
		)
	}
}
