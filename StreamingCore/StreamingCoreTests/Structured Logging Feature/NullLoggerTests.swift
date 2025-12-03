//
//  NullLoggerTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

final class NullLoggerTests: XCTestCase {

	// MARK: - Minimum Level

	func test_minimumLevel_isCritical() {
		let sut = NullLogger()

		XCTAssertEqual(sut.minimumLevel, .critical)
	}

	// MARK: - Logging

	func test_log_doesNotCrash() async {
		let sut = NullLogger()
		let entry = makeEntry(level: .info)

		// Should not crash - this is the main test
		await sut.log(entry)
	}

	func test_log_acceptsAllLevels() async {
		let sut = NullLogger()

		await sut.log(makeEntry(level: .debug))
		await sut.log(makeEntry(level: .info))
		await sut.log(makeEntry(level: .warning))
		await sut.log(makeEntry(level: .error))
		await sut.log(makeEntry(level: .critical))

		// No crash means success
	}

	// MARK: - Convenience Methods

	func test_debug_doesNotCrash() async {
		let sut = NullLogger()

		await sut.debug("Test debug message")
	}

	func test_info_doesNotCrash() async {
		let sut = NullLogger()

		await sut.info("Test info message")
	}

	func test_warning_doesNotCrash() async {
		let sut = NullLogger()

		await sut.warning("Test warning message")
	}

	func test_error_doesNotCrash() async {
		let sut = NullLogger()

		await sut.error("Test error message")
	}

	func test_critical_doesNotCrash() async {
		let sut = NullLogger()

		await sut.critical("Test critical message")
	}

	// MARK: - Sendable

	func test_canBeUsedAcrossConcurrencyBoundaries() async {
		let sut = NullLogger()

		await Task.detached {
			await sut.log(self.makeEntry(level: .info))
		}.value
	}

	// MARK: - Helpers

	private func makeEntry(level: LogLevel) -> LogEntry {
		LogEntry(
			level: level,
			message: "Test message",
			context: LogContext(file: "test.swift", function: "test()", line: 1)
		)
	}
}
