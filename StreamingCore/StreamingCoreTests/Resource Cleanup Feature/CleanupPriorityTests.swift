//
//  CleanupPriorityTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class CleanupPriorityTests: XCTestCase {

	// MARK: - Raw Value Tests

	func test_low_hasRawValue0() {
		XCTAssertEqual(CleanupPriority.low.rawValue, 0)
	}

	func test_medium_hasRawValue1() {
		XCTAssertEqual(CleanupPriority.medium.rawValue, 1)
	}

	func test_high_hasRawValue2() {
		XCTAssertEqual(CleanupPriority.high.rawValue, 2)
	}

	// MARK: - Comparable Tests

	func test_low_isLessThanMedium() {
		XCTAssertLessThan(CleanupPriority.low, CleanupPriority.medium)
	}

	func test_medium_isLessThanHigh() {
		XCTAssertLessThan(CleanupPriority.medium, CleanupPriority.high)
	}

	func test_low_isLessThanHigh() {
		XCTAssertLessThan(CleanupPriority.low, CleanupPriority.high)
	}

	func test_high_isNotLessThanMedium() {
		XCTAssertFalse(CleanupPriority.high < CleanupPriority.medium)
	}

	func test_medium_isNotLessThanLow() {
		XCTAssertFalse(CleanupPriority.medium < CleanupPriority.low)
	}

	func test_equalPriorities_areNotLessThanEachOther() {
		XCTAssertFalse(CleanupPriority.medium < CleanupPriority.medium)
	}

	// MARK: - CaseIterable Tests

	func test_allCases_containsThreePriorities() {
		XCTAssertEqual(CleanupPriority.allCases.count, 3)
	}

	func test_allCases_areInOrder() {
		let expected: [CleanupPriority] = [.low, .medium, .high]
		XCTAssertEqual(CleanupPriority.allCases, expected)
	}

	// MARK: - Sendable Tests

	func test_cleanupPriority_isSendable() {
		let priority: any Sendable = CleanupPriority.high
		XCTAssertNotNil(priority)
	}

	// MARK: - Equatable Tests

	func test_samePriorities_areEqual() {
		XCTAssertEqual(CleanupPriority.low, CleanupPriority.low)
		XCTAssertEqual(CleanupPriority.medium, CleanupPriority.medium)
		XCTAssertEqual(CleanupPriority.high, CleanupPriority.high)
	}

	func test_differentPriorities_areNotEqual() {
		XCTAssertNotEqual(CleanupPriority.low, CleanupPriority.medium)
		XCTAssertNotEqual(CleanupPriority.medium, CleanupPriority.high)
		XCTAssertNotEqual(CleanupPriority.low, CleanupPriority.high)
	}

	// MARK: - Sorting Tests

	func test_priorities_sortInAscendingOrder() {
		let unsorted: [CleanupPriority] = [.high, .low, .medium]
		let sorted = unsorted.sorted()

		XCTAssertEqual(sorted, [.low, .medium, .high])
	}

	func test_priorities_sortInDescendingOrder() {
		let unsorted: [CleanupPriority] = [.low, .high, .medium]
		let sorted = unsorted.sorted(by: >)

		XCTAssertEqual(sorted, [.high, .medium, .low])
	}
}
