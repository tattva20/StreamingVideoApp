//
//  VideoCacheCleanerTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class VideoCacheCleanerTests: XCTestCase {

	// MARK: - ResourceCleaner Protocol Conformance

	func test_resourceName_returnsVideoCache() {
		let sut = makeSUT()

		XCTAssertEqual(sut.resourceName, "Video Cache")
	}

	func test_priority_returnsHigh() {
		let sut = makeSUT()

		XCTAssertEqual(sut.priority, .high)
	}

	// MARK: - estimateCleanup

	func test_estimateCleanup_returnsZero_whenCacheSizeUnknown() async {
		let sut = makeSUT()

		let estimate = await sut.estimateCleanup()

		XCTAssertEqual(estimate, 0)
	}

	func test_estimateCleanup_returnsCustomEstimate_whenProvided() async {
		let expectedSize: UInt64 = 100_000_000 // 100MB
		let sut = makeSUT(estimateSize: expectedSize)

		let estimate = await sut.estimateCleanup()

		XCTAssertEqual(estimate, expectedSize)
	}

	// MARK: - cleanup

	func test_cleanup_invokesDeleteAction() async {
		var deleteActionCallCount = 0
		let sut = makeSUT(deleteAction: {
			deleteActionCallCount += 1
		})

		_ = await sut.cleanup()

		XCTAssertEqual(deleteActionCallCount, 1)
	}

	func test_cleanup_returnsSuccess_whenDeleteActionSucceeds() async {
		let sut = makeSUT(deleteAction: { })

		let result = await sut.cleanup()

		XCTAssertEqual(result.success, true)
		XCTAssertEqual(result.resourceName, "Video Cache")
		XCTAssertNil(result.error)
	}

	func test_cleanup_returnsZeroItemsRemoved_byDefault() async {
		let sut = makeSUT(deleteAction: { })

		let result = await sut.cleanup()

		XCTAssertEqual(result.itemsRemoved, 0)
	}

	func test_cleanup_returnsZeroBytesFreed_byDefault() async {
		let sut = makeSUT(deleteAction: { })

		let result = await sut.cleanup()

		XCTAssertEqual(result.bytesFreed, 0)
	}

	func test_cleanup_returnsFailure_whenDeleteActionThrows() async {
		let expectedError = NSError(domain: "test", code: 1)
		let sut = makeSUT(deleteAction: { throw expectedError })

		let result = await sut.cleanup()

		XCTAssertEqual(result.success, false)
		XCTAssertEqual(result.resourceName, "Video Cache")
		XCTAssertNotNil(result.error)
	}

	func test_cleanup_returnsErrorMessage_whenDeleteActionThrows() async {
		let errorMessage = "Failed to delete video cache"
		let expectedError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
		let sut = makeSUT(deleteAction: { throw expectedError })

		let result = await sut.cleanup()

		XCTAssertEqual(result.error, errorMessage)
	}

	// MARK: - With statistics callback

	func test_cleanup_reportsStatistics_whenProvided() async {
		let expectedBytesFreed: UInt64 = 50_000_000
		let expectedItemsRemoved = 5
		let sut = makeSUT(
			deleteAction: { },
			statisticsCallback: { (expectedBytesFreed, expectedItemsRemoved) }
		)

		let result = await sut.cleanup()

		XCTAssertEqual(result.bytesFreed, expectedBytesFreed)
		XCTAssertEqual(result.itemsRemoved, expectedItemsRemoved)
	}

	// MARK: - Helpers

	private func makeSUT(
		deleteAction: @escaping () throws -> Void = { },
		statisticsCallback: (() -> (bytesFreed: UInt64, itemsRemoved: Int))? = nil,
		estimateSize: UInt64 = 0,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> VideoCacheCleaner {
		let sut = VideoCacheCleaner(
			deleteAction: deleteAction,
			statisticsCallback: statisticsCallback,
			estimateSize: estimateSize
		)
		return sut
	}
}
