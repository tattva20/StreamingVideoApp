//
//  LogLevelTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

final class LogLevelTests: XCTestCase {

	// MARK: - Raw Values

	func test_debug_hasRawValueZero() {
		XCTAssertEqual(LogLevel.debug.rawValue, 0)
	}

	func test_info_hasRawValueOne() {
		XCTAssertEqual(LogLevel.info.rawValue, 1)
	}

	func test_warning_hasRawValueTwo() {
		XCTAssertEqual(LogLevel.warning.rawValue, 2)
	}

	func test_error_hasRawValueThree() {
		XCTAssertEqual(LogLevel.error.rawValue, 3)
	}

	func test_critical_hasRawValueFour() {
		XCTAssertEqual(LogLevel.critical.rawValue, 4)
	}

	// MARK: - Comparable

	func test_debug_isLessThanInfo() {
		XCTAssertLessThan(LogLevel.debug, LogLevel.info)
	}

	func test_info_isLessThanWarning() {
		XCTAssertLessThan(LogLevel.info, LogLevel.warning)
	}

	func test_warning_isLessThanError() {
		XCTAssertLessThan(LogLevel.warning, LogLevel.error)
	}

	func test_error_isLessThanCritical() {
		XCTAssertLessThan(LogLevel.error, LogLevel.critical)
	}

	func test_critical_isGreaterThanAllOtherLevels() {
		XCTAssertGreaterThan(LogLevel.critical, LogLevel.debug)
		XCTAssertGreaterThan(LogLevel.critical, LogLevel.info)
		XCTAssertGreaterThan(LogLevel.critical, LogLevel.warning)
		XCTAssertGreaterThan(LogLevel.critical, LogLevel.error)
	}

	// MARK: - Equatable

	func test_sameLevels_areEqual() {
		XCTAssertEqual(LogLevel.debug, LogLevel.debug)
		XCTAssertEqual(LogLevel.info, LogLevel.info)
		XCTAssertEqual(LogLevel.warning, LogLevel.warning)
		XCTAssertEqual(LogLevel.error, LogLevel.error)
		XCTAssertEqual(LogLevel.critical, LogLevel.critical)
	}

	func test_differentLevels_areNotEqual() {
		XCTAssertNotEqual(LogLevel.debug, LogLevel.info)
		XCTAssertNotEqual(LogLevel.info, LogLevel.warning)
		XCTAssertNotEqual(LogLevel.warning, LogLevel.error)
		XCTAssertNotEqual(LogLevel.error, LogLevel.critical)
	}

	// MARK: - Codable

	func test_encodesAndDecodesCorrectly() throws {
		let levels: [LogLevel] = [.debug, .info, .warning, .error, .critical]

		for level in levels {
			let encoded = try JSONEncoder().encode(level)
			let decoded = try JSONDecoder().decode(LogLevel.self, from: encoded)
			XCTAssertEqual(decoded, level)
		}
	}

	// MARK: - Sendable

	func test_canBeSentAcrossConcurrencyBoundaries() async {
		let level = LogLevel.info

		let result = await Task.detached {
			return level
		}.value

		XCTAssertEqual(result, level)
	}
}
