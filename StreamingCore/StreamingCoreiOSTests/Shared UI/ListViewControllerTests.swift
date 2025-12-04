//
//  ListViewControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore
@testable import StreamingCoreiOS

@MainActor
final class ListViewControllerTests: XCTestCase {

	func test_init_hasErrorView() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.errorView)
	}

	func test_viewDidLoad_configuresTableView() {
		let sut = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertNotNil(sut.tableView.dataSource)
	}

	func test_viewDidAppear_triggersRefresh() {
		var refreshCallCount = 0
		let sut = makeSUT()
		sut.onRefresh = { refreshCallCount += 1 }

		sut.loadViewIfNeeded()
		sut.viewDidAppear(false)

		XCTAssertEqual(refreshCallCount, 1)
	}

	func test_viewDidAppear_triggersRefreshOnlyOnce() {
		var refreshCallCount = 0
		let sut = makeSUT()
		sut.onRefresh = { refreshCallCount += 1 }

		sut.loadViewIfNeeded()
		sut.viewDidAppear(false)
		sut.viewDidAppear(false)

		XCTAssertEqual(refreshCallCount, 1)
	}

	func test_valueChanged_triggersRefresh() {
		var refreshCallCount = 0
		let sut = makeSUT()
		sut.onRefresh = { refreshCallCount += 1 }

		sut.loadViewIfNeeded()
		sut.viewDidAppear(false)

		sut.valueChanged()

		XCTAssertEqual(refreshCallCount, 2)
	}

	func test_display_errorViewModel_displaysErrorMessage() {
		let sut = makeSUT()
		sut.loadViewIfNeeded()

		sut.display(ResourceErrorViewModel(message: "an error message"))

		XCTAssertEqual(sut.errorView.message, "an error message")
	}

	func test_display_nilErrorMessage_hidesError() {
		let sut = makeSUT()
		sut.loadViewIfNeeded()

		sut.display(ResourceErrorViewModel(message: "an error message"))
		sut.display(ResourceErrorViewModel(message: nil))

		XCTAssertNil(sut.errorView.message)
	}

	// MARK: - Helpers

	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> ListViewController {
		let sut = ListViewController()
		sut.refreshControl = UIRefreshControl()
		return sut
	}
}
