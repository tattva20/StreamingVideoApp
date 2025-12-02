//
//  VideoCommentsPresenterTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore

class VideoCommentsPresenterTests: XCTestCase {

	func test_title_isLocalized() {
		XCTAssertEqual(VideoCommentsPresenter.title, localized("VIDEO_COMMENTS_VIEW_TITLE"))
	}

	func test_map_createsViewModels() {
		let now = Date()
		let calendar = Calendar(identifier: .gregorian)
		let locale = Locale(identifier: "en_US_POSIX")

		let comments = [
			VideoComment(
				id: UUID(),
				message: "a message",
				createdAt: now.adding(minutes: -5, calendar: calendar),
				username: "a username"
			),
			VideoComment(
				id: UUID(),
				message: "another message",
				createdAt: now.adding(days: -1, calendar: calendar),
				username: "another username"
			)
		]

		let viewModel = VideoCommentsPresenter.map(
			comments,
			currentDate: now,
			calendar: calendar,
			locale: locale
		)

		XCTAssertEqual(viewModel.comments.count, 2)
		XCTAssertEqual(viewModel.comments[0].message, "a message")
		XCTAssertEqual(viewModel.comments[0].username, "a username")
		XCTAssertEqual(viewModel.comments[0].date, "5 minutes ago")
		XCTAssertEqual(viewModel.comments[1].message, "another message")
		XCTAssertEqual(viewModel.comments[1].username, "another username")
		XCTAssertEqual(viewModel.comments[1].date, "1 day ago")
	}

	// MARK: - Helpers

	private func localized(_ key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
		let table = "VideoComments"
		let bundle = Bundle(for: VideoCommentsPresenter.self)
		let value = bundle.localizedString(forKey: key, value: nil, table: table)
		if value == key {
			XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
		}
		return value
	}
}
