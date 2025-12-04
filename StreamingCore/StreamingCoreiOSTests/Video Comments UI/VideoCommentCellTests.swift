//
//  VideoCommentCellTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCoreiOS

@MainActor
final class VideoCommentCellTests: XCTestCase {

	func test_init_hasMessageLabel() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.messageLabel)
	}

	func test_init_hasUsernameLabel() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.usernameLabel)
	}

	func test_init_hasDateLabel() {
		let sut = makeSUT()

		XCTAssertNotNil(sut.dateLabel)
	}

	func test_messageLabel_usesBodyFont() {
		let sut = makeSUT()

		XCTAssertEqual(sut.messageLabel.font, .preferredFont(forTextStyle: .body))
	}

	func test_usernameLabel_usesHeadlineFont() {
		let sut = makeSUT()

		XCTAssertEqual(sut.usernameLabel.font, .preferredFont(forTextStyle: .headline))
	}

	func test_dateLabel_usesCaption1Font() {
		let sut = makeSUT()

		XCTAssertEqual(sut.dateLabel.font, .preferredFont(forTextStyle: .caption1))
	}

	func test_messageLabel_allowsMultipleLines() {
		let sut = makeSUT()

		XCTAssertEqual(sut.messageLabel.numberOfLines, 0)
	}

	// MARK: - Helpers

	private func makeSUT() -> VideoCommentCell {
		VideoCommentCell()
	}
}
