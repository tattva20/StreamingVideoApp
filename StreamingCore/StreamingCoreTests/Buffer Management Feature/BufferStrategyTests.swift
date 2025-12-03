//
//  BufferStrategyTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class BufferStrategyTests: XCTestCase {

	// MARK: - Raw Value Tests

	func test_rawValues_areInCorrectOrder() {
		XCTAssertEqual(BufferStrategy.minimal.rawValue, 0)
		XCTAssertEqual(BufferStrategy.conservative.rawValue, 1)
		XCTAssertEqual(BufferStrategy.balanced.rawValue, 2)
		XCTAssertEqual(BufferStrategy.aggressive.rawValue, 3)
	}

	// MARK: - Comparable Tests

	func test_minimal_isLessThanConservative() {
		XCTAssertTrue(BufferStrategy.minimal < BufferStrategy.conservative)
	}

	func test_conservative_isLessThanBalanced() {
		XCTAssertTrue(BufferStrategy.conservative < BufferStrategy.balanced)
	}

	func test_balanced_isLessThanAggressive() {
		XCTAssertTrue(BufferStrategy.balanced < BufferStrategy.aggressive)
	}

	func test_minimal_isLessThanAggressive() {
		XCTAssertTrue(BufferStrategy.minimal < BufferStrategy.aggressive)
	}

	func test_aggressive_isNotLessThanMinimal() {
		XCTAssertFalse(BufferStrategy.aggressive < BufferStrategy.minimal)
	}

	// MARK: - Equatable Tests

	func test_sameStrategies_areEqual() {
		XCTAssertEqual(BufferStrategy.minimal, BufferStrategy.minimal)
		XCTAssertEqual(BufferStrategy.conservative, BufferStrategy.conservative)
		XCTAssertEqual(BufferStrategy.balanced, BufferStrategy.balanced)
		XCTAssertEqual(BufferStrategy.aggressive, BufferStrategy.aggressive)
	}

	func test_differentStrategies_areNotEqual() {
		XCTAssertNotEqual(BufferStrategy.minimal, BufferStrategy.conservative)
		XCTAssertNotEqual(BufferStrategy.balanced, BufferStrategy.aggressive)
	}

	// MARK: - CaseIterable Tests

	func test_allCases_containsAllStrategies() {
		let allCases = BufferStrategy.allCases

		XCTAssertEqual(allCases.count, 4)
		XCTAssertTrue(allCases.contains(.minimal))
		XCTAssertTrue(allCases.contains(.conservative))
		XCTAssertTrue(allCases.contains(.balanced))
		XCTAssertTrue(allCases.contains(.aggressive))
	}

	func test_allCases_areInAscendingOrder() {
		let allCases = BufferStrategy.allCases

		for i in 0..<allCases.count - 1 {
			XCTAssertTrue(allCases[i] < allCases[i + 1])
		}
	}

	// MARK: - Description Tests

	func test_description_providesHumanReadableString() {
		XCTAssertEqual(BufferStrategy.minimal.description, "Minimal (memory critical)")
		XCTAssertEqual(BufferStrategy.conservative.description, "Conservative (low resources)")
		XCTAssertEqual(BufferStrategy.balanced.description, "Balanced (normal)")
		XCTAssertEqual(BufferStrategy.aggressive.description, "Aggressive (optimal conditions)")
	}

	// MARK: - Sendable Tests

	func test_bufferStrategy_isSendable() {
		let strategy: any Sendable = BufferStrategy.balanced
		XCTAssertNotNil(strategy)
	}
}
