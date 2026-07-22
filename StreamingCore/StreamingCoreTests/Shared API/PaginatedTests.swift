//
//  PaginatedTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

final class PaginatedTests: XCTestCase {

	func test_init_storesItems() {
		let items = ["item1", "item2", "item3"]

		let sut = Paginated(items: items)

		XCTAssertEqual(sut.items, items)
	}

	func test_init_withLoadMore_storesLoadMoreClosure() {
		let sut = Paginated(items: [String]()) { Paginated(items: []) }

		XCTAssertNotNil(sut.loadMore)
	}

	func test_init_withNoLoadMore_setsLoadMoreToNil() {
		let sut = Paginated(items: [String]())

		XCTAssertNil(sut.loadMore)
	}

	func test_loadMore_deliversNewPageOnSuccess() async throws {
		let expectedItems = ["new1", "new2"]

		let sut = Paginated(items: [String]()) {
			Paginated(items: expectedItems)
		}

		let page = try await sut.loadMore?()

		XCTAssertEqual(page?.items, expectedItems)
	}

	func test_loadMore_deliversErrorOnFailure() async {
		let expectedError = anyNSError()

		let sut = Paginated(items: [String]()) {
			throw expectedError
		}

		do {
			_ = try await sut.loadMore?()
			XCTFail("Expected failure, got success")
		} catch {
			XCTAssertEqual(error as NSError, expectedError)
		}
	}
}
