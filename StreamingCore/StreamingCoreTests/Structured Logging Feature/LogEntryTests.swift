//
//  LogEntryTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

final class LogEntryTests: XCTestCase {

	// MARK: - Initialization

	func test_init_storesAllProperties() {
		let id = UUID()
		let timestamp = Date()
		let level = LogLevel.info
		let message = "Test message"
		let context = LogContext(file: "test.swift", function: "test()", line: 42)

		let entry = LogEntry(
			id: id,
			timestamp: timestamp,
			level: level,
			message: message,
			context: context
		)

		XCTAssertEqual(entry.id, id)
		XCTAssertEqual(entry.timestamp, timestamp)
		XCTAssertEqual(entry.level, level)
		XCTAssertEqual(entry.message, message)
		XCTAssertEqual(entry.context, context)
	}

	func test_init_generatesDefaultIDAndTimestamp() {
		let entry = LogEntry(
			level: .debug,
			message: "Test",
			context: LogContext(file: "test.swift", function: "test()", line: 1)
		)

		XCTAssertNotNil(entry.id)
		XCTAssertNotNil(entry.timestamp)
	}

	// MARK: - Formatted Message

	func test_formattedMessage_includesLevelAndMessage() {
		let entry = makeEntry(level: .info, message: "Test message")

		XCTAssertTrue(entry.formattedMessage.contains("[info]"))
		XCTAssertTrue(entry.formattedMessage.contains("Test message"))
	}

	func test_formattedMessage_includesSubsystemWhenPresent() {
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1,
			subsystem: "VideoPlayer"
		)
		let entry = LogEntry(level: .info, message: "Test", context: context)

		XCTAssertTrue(entry.formattedMessage.contains("[VideoPlayer]"))
	}

	func test_formattedMessage_includesCorrelationIDWhenPresent() {
		let correlationID = UUID()
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1,
			correlationID: correlationID
		)
		let entry = LogEntry(level: .info, message: "Test", context: context)

		let shortID = String(correlationID.uuidString.prefix(8))
		XCTAssertTrue(entry.formattedMessage.contains("[cid:\(shortID)]"))
	}

	func test_formattedMessage_debugLevel_hasCorrectIndicator() {
		let entry = makeEntry(level: .debug)

		XCTAssertTrue(entry.formattedMessage.contains("[debug]"))
	}

	func test_formattedMessage_warningLevel_hasCorrectIndicator() {
		let entry = makeEntry(level: .warning)

		XCTAssertTrue(entry.formattedMessage.contains("[warning]"))
	}

	func test_formattedMessage_errorLevel_hasCorrectIndicator() {
		let entry = makeEntry(level: .error)

		XCTAssertTrue(entry.formattedMessage.contains("[error]"))
	}

	func test_formattedMessage_criticalLevel_hasCorrectIndicator() {
		let entry = makeEntry(level: .critical)

		XCTAssertTrue(entry.formattedMessage.contains("[critical]"))
	}

	// MARK: - Equatable

	func test_entriesWithSameValues_areEqual() {
		let id = UUID()
		let timestamp = Date()
		let context = LogContext(file: "test.swift", function: "test()", line: 1)

		let entry1 = LogEntry(id: id, timestamp: timestamp, level: .info, message: "Test", context: context)
		let entry2 = LogEntry(id: id, timestamp: timestamp, level: .info, message: "Test", context: context)

		XCTAssertEqual(entry1, entry2)
	}

	func test_entriesWithDifferentIDs_areNotEqual() {
		let context = LogContext(file: "test.swift", function: "test()", line: 1)
		let timestamp = Date()

		let entry1 = LogEntry(id: UUID(), timestamp: timestamp, level: .info, message: "Test", context: context)
		let entry2 = LogEntry(id: UUID(), timestamp: timestamp, level: .info, message: "Test", context: context)

		XCTAssertNotEqual(entry1, entry2)
	}

	// MARK: - Sendable

	func test_canBeSentAcrossConcurrencyBoundaries() async {
		let entry = makeEntry(level: .info, message: "Test")

		let result = await Task.detached {
			return entry
		}.value

		XCTAssertEqual(result.message, entry.message)
		XCTAssertEqual(result.level, entry.level)
	}

	// MARK: - Helpers

	private func makeEntry(
		level: LogLevel = .info,
		message: String = "Test message"
	) -> LogEntry {
		LogEntry(
			level: level,
			message: message,
			context: LogContext(file: "test.swift", function: "test()", line: 1)
		)
	}
}
