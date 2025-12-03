//
//  PreloadPriorityTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PreloadPriorityTests: XCTestCase {

	// MARK: - Raw Values

	func test_rawValues_areInAscendingOrder() {
		XCTAssertEqual(PreloadPriority.low.rawValue, 0)
		XCTAssertEqual(PreloadPriority.medium.rawValue, 1)
		XCTAssertEqual(PreloadPriority.high.rawValue, 2)
		XCTAssertEqual(PreloadPriority.immediate.rawValue, 3)
	}

	// MARK: - Comparable

	func test_comparable_lowIsLessThanMedium() {
		XCTAssertTrue(PreloadPriority.low < PreloadPriority.medium)
	}

	func test_comparable_mediumIsLessThanHigh() {
		XCTAssertTrue(PreloadPriority.medium < PreloadPriority.high)
	}

	func test_comparable_highIsLessThanImmediate() {
		XCTAssertTrue(PreloadPriority.high < PreloadPriority.immediate)
	}

	func test_comparable_immediateIsNotLessThanHigh() {
		XCTAssertFalse(PreloadPriority.immediate < PreloadPriority.high)
	}

	// MARK: - Sorting

	func test_sorting_ordersCorrectly() {
		let priorities: [PreloadPriority] = [.immediate, .low, .high, .medium]

		let sorted = priorities.sorted()

		XCTAssertEqual(sorted, [.low, .medium, .high, .immediate])
	}

	// MARK: - All Cases

	func test_allCases_containsFourPriorities() {
		XCTAssertEqual(PreloadPriority.allCases.count, 4)
	}
}
