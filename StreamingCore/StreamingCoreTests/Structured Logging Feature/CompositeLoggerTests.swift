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

	func test_log_forwardsToAllLoggers() async {
		let logger1 = LoggerSpy()
		let logger2 = LoggerSpy()
		let sut = CompositeLogger(loggers: [logger1, logger2])
		let entry = makeEntry(level: .info)

		await sut.log(entry)

		let entries1 = await logger1.loggedEntries
		let entries2 = await logger2.loggedEntries
		XCTAssertEqual(entries1.count, 1)
		XCTAssertEqual(entries2.count, 1)
	}

	func test_log_filtersBasedOnCompositeMinimumLevel() async {
		let logger = LoggerSpy(minimumLevel: .debug)
		let sut = CompositeLogger(loggers: [logger], minimumLevel: .warning)
		let entry = makeEntry(level: .debug)

		await sut.log(entry)

		let entries = await logger.loggedEntries
		XCTAssertTrue(entries.isEmpty)
	}

	func test_log_respectsIndividualLoggerMinimumLevels() async {
		let debugLogger = LoggerSpy(minimumLevel: .debug)
		let errorLogger = LoggerSpy(minimumLevel: .error)
		let sut = CompositeLogger(loggers: [debugLogger, errorLogger])
		let entry = makeEntry(level: .info)

		await sut.log(entry)

		let debugEntries = await debugLogger.loggedEntries
		let errorEntries = await errorLogger.loggedEntries
		XCTAssertEqual(debugEntries.count, 1)
		XCTAssertTrue(errorEntries.isEmpty)
	}

	// MARK: - Empty Loggers

	func test_log_handlesEmptyLoggersList() async {
		let sut = CompositeLogger(loggers: [])
		let entry = makeEntry(level: .info)

		// Should not crash
		await sut.log(entry)
	}

	// MARK: - Concurrent Logging

	func test_log_handlesConcurrentLogsToDifferentLoggers() async {
		let loggers = (0..<5).map { _ in LoggerSpy() }
		let sut = CompositeLogger(loggers: loggers)

		await withTaskGroup(of: Void.self) { group in
			for i in 0..<20 {
				group.addTask {
					await sut.log(self.makeEntry(level: .info, message: "Message \(i)"))
				}
			}
		}

		for logger in loggers {
			let entries = await logger.loggedEntries
			XCTAssertEqual(entries.count, 20)
		}
	}

	// MARK: - Level Filtering

	func test_log_passesEntriesAtMinimumLevel() async {
		let logger = LoggerSpy()
		let sut = CompositeLogger(loggers: [logger], minimumLevel: .warning)
		let entry = makeEntry(level: .warning)

		await sut.log(entry)

		let entries = await logger.loggedEntries
		XCTAssertEqual(entries.count, 1)
	}

	func test_log_passesEntriesAboveMinimumLevel() async {
		let logger = LoggerSpy()
		let sut = CompositeLogger(loggers: [logger], minimumLevel: .warning)
		let entry = makeEntry(level: .critical)

		await sut.log(entry)

		let entries = await logger.loggedEntries
		XCTAssertEqual(entries.count, 1)
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
