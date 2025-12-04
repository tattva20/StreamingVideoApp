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
		let sut = Paginated(items: [String]()) { _ in }

		XCTAssertNotNil(sut.loadMore)
	}

	func test_init_withNoLoadMore_setsLoadMoreToNil() {
		let sut = Paginated(items: [String]())

		XCTAssertNil(sut.loadMore)
	}

	func test_loadMore_callsCompletionWithNewPage() {
		let expectation = expectation(description: "Wait for loadMore")
		let expectedItems = ["new1", "new2"]
		var receivedResult: Result<Paginated<String>, Error>?

		let sut = Paginated(items: [String]()) { completion in
			completion(.success(Paginated(items: expectedItems)))
		}

		sut.loadMore? { result in
			receivedResult = result
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 1.0)

		switch receivedResult {
		case let .success(page):
			XCTAssertEqual(page.items, expectedItems)
		case .failure, .none:
			XCTFail("Expected success with items, got \(String(describing: receivedResult))")
		}
	}

	func test_loadMore_deliversErrorOnFailure() {
		let expectation = expectation(description: "Wait for loadMore")
		let expectedError = anyNSError()
		var receivedResult: Result<Paginated<String>, Error>?

		let sut = Paginated(items: [String]()) { completion in
			completion(.failure(expectedError))
		}

		sut.loadMore? { result in
			receivedResult = result
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 1.0)

		switch receivedResult {
		case .success:
			XCTFail("Expected failure, got success")
		case let .failure(error as NSError):
			XCTAssertEqual(error, expectedError)
		case .none:
			XCTFail("Expected failure, got nil")
		}
	}
}
