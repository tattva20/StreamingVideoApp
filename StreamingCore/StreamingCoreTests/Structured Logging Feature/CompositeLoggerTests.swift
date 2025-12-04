//
//  CompositeLoggerTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

final class CompositeLoggerTests: XCTestCase {

	// MARK: - Initialization

	func test_init_setsMinimumLevel() {
		let sut = CompositeLogger(loggers: [], minimumLevel: .warning)

		XCTAssertEqual(sut.minimumLevel, .warning)
	}

	func test_init_defaultsMinimumLevelToDebug() {
		let sut = CompositeLogger(loggers: [])

		XCTAssertEqual(sut.minimumLevel, .debug)
	}

	// MARK: - Forwarding

	func test_log_forwardsToAllLoggers() {
		let logger1 = LoggerSpy()
		let logger2 = LoggerSpy()
		let sut = CompositeLogger(loggers: [logger1, logger2])
		let entry = makeEntry(level: .info)

		sut.log(entry)

		XCTAssertEqual(logger1.loggedEntries.count, 1)
		XCTAssertEqual(logger2.loggedEntries.count, 1)
	}

	func test_log_filtersBasedOnCompositeMinimumLevel() {
		let logger = LoggerSpy(minimumLevel: .debug)
		let sut = CompositeLogger(loggers: [logger], minimumLevel: .warning)
		let entry = makeEntry(level: .debug)

		sut.log(entry)

		XCTAssertTrue(logger.loggedEntries.isEmpty)
	}

	func test_log_respectsIndividualLoggerMinimumLevels() {
		let debugLogger = LoggerSpy(minimumLevel: .debug)
		let errorLogger = LoggerSpy(minimumLevel: .error)
		let sut = CompositeLogger(loggers: [debugLogger, errorLogger])
		let entry = makeEntry(level: .info)

		sut.log(entry)

		XCTAssertEqual(debugLogger.loggedEntries.count, 1)
		XCTAssertTrue(errorLogger.loggedEntries.isEmpty)
	}

	// MARK: - Empty Loggers

	func test_log_handlesEmptyLoggersList() {
		let sut = CompositeLogger(loggers: [])
		let entry = makeEntry(level: .info)

		// Should not crash
		sut.log(entry)
	}

	// MARK: - Concurrent Logging

	func test_log_handlesConcurrentLogsToDifferentLoggers() {
		let loggers = (0..<5).map { _ in LoggerSpy() }
		let sut = CompositeLogger(loggers: loggers)

		for i in 0..<20 {
			sut.log(self.makeEntry(level: .info, message: "Message \(i)"))
		}

		for logger in loggers {
			XCTAssertEqual(logger.loggedEntries.count, 20)
		}
	}

	// MARK: - Level Filtering

	func test_log_passesEntriesAtMinimumLevel() {
		let logger = LoggerSpy()
		let sut = CompositeLogger(loggers: [logger], minimumLevel: .warning)
		let entry = makeEntry(level: .warning)

		sut.log(entry)

		XCTAssertEqual(logger.loggedEntries.count, 1)
	}

	func test_log_passesEntriesAboveMinimumLevel() {
		let logger = LoggerSpy()
		let sut = CompositeLogger(loggers: [logger], minimumLevel: .warning)
		let entry = makeEntry(level: .critical)

		sut.log(entry)

		XCTAssertEqual(logger.loggedEntries.count, 1)
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
