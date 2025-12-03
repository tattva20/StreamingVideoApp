//
//  ConsoleLoggerTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

final class ConsoleLoggerTests: XCTestCase {

	// MARK: - Minimum Level

	func test_init_setsMinimumLevel() {
		let sut = ConsoleLogger(minimumLevel: .warning)

		XCTAssertEqual(sut.minimumLevel, .warning)
	}

	func test_init_defaultsMinimumLevelToDebug() {
		let sut = ConsoleLogger()

		XCTAssertEqual(sut.minimumLevel, .debug)
	}

	// MARK: - Filtering

	func test_log_ignoresEntriesBelowMinimumLevel() async {
		let sut = ConsoleLogger(minimumLevel: .warning)
		let entry = makeEntry(level: .debug)

		// Should not crash and should be filtered (no output visible)
		await sut.log(entry)
	}

	func test_log_acceptsEntriesAtMinimumLevel() async {
		let sut = ConsoleLogger(minimumLevel: .info)
		let entry = makeEntry(level: .info)

		// Should not crash
		await sut.log(entry)
	}

	func test_log_acceptsEntriesAboveMinimumLevel() async {
		let sut = ConsoleLogger(minimumLevel: .info)
		let entry = makeEntry(level: .error)

		// Should not crash
		await sut.log(entry)
	}

	// MARK: - Logging All Levels

	func test_log_handlesDebugLevel() async {
		let sut = ConsoleLogger(minimumLevel: .debug)

		await sut.log(makeEntry(level: .debug))
	}

	func test_log_handlesInfoLevel() async {
		let sut = ConsoleLogger(minimumLevel: .debug)

		await sut.log(makeEntry(level: .info))
	}

	func test_log_handlesWarningLevel() async {
		let sut = ConsoleLogger(minimumLevel: .debug)

		await sut.log(makeEntry(level: .warning))
	}

	func test_log_handlesErrorLevel() async {
		let sut = ConsoleLogger(minimumLevel: .debug)

		await sut.log(makeEntry(level: .error))
	}

	func test_log_handlesCriticalLevel() async {
		let sut = ConsoleLogger(minimumLevel: .debug)

		await sut.log(makeEntry(level: .critical))
	}

	// MARK: - Metadata Handling

	func test_log_handlesMetadata() async {
		let sut = ConsoleLogger()
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1,
			metadata: ["key": "value", "another": "data"]
		)
		let entry = LogEntry(level: .info, message: "Test", context: context)

		await sut.log(entry)
	}

	func test_log_handlesCorrelationID() async {
		let sut = ConsoleLogger()
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1,
			correlationID: UUID()
		)
		let entry = LogEntry(level: .info, message: "Test", context: context)

		await sut.log(entry)
	}

	// MARK: - Concurrent Access

	func test_log_handlesMultipleConcurrentLogs() async {
		let sut = ConsoleLogger()

		await withTaskGroup(of: Void.self) { group in
			for i in 0..<10 {
				group.addTask {
					await sut.log(self.makeEntry(level: .info, message: "Message \(i)"))
				}
			}
		}

		// No crash means success
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
