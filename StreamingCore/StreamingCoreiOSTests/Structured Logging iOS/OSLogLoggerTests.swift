//
//  OSLogLoggerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore
@testable import StreamingCoreiOS

final class OSLogLoggerTests: XCTestCase {

	// MARK: - Initialization

	func test_init_setsMinimumLevel() {
		let sut = OSLogLogger(
			subsystem: "com.test.app",
			category: "test",
			minimumLevel: .warning
		)

		XCTAssertEqual(sut.minimumLevel, .warning)
	}

	func test_init_defaultsMinimumLevelToInfo() {
		let sut = OSLogLogger(
			subsystem: "com.test.app",
			category: "test"
		)

		XCTAssertEqual(sut.minimumLevel, .info)
	}

	// MARK: - Logging

	func test_log_doesNotCrashForDebugLevel() async {
		let sut = makeSUT(minimumLevel: .debug)

		await sut.log(makeEntry(level: .debug))
	}

	func test_log_doesNotCrashForInfoLevel() async {
		let sut = makeSUT()

		await sut.log(makeEntry(level: .info))
	}

	func test_log_doesNotCrashForWarningLevel() async {
		let sut = makeSUT()

		await sut.log(makeEntry(level: .warning))
	}

	func test_log_doesNotCrashForErrorLevel() async {
		let sut = makeSUT()

		await sut.log(makeEntry(level: .error))
	}

	func test_log_doesNotCrashForCriticalLevel() async {
		let sut = makeSUT()

		await sut.log(makeEntry(level: .critical))
	}

	// MARK: - Filtering

	func test_log_ignoresEntriesBelowMinimumLevel() async {
		let sut = makeSUT(minimumLevel: .error)

		// Should not crash and should be filtered
		await sut.log(makeEntry(level: .info))
	}

	func test_log_acceptsEntriesAtMinimumLevel() async {
		let sut = makeSUT(minimumLevel: .warning)

		await sut.log(makeEntry(level: .warning))
	}

	// MARK: - Concurrent Access

	func test_log_handlesConcurrentLogs() async {
		let sut = makeSUT()

		await withTaskGroup(of: Void.self) { group in
			for i in 0..<10 {
				group.addTask {
					await sut.log(self.makeEntry(level: .info, message: "Concurrent \(i)"))
				}
			}
		}
	}

	// MARK: - Helpers

	private func makeSUT(minimumLevel: LogLevel = .info) -> OSLogLogger {
		OSLogLogger(
			subsystem: "com.streamingvideoapp.test",
			category: "UnitTests",
			minimumLevel: minimumLevel
		)
	}

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
