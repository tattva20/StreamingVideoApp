//
//  ImageCacheCleanerTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class ImageCacheCleanerTests: XCTestCase {

	// MARK: - ResourceCleaner Protocol Conformance

	func test_resourceName_returnsImageCache() {
		let sut = makeSUT()

		XCTAssertEqual(sut.resourceName, "Image Cache")
	}

	func test_priority_returnsMedium() {
		let sut = makeSUT()

		XCTAssertEqual(sut.priority, .medium)
	}

	// MARK: - estimateCleanup

	func test_estimateCleanup_returnsZero_whenCacheSizeUnknown() async {
		let sut = makeSUT()

		let estimate = await sut.estimateCleanup()

		XCTAssertEqual(estimate, 0)
	}

	func test_estimateCleanup_returnsCustomEstimate_whenProvided() async {
		let expectedSize: UInt64 = 5_000_000
		let sut = makeSUT(estimateSize: expectedSize)

		let estimate = await sut.estimateCleanup()

		XCTAssertEqual(estimate, expectedSize)
	}

	// MARK: - cleanup

	func test_cleanup_invokesClearAction() async {
		var clearActionCallCount = 0
		let sut = makeSUT(clearAction: {
			clearActionCallCount += 1
			return 10
		})

		_ = await sut.cleanup()

		XCTAssertEqual(clearActionCallCount, 1)
	}

	func test_cleanup_returnsSuccess_whenClearActionSucceeds() async {
		let itemsCleared = 15
		let sut = makeSUT(clearAction: { itemsCleared })

		let result = await sut.cleanup()

		XCTAssertEqual(result.success, true)
		XCTAssertEqual(result.resourceName, "Image Cache")
		XCTAssertEqual(result.itemsRemoved, itemsCleared)
		XCTAssertNil(result.error)
	}

	func test_cleanup_returnsZeroBytesFreed_asNSCacheDoesNotExposeSize() async {
		let sut = makeSUT(clearAction: { 10 })

		let result = await sut.cleanup()

		XCTAssertEqual(result.bytesFreed, 0)
	}

	func test_cleanup_returnsFailure_whenClearActionThrows() async {
		let expectedError = NSError(domain: "test", code: 1)
		let sut = makeSUT(clearAction: { throw expectedError })

		let result = await sut.cleanup()

		XCTAssertEqual(result.success, false)
		XCTAssertEqual(result.resourceName, "Image Cache")
		XCTAssertEqual(result.itemsRemoved, 0)
		XCTAssertNotNil(result.error)
	}

	func test_cleanup_returnsErrorMessage_whenClearActionThrows() async {
		let expectedError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cache clear failed"])
		let sut = makeSUT(clearAction: { throw expectedError })

		let result = await sut.cleanup()

		XCTAssertEqual(result.error, "Cache clear failed")
	}

	// MARK: - Helpers

	private func makeSUT(
		clearAction: @escaping () throws -> Int = { 0 },
		estimateSize: UInt64 = 0,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> ImageCacheCleaner {
		let sut = ImageCacheCleaner(
			clearAction: clearAction,
			estimateSize: estimateSize
		)
		return sut
	}
}
