//
//  PaginatedCombineTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
import StreamingCore

final class PaginatedCombineTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
	}

	func test_initWithLoadMorePublisher_convertsPublisherToCallback() {
		let expectedItems = ["item1", "item2"]
		let loadMorePublisher: () -> AnyPublisher<Paginated<String>, Error> = {
			Just(Paginated(items: expectedItems))
				.setFailureType(to: Error.self)
				.eraseToAnyPublisher()
		}

		let sut = Paginated(items: [String](), loadMorePublisher: loadMorePublisher)

		XCTAssertNotNil(sut.loadMore, "Expected loadMore to be set when initialized with publisher")
	}

	func test_initWithLoadMorePublisher_withNilPublisher_setsLoadMoreToNil() {
		let sut = Paginated(items: [String](), loadMorePublisher: nil)

		XCTAssertNil(sut.loadMore)
	}

	func test_loadMorePublisher_convertsCallbackToPublisher() {
		let expectedItems = ["item1", "item2"]
		let sut = Paginated(items: [String]()) { completion in
			completion(.success(Paginated(items: expectedItems)))
		}

		XCTAssertNotNil(sut.loadMorePublisher, "Expected loadMorePublisher to be available")
	}

	func test_loadMorePublisher_withNilLoadMore_returnsNilPublisher() {
		let sut = Paginated(items: [String]())

		XCTAssertNil(sut.loadMorePublisher)
	}

	func test_loadMorePublisher_deliversResultOnSuccess() {
		let expectation = expectation(description: "Wait for publisher")
		let expectedItems = ["new1", "new2"]
		var receivedItems: [String]?

		let sut = Paginated(items: [String]()) { completion in
			completion(.success(Paginated(items: expectedItems)))
		}

		sut.loadMorePublisher?()
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { page in
					receivedItems = page.items
					expectation.fulfill()
				}
			)
			.store(in: &cancellables)

		wait(for: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedItems, expectedItems)
	}

	func test_loadMorePublisher_deliversErrorOnFailure() {
		let expectation = expectation(description: "Wait for publisher")
		let expectedError = anyNSError()
		var receivedError: Error?

		let sut = Paginated(items: [String]()) { completion in
			completion(.failure(expectedError))
		}

		sut.loadMorePublisher?()
			.sink(
				receiveCompletion: { completion in
					if case let .failure(error) = completion {
						receivedError = error
						expectation.fulfill()
					}
				},
				receiveValue: { _ in }
			)
			.store(in: &cancellables)

		wait(for: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedError as NSError?, expectedError)
	}
}
