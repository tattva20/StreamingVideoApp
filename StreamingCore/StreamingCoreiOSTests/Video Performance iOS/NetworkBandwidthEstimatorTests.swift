//
//  NetworkBandwidthEstimatorTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCoreiOS

final class NetworkBandwidthEstimatorTests: XCTestCase {

	// MARK: - Initial State

	func test_init_startsWithEmptyEstimate() async {
		let sut = makeSUT()

		let estimate = await sut.currentEstimate

		XCTAssertEqual(estimate, .empty)
	}

	func test_init_startsWithNoSamples() async {
		let sut = makeSUT()

		let count = await sut.sampleCount

		XCTAssertEqual(count, 0)
	}

	// MARK: - Recording Samples

	func test_recordSample_incrementsSampleCount() async {
		let sut = makeSUT()
		let sample = makeSample(bytesTransferred: 1_000_000, duration: 1.0)

		await sut.recordSample(sample)

		let count = await sut.sampleCount
		XCTAssertEqual(count, 1)
	}

	func test_recordSample_multipleTimesIncrementsSampleCount() async {
		let sut = makeSUT()

		await sut.recordSample(makeSample())
		await sut.recordSample(makeSample())
		await sut.recordSample(makeSample())

		let count = await sut.sampleCount
		XCTAssertEqual(count, 3)
	}

	// MARK: - Estimate Calculation

