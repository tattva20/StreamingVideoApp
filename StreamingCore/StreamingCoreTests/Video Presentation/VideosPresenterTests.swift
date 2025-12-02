//
//  VideosPresenterTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore

@MainActor
class VideosPresenterTests: XCTestCase {

	func test_title_isLocalized() {
		XCTAssertEqual(VideosPresenter.title, localized("VIDEO_VIEW_TITLE"))
	}

	// MARK: - Helpers

	private func localized(_ key: String, file: StaticString = #filePath, line: UInt = #line) -> String {
		let table = "Video"
		let bundle = Bundle(for: VideosPresenter.self)
		let value = bundle.localizedString(forKey: key, value: nil, table: table)
		if value == key {
			XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
		}
		return value
	}

}
