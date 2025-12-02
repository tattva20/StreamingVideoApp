//
//  ErrorViewTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCoreiOS

@MainActor
final class ErrorViewTests: XCTestCase {

    func test_init_doesNotDisplayMessage() {
        let sut = ErrorView()

        XCTAssertNil(sut.message)
        XCTAssertFalse(sut.isVisible)
    }

    func test_setMessage_displaysMessage() {
        let sut = ErrorView()

        sut.message = "an error message"

        XCTAssertEqual(sut.message, "an error message")
        XCTAssertTrue(sut.isVisible)
    }

    func test_setNilMessage_hidesMessage() {
        let sut = ErrorView()
        sut.message = "an error message"
        XCTAssertNotNil(sut.message)

        sut.message = nil

        XCTAssertNil(sut.message)
        XCTAssertFalse(sut.isVisible)
    }
}

private extension ErrorView {
    var isVisible: Bool {
        return alpha > 0
    }
}
