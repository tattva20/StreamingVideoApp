//
//  PerformanceEventTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PerformanceEventTests: XCTestCase {

	// MARK: - PerformanceEvent Tests

	func test_loadStarted_isEqualToSameCase() {
		XCTAssertEqual(PerformanceEvent.loadStarted, PerformanceEvent.loadStarted)
	}

	func test_firstFrameRendered_isEqualToSameCase() {
		XCTAssertEqual(PerformanceEvent.firstFrameRendered, PerformanceEvent.firstFrameRendered)
	}

	func test_bufferingStarted_isEqualToSameCase() {
		XCTAssertEqual(PerformanceEvent.bufferingStarted, PerformanceEvent.bufferingStarted)
	}

	func test_bufferingEnded_isEqualWithSameDuration() {
		let duration: TimeInterval = 2.5
		XCTAssertEqual(
			PerformanceEvent.bufferingEnded(duration: duration),
			PerformanceEvent.bufferingEnded(duration: duration)
		)
	}

	func test_bufferingEnded_isNotEqualWithDifferentDuration() {
		XCTAssertNotEqual(
			PerformanceEvent.bufferingEnded(duration: 2.5),
			PerformanceEvent.bufferingEnded(duration: 3.0)
		)
	}

	func test_playbackStalled_isEqualToSameCase() {
		XCTAssertEqual(PerformanceEvent.playbackStalled, PerformanceEvent.playbackStalled)
	}

	func test_playbackResumed_isEqualToSameCase() {
		XCTAssertEqual(PerformanceEvent.playbackResumed, PerformanceEvent.playbackResumed)
	}

	func test_qualityChanged_isEqualWithSameBitrate() {
		let bitrate = 3_000_000
		XCTAssertEqual(
			PerformanceEvent.qualityChanged(bitrate: bitrate),
			PerformanceEvent.qualityChanged(bitrate: bitrate)
		)
	}

	func test_qualityChanged_isNotEqualWithDifferentBitrate() {
		XCTAssertNotEqual(
			PerformanceEvent.qualityChanged(bitrate: 3_000_000),
			PerformanceEvent.qualityChanged(bitrate: 6_000_000)
		)
	}

	func test_memoryWarning_isEqualWithSameLevel() {
		XCTAssertEqual(
			PerformanceEvent.memoryWarning(level: .warning),
			PerformanceEvent.memoryWarning(level: .warning)
		)
	}

	func test_memoryWarning_isNotEqualWithDifferentLevel() {
		XCTAssertNotEqual(
			PerformanceEvent.memoryWarning(level: .warning),
			PerformanceEvent.memoryWarning(level: .critical)
		)
	}

	func test_networkChanged_isEqualWithSameQuality() {
		XCTAssertEqual(
			PerformanceEvent.networkChanged(quality: .good),
			PerformanceEvent.networkChanged(quality: .good)
		)
	}

	func test_networkChanged_isNotEqualWithDifferentQuality() {
		XCTAssertNotEqual(
			PerformanceEvent.networkChanged(quality: .good),
			PerformanceEvent.networkChanged(quality: .poor)
		)
	}

	func test_bytesTransferred_isEqualWithSameValues() {
		XCTAssertEqual(
			PerformanceEvent.bytesTransferred(bytes: 1024, duration: 1.0),
			PerformanceEvent.bytesTransferred(bytes: 1024, duration: 1.0)
		)
	}

	func test_bytesTransferred_isNotEqualWithDifferentBytes() {
		XCTAssertNotEqual(
			PerformanceEvent.bytesTransferred(bytes: 1024, duration: 1.0),
			PerformanceEvent.bytesTransferred(bytes: 2048, duration: 1.0)
		)
	}

	func test_bytesTransferred_isNotEqualWithDifferentDuration() {
		XCTAssertNotEqual(
			PerformanceEvent.bytesTransferred(bytes: 1024, duration: 1.0),
			PerformanceEvent.bytesTransferred(bytes: 1024, duration: 2.0)
		)
	}

	func test_differentEventTypes_areNotEqual() {
		XCTAssertNotEqual(PerformanceEvent.loadStarted, PerformanceEvent.firstFrameRendered)
		XCTAssertNotEqual(PerformanceEvent.bufferingStarted, PerformanceEvent.playbackStalled)
		XCTAssertNotEqual(PerformanceEvent.loadStarted, PerformanceEvent.bufferingEnded(duration: 0))
	}

	// MARK: - Sendable Tests

	func test_performanceEvent_isSendable() {
		let event: any Sendable = PerformanceEvent.loadStarted
		XCTAssertNotNil(event)
	}

	// MARK: - MemoryPressureLevel Tests

	func test_memoryPressureLevel_comparable() {
		XCTAssertTrue(MemoryPressureLevel.normal < MemoryPressureLevel.warning)
		XCTAssertTrue(MemoryPressureLevel.warning < MemoryPressureLevel.critical)
		XCTAssertTrue(MemoryPressureLevel.normal < MemoryPressureLevel.critical)
	}

	func test_memoryPressureLevel_equality() {
		XCTAssertEqual(MemoryPressureLevel.normal, MemoryPressureLevel.normal)
		XCTAssertEqual(MemoryPressureLevel.warning, MemoryPressureLevel.warning)
		XCTAssertEqual(MemoryPressureLevel.critical, MemoryPressureLevel.critical)
	}

	// MARK: - NetworkQuality Tests

	func test_networkQuality_comparable() {
		XCTAssertTrue(NetworkQuality.offline < NetworkQuality.poor)
		XCTAssertTrue(NetworkQuality.poor < NetworkQuality.fair)
		XCTAssertTrue(NetworkQuality.fair < NetworkQuality.good)
		XCTAssertTrue(NetworkQuality.good < NetworkQuality.excellent)
	}

	func test_networkQuality_equality() {
		XCTAssertEqual(NetworkQuality.excellent, NetworkQuality.excellent)
		XCTAssertEqual(NetworkQuality.good, NetworkQuality.good)
		XCTAssertEqual(NetworkQuality.fair, NetworkQuality.fair)
		XCTAssertEqual(NetworkQuality.poor, NetworkQuality.poor)
		XCTAssertEqual(NetworkQuality.offline, NetworkQuality.offline)
	}
}
