//
//  LogContextTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

final class LogContextTests: XCTestCase {

	// MARK: - Initialization

	func test_init_extractsFileNameFromPath() {
		let context = LogContext(
			file: "/path/to/MyFile.swift",
			function: "testFunction()",
			line: 42
		)

		XCTAssertEqual(context.file, "MyFile.swift")
	}

	func test_init_storesFunction() {
		let context = LogContext(
			file: "test.swift",
			function: "myFunction(param:)",
			line: 1
		)

		XCTAssertEqual(context.function, "myFunction(param:)")
	}

	func test_init_storesLine() {
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 123
		)

		XCTAssertEqual(context.line, 123)
	}

	func test_init_storesOptionalSubsystem() {
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1,
			subsystem: "VideoPlayer"
		)

		XCTAssertEqual(context.subsystem, "VideoPlayer")
	}

	func test_init_storesOptionalCategory() {
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1,
			category: "Playback"
		)

		XCTAssertEqual(context.category, "Playback")
	}

	func test_init_storesOptionalCorrelationID() {
		let correlationID = UUID()
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1,
			correlationID: correlationID
		)

		XCTAssertEqual(context.correlationID, correlationID)
	}

	func test_init_storesMetadata() {
		let metadata = ["key1": "value1", "key2": "value2"]
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1,
			metadata: metadata
		)

		XCTAssertEqual(context.metadata, metadata)
	}

	func test_init_defaultsOptionalValuesToNilOrEmpty() {
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 1
		)

		XCTAssertNil(context.subsystem)
		XCTAssertNil(context.category)
		XCTAssertNil(context.correlationID)
		XCTAssertTrue(context.metadata.isEmpty)
	}

	// MARK: - Equatable

	func test_contextsWithSameValues_areEqual() {
		let correlationID = UUID()
		let context1 = LogContext(
			file: "test.swift",
			function: "test()",
			line: 42,
			subsystem: "App",
			category: "Test",
			correlationID: correlationID,
			metadata: ["key": "value"]
		)
		let context2 = LogContext(
			file: "test.swift",
			function: "test()",
			line: 42,
			subsystem: "App",
			category: "Test",
			correlationID: correlationID,
			metadata: ["key": "value"]
		)

		XCTAssertEqual(context1, context2)
	}

	func test_contextsWithDifferentValues_areNotEqual() {
		let context1 = LogContext(file: "test1.swift", function: "test()", line: 1)
		let context2 = LogContext(file: "test2.swift", function: "test()", line: 1)

		XCTAssertNotEqual(context1, context2)
	}

	// MARK: - Sendable

	func test_canBeSentAcrossConcurrencyBoundaries() async {
		let context = LogContext(
			file: "test.swift",
			function: "test()",
			line: 42,
			subsystem: "Test"
		)

		let result = await Task.detached {
			return context
		}.value

		XCTAssertEqual(result, context)
	}
}
