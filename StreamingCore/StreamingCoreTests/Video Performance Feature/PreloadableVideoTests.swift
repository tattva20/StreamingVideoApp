//
//  PreloadableVideoTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PreloadableVideoTests: XCTestCase {

	// MARK: - Initialization

	func test_init_storesIdAndURL() {
		let id = UUID()
		let url = anyURL()

		let sut = PreloadableVideo(id: id, url: url, estimatedDuration: nil)

		XCTAssertEqual(sut.id, id)
		XCTAssertEqual(sut.url, url)
	}

	func test_init_storesEstimatedDuration() {
		let expectedDuration: TimeInterval = 120.5

		let sut = PreloadableVideo(id: UUID(), url: anyURL(), estimatedDuration: expectedDuration)

		XCTAssertEqual(sut.estimatedDuration, expectedDuration)
	}

	func test_init_storesNilDuration_whenNotProvided() {
		let sut = PreloadableVideo(id: UUID(), url: anyURL(), estimatedDuration: nil)

		XCTAssertNil(sut.estimatedDuration)
	}

	// MARK: - Equatable

	func test_equatable_equalWhenAllPropertiesMatch() {
		let id = UUID()
		let url = anyURL()
		let duration: TimeInterval = 100

		let video1 = PreloadableVideo(id: id, url: url, estimatedDuration: duration)
		let video2 = PreloadableVideo(id: id, url: url, estimatedDuration: duration)

		XCTAssertEqual(video1, video2)
	}

	func test_equatable_notEqualWhenIdDiffers() {
		let url = anyURL()

		let video1 = PreloadableVideo(id: UUID(), url: url, estimatedDuration: nil)
		let video2 = PreloadableVideo(id: UUID(), url: url, estimatedDuration: nil)

		XCTAssertNotEqual(video1, video2)
	}

	func test_equatable_notEqualWhenURLDiffers() {
		let id = UUID()

		let video1 = PreloadableVideo(id: id, url: URL(string: "https://example.com/a.mp4")!, estimatedDuration: nil)
		let video2 = PreloadableVideo(id: id, url: URL(string: "https://example.com/b.mp4")!, estimatedDuration: nil)

		XCTAssertNotEqual(video1, video2)
	}

	// MARK: - Helpers

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}
