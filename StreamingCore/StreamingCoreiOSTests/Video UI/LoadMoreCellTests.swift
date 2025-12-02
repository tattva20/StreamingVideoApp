//
//  LoadMoreCellTests.swift
//  StreamingCoreiOSTests
//
//  Created by Octavio Rojas on 30/11/25.
//

import XCTest
import StreamingCoreiOS

@MainActor
class LoadMoreCellTests: XCTestCase {

    func test_init_rendersNoLoadingIndicatorOrMessage() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isLoading, "Expected no loading indicator on init")
        XCTAssertNil(sut.message, "Expected no message on init")
    }

    func test_startLoading_displaysLoadingIndicator() {
        let sut = makeSUT()

        sut.isLoading = true

        XCTAssertTrue(sut.isLoading, "Expected loading indicator when loading starts")
    }

    func test_stopLoading_hidesLoadingIndicator() {
        let sut = makeSUT()

        sut.isLoading = true
        sut.isLoading = false

        XCTAssertFalse(sut.isLoading, "Expected no loading indicator when loading stops")
    }

    func test_setMessage_displaysMessage() {
        let sut = makeSUT()
        let message = "any message"

        sut.message = message

        XCTAssertEqual(sut.message, message, "Expected to display message")
    }

    func test_setNilMessage_hidesMessage() {
        let sut = makeSUT()

        sut.message = "any message"
        sut.message = nil

        XCTAssertNil(sut.message, "Expected to hide message")
    }

    // MARK: - Helpers

    private func makeSUT() -> LoadMoreCell {
        return LoadMoreCell()
    }
}
