//
//  CellControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import UIKit
@testable import StreamingCoreiOS

@MainActor
final class CellControllerTests: XCTestCase {

	func test_init_storesDataSource() {
		let dataSource = DataSourceSpy()

		let sut = CellController(id: UUID(), dataSource)

		XCTAssertTrue(sut.dataSource === dataSource)
	}

	func test_init_extractsDelegateFromDataSource() {
		let dataSource = DataSourceDelegateSpy()

		let sut = CellController(id: UUID(), dataSource)

		XCTAssertTrue(sut.delegate === dataSource)
	}

	func test_init_extractsDataSourcePrefetchingFromDataSource() {
		let dataSource = DataSourcePrefetchingSpy()

		let sut = CellController(id: UUID(), dataSource)

		XCTAssertTrue(sut.dataSourcePrefetching === dataSource)
	}

	func test_init_setsNilDelegateWhenDataSourceDoesNotConform() {
		let dataSource = DataSourceSpy()

		let sut = CellController(id: UUID(), dataSource)

		XCTAssertNil(sut.delegate)
	}

	func test_init_setsNilDataSourcePrefetchingWhenDataSourceDoesNotConform() {
		let dataSource = DataSourceSpy()

		let sut = CellController(id: UUID(), dataSource)

		XCTAssertNil(sut.dataSourcePrefetching)
	}

	func test_equality_isBasedOnId() {
		let id = UUID()
		let sut1 = CellController(id: id, DataSourceSpy())
		let sut2 = CellController(id: id, DataSourceSpy())
		let sut3 = CellController(id: UUID(), DataSourceSpy())

		XCTAssertEqual(sut1, sut2)
		XCTAssertNotEqual(sut1, sut3)
	}

	func test_hashable_isBasedOnId() {
		let id = UUID()
		let sut1 = CellController(id: id, DataSourceSpy())
		let sut2 = CellController(id: id, DataSourceSpy())

		XCTAssertEqual(sut1.hashValue, sut2.hashValue)
	}

	// MARK: - Helpers

	private class DataSourceSpy: NSObject, UITableViewDataSource {
		func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
		func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
	}

	private class DataSourceDelegateSpy: NSObject, UITableViewDataSource, UITableViewDelegate {
		func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
		func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
	}

	private class DataSourcePrefetchingSpy: NSObject, UITableViewDataSource, UITableViewDataSourcePrefetching {
		func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
		func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
		func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {}
	}
}
