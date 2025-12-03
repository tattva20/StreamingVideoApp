//
//  BufferConfigurationTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class BufferConfigurationTests: XCTestCase {

	// MARK: - Initialization Tests

	func test_init_setsAllProperties() {
		let sut = BufferConfiguration(
			strategy: .balanced,
			preferredForwardBufferDuration: 15.0,
			reason: "Test configuration"
		)

		XCTAssertEqual(sut.strategy, .balanced)
		XCTAssertEqual(sut.preferredForwardBufferDuration, 15.0)
		XCTAssertEqual(sut.reason, "Test configuration")
	}

	// MARK: - Preset Configuration Tests

	func test_minimal_hasCorrectValues() {
		let sut = BufferConfiguration.minimal

		XCTAssertEqual(sut.strategy, .minimal)
		XCTAssertEqual(sut.preferredForwardBufferDuration, 2.0)
		XCTAssertEqual(sut.reason, "Memory critical - minimal buffering")
	}

	func test_conservative_hasCorrectValues() {
		let sut = BufferConfiguration.conservative

		XCTAssertEqual(sut.strategy, .conservative)
		XCTAssertEqual(sut.preferredForwardBufferDuration, 5.0)
		XCTAssertEqual(sut.reason, "Limited resources - conservative buffering")
	}

	func test_balanced_hasCorrectValues() {
		let sut = BufferConfiguration.balanced

		XCTAssertEqual(sut.strategy, .balanced)
		XCTAssertEqual(sut.preferredForwardBufferDuration, 10.0)
		XCTAssertEqual(sut.reason, "Normal conditions - balanced buffering")
	}

	func test_aggressive_hasCorrectValues() {
		let sut = BufferConfiguration.aggressive

		XCTAssertEqual(sut.strategy, .aggressive)
		XCTAssertEqual(sut.preferredForwardBufferDuration, 30.0)
		XCTAssertEqual(sut.reason, "Optimal conditions - aggressive buffering")
	}

	// MARK: - Buffer Duration Ordering Tests

	func test_presets_haveIncreasingBufferDurations() {
		XCTAssertLessThan(
			BufferConfiguration.minimal.preferredForwardBufferDuration,
			BufferConfiguration.conservative.preferredForwardBufferDuration
		)
		XCTAssertLessThan(
			BufferConfiguration.conservative.preferredForwardBufferDuration,
			BufferConfiguration.balanced.preferredForwardBufferDuration
		)
		XCTAssertLessThan(
			BufferConfiguration.balanced.preferredForwardBufferDuration,
			BufferConfiguration.aggressive.preferredForwardBufferDuration
		)
	}

	// MARK: - Equatable Tests

	func test_equality_returnsTrueForIdenticalConfigurations() {
		let config1 = BufferConfiguration(
			strategy: .balanced,
			preferredForwardBufferDuration: 10.0,
			reason: "Test"
		)
		let config2 = BufferConfiguration(
			strategy: .balanced,
			preferredForwardBufferDuration: 10.0,
			reason: "Test"
		)

		XCTAssertEqual(config1, config2)
	}

	func test_equality_returnsFalseForDifferentStrategies() {
		let config1 = BufferConfiguration(
			strategy: .balanced,
			preferredForwardBufferDuration: 10.0,
			reason: "Test"
		)
		let config2 = BufferConfiguration(
			strategy: .aggressive,
			preferredForwardBufferDuration: 10.0,
			reason: "Test"
		)

		XCTAssertNotEqual(config1, config2)
	}

	func test_equality_returnsFalseForDifferentBufferDurations() {
		let config1 = BufferConfiguration(
			strategy: .balanced,
			preferredForwardBufferDuration: 10.0,
			reason: "Test"
		)
		let config2 = BufferConfiguration(
			strategy: .balanced,
			preferredForwardBufferDuration: 15.0,
			reason: "Test"
		)

		XCTAssertNotEqual(config1, config2)
	}

	func test_equality_returnsFalseForDifferentReasons() {
		let config1 = BufferConfiguration(
			strategy: .balanced,
			preferredForwardBufferDuration: 10.0,
			reason: "Reason A"
		)
		let config2 = BufferConfiguration(
			strategy: .balanced,
			preferredForwardBufferDuration: 10.0,
			reason: "Reason B"
		)

		XCTAssertNotEqual(config1, config2)
	}

	// MARK: - Sendable Tests

	func test_bufferConfiguration_isSendable() {
		let config: any Sendable = BufferConfiguration.balanced
		XCTAssertNotNil(config)
	}
}
