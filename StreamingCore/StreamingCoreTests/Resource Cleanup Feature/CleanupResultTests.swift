//
//  CleanupResultTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class CleanupResultTests: XCTestCase {

	// MARK: - Initialization Tests

	func test_init_storesResourceName() {
		let sut = makeSUT(resourceName: "Test Resource")

		XCTAssertEqual(sut.resourceName, "Test Resource")
	}

	func test_init_storesBytesFreed() {
		let sut = makeSUT(bytesFreed: 1_048_576)

		XCTAssertEqual(sut.bytesFreed, 1_048_576)
	}

	func test_init_storesItemsRemoved() {
		let sut = makeSUT(itemsRemoved: 42)

		XCTAssertEqual(sut.itemsRemoved, 42)
	}

	func test_init_storesSuccessTrue() {
		let sut = makeSUT(success: true)

		XCTAssertTrue(sut.success)
	}

	func test_init_storesSuccessFalse() {
		let sut = makeSUT(success: false)

		XCTAssertFalse(sut.success)
	}

	func test_init_storesError() {
		let sut = makeSUT(error: "Something went wrong")

		XCTAssertEqual(sut.error, "Something went wrong")
	}

	func test_init_errorDefaultsToNil() {
		let sut = makeSUT()

		XCTAssertNil(sut.error)
	}

	// MARK: - Computed Property Tests

	func test_freedMB_convertsBytes() {
		// 2MB = 2 * 1024 * 1024 = 2,097,152 bytes
		let sut = makeSUT(bytesFreed: 2_097_152)

		XCTAssertEqual(sut.freedMB, 2.0, accuracy: 0.001)
	}

	func test_freedMB_handlesZeroBytes() {
		let sut = makeSUT(bytesFreed: 0)

		XCTAssertEqual(sut.freedMB, 0.0)
	}

	func test_freedMB_handlesFractionalMB() {
		// 1.5MB = 1.5 * 1024 * 1024 = 1,572,864 bytes
		let sut = makeSUT(bytesFreed: 1_572_864)

		XCTAssertEqual(sut.freedMB, 1.5, accuracy: 0.001)
	}

	// MARK: - Factory Method Tests

	func test_failure_createsResultWithZeroBytesFreed() {
		let sut = CleanupResult.failure(resourceName: "Test", error: "Error")

		XCTAssertEqual(sut.bytesFreed, 0)
	}

	func test_failure_createsResultWithZeroItemsRemoved() {
		let sut = CleanupResult.failure(resourceName: "Test", error: "Error")

		XCTAssertEqual(sut.itemsRemoved, 0)
	}

	func test_failure_createsResultWithSuccessFalse() {
		let sut = CleanupResult.failure(resourceName: "Test", error: "Error")

		XCTAssertFalse(sut.success)
	}

	func test_failure_storesResourceName() {
		let sut = CleanupResult.failure(resourceName: "Image Cache", error: "Error")

		XCTAssertEqual(sut.resourceName, "Image Cache")
	}

	func test_failure_storesErrorMessage() {
		let sut = CleanupResult.failure(resourceName: "Test", error: "Disk full")

		XCTAssertEqual(sut.error, "Disk full")
	}

	// MARK: - Equatable Tests

	func test_sameResults_areEqual() {
		let result1 = makeSUT(resourceName: "Cache", bytesFreed: 1000, itemsRemoved: 5, success: true)
		let result2 = makeSUT(resourceName: "Cache", bytesFreed: 1000, itemsRemoved: 5, success: true)

		XCTAssertEqual(result1, result2)
	}

	func test_differentResourceNames_areNotEqual() {
		let result1 = makeSUT(resourceName: "Cache A")
		let result2 = makeSUT(resourceName: "Cache B")

		XCTAssertNotEqual(result1, result2)
	}

	func test_differentBytesFreed_areNotEqual() {
		let result1 = makeSUT(bytesFreed: 1000)
		let result2 = makeSUT(bytesFreed: 2000)

		XCTAssertNotEqual(result1, result2)
	}

	func test_differentItemsRemoved_areNotEqual() {
		let result1 = makeSUT(itemsRemoved: 5)
		let result2 = makeSUT(itemsRemoved: 10)

		XCTAssertNotEqual(result1, result2)
	}

	func test_differentSuccess_areNotEqual() {
		let result1 = makeSUT(success: true)
		let result2 = makeSUT(success: false)

		XCTAssertNotEqual(result1, result2)
	}

	func test_differentErrors_areNotEqual() {
		let result1 = makeSUT(error: "Error A")
		let result2 = makeSUT(error: "Error B")

		XCTAssertNotEqual(result1, result2)
	}

	// MARK: - Sendable Tests

	func test_cleanupResult_isSendable() {
		let result: any Sendable = makeSUT()
		XCTAssertNotNil(result)
	}

	// MARK: - Helpers

	private func makeSUT(
		resourceName: String = "Test Resource",
		bytesFreed: UInt64 = 0,
		itemsRemoved: Int = 0,
		success: Bool = true,
		error: String? = nil
	) -> CleanupResult {
		CleanupResult(
			resourceName: resourceName,
			bytesFreed: bytesFreed,
			itemsRemoved: itemsRemoved,
			success: success,
			error: error
		)
	}
}