	func test_currentEstimate_afterSingleSample_calculatesCorrectAverage() async {
		let sut = makeSUT()
		// 1,000,000 bytes in 1 second = 8,000,000 bps
		await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))

		let estimate = await sut.currentEstimate

		XCTAssertEqual(estimate.averageBandwidthBps, 8_000_000)
	}

	func test_currentEstimate_afterMultipleSamples_calculatesCorrectAverage() async {
		let sut = makeSUT()
		// Sample 1: 1,000,000 bytes / 1 sec = 8,000,000 bps
		await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))
		// Sample 2: 2,000,000 bytes / 1 sec = 16,000,000 bps
		await sut.recordSample(makeSample(bytesTransferred: 2_000_000, duration: 1.0))

		let estimate = await sut.currentEstimate

		// Average: (8,000,000 + 16,000,000) / 2 = 12,000,000 bps
		XCTAssertEqual(estimate.averageBandwidthBps, 12_000_000)
	}

	func test_currentEstimate_tracksPeakBandwidth() async {
		let sut = makeSUT()
		await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0)) // 8 Mbps
		await sut.recordSample(makeSample(bytesTransferred: 2_000_000, duration: 1.0)) // 16 Mbps
		await sut.recordSample(makeSample(bytesTransferred: 500_000, duration: 1.0))   // 4 Mbps

		let estimate = await sut.currentEstimate

		XCTAssertEqual(estimate.peakBandwidthBps, 16_000_000)
	}

	func test_currentEstimate_tracksMinimumBandwidth() async {
		let sut = makeSUT()
		await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0)) // 8 Mbps
		await sut.recordSample(makeSample(bytesTransferred: 2_000_000, duration: 1.0)) // 16 Mbps
		await sut.recordSample(makeSample(bytesTransferred: 500_000, duration: 1.0))   // 4 Mbps

		let estimate = await sut.currentEstimate

		XCTAssertEqual(estimate.minimumBandwidthBps, 4_000_000)
	}

	func test_currentEstimate_tracksSampleCount() async {
		let sut = makeSUT()
		await sut.recordSample(makeSample())
		await sut.recordSample(makeSample())
		await sut.recordSample(makeSample())

		let estimate = await sut.currentEstimate

		XCTAssertEqual(estimate.sampleCount, 3)
	}

	// MARK: - Stability Calculation

	func test_currentEstimate_stableConnectionHasHighStability() async {
		let sut = makeSUT()
		// All samples have same bandwidth (8 Mbps)
		for _ in 0..<5 {
			await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))
		}

		let estimate = await sut.currentEstimate

		XCTAssertGreaterThan(estimate.stability, 0.9, "Stable connection should have high stability")
	}

	func test_currentEstimate_unstableConnectionHasLowStability() async {
		let sut = makeSUT()
		// Highly variable bandwidth
		await sut.recordSample(makeSample(bytesTransferred: 100_000, duration: 1.0))   // 0.8 Mbps
		await sut.recordSample(makeSample(bytesTransferred: 5_000_000, duration: 1.0)) // 40 Mbps
		await sut.recordSample(makeSample(bytesTransferred: 200_000, duration: 1.0))   // 1.6 Mbps
		await sut.recordSample(makeSample(bytesTransferred: 4_000_000, duration: 1.0)) // 32 Mbps
		await sut.recordSample(makeSample(bytesTransferred: 300_000, duration: 1.0))   // 2.4 Mbps

		let estimate = await sut.currentEstimate

		XCTAssertLessThan(estimate.stability, 0.5, "Unstable connection should have low stability")
	}

	// MARK: - Confidence Calculation

	func test_currentEstimate_lowSampleCountHasLowConfidence() async {
		let sut = makeSUT()
		await sut.recordSample(makeSample())

		let estimate = await sut.currentEstimate

		XCTAssertLessThan(estimate.confidence, 0.5, "Single sample should have low confidence")
	}

	func test_currentEstimate_highSampleCountHasHighConfidence() async {
		let sut = makeSUT()
		for _ in 0..<10 {
			await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))
		}

		let estimate = await sut.currentEstimate

		XCTAssertGreaterThan(estimate.confidence, 0.7, "Many samples should have high confidence")
	}

	// MARK: - Maximum Samples

	func test_recordSample_limitsToMaxSamples() async {
		let sut = makeSUT(maxSamples: 5)

		for _ in 0..<10 {
			await sut.recordSample(makeSample())
		}

		let count = await sut.sampleCount
		XCTAssertEqual(count, 5)
	}

	func test_recordSample_removesOldestSamplesWhenFull() async {
		let sut = makeSUT(maxSamples: 3)

		// Add 3 samples with 8 Mbps bandwidth
		for _ in 0..<3 {
			await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 1.0))
		}

		// Add 3 more samples with 16 Mbps bandwidth - should push out old samples
		for _ in 0..<3 {
			await sut.recordSample(makeSample(bytesTransferred: 2_000_000, duration: 1.0))
		}

		let estimate = await sut.currentEstimate
		// Should now have average of 16 Mbps (only new samples)
		XCTAssertEqual(estimate.averageBandwidthBps, 16_000_000)
	}

	// MARK: - Clear

	func test_clear_resetsToEmptyEstimate() async {
		let sut = makeSUT()
		await sut.recordSample(makeSample())
		await sut.recordSample(makeSample())

		await sut.clear()

		let estimate = await sut.currentEstimate
		XCTAssertEqual(estimate, .empty)
	}

	func test_clear_resetsSampleCount() async {
		let sut = makeSUT()
		await sut.recordSample(makeSample())
		await sut.recordSample(makeSample())

		await sut.clear()

		let count = await sut.sampleCount
		XCTAssertEqual(count, 0)
	}

	// MARK: - Ignores Invalid Samples

	func test_recordSample_ignoresZeroDurationSamples() async {
		let sut = makeSUT()

		await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: 0))

		let count = await sut.sampleCount
		XCTAssertEqual(count, 0)
	}

	func test_recordSample_ignoresNegativeDurationSamples() async {
		let sut = makeSUT()

		await sut.recordSample(makeSample(bytesTransferred: 1_000_000, duration: -1.0))

		let count = await sut.sampleCount
		XCTAssertEqual(count, 0)
	}

	func test_recordSample_ignoresZeroBytesSamples() async {
		let sut = makeSUT()

		await sut.recordSample(makeSample(bytesTransferred: 0, duration: 1.0))

		let count = await sut.sampleCount
		XCTAssertEqual(count, 0)
	}

	// MARK: - Helpers

	private func makeSUT(
		maxSamples: Int = 30,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> NetworkBandwidthEstimator {
		let sut = NetworkBandwidthEstimator(maxSamples: maxSamples)
		return sut
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
