//
//  CombineHelpersTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
import StreamingCore

final class CombineHelpersTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
	}

	// MARK: - Fallback Tests

	func test_fallback_deliversPrimaryValueOnSuccess() {
		let expectedValue = "primary value"
		var receivedValue: String?

		Just(expectedValue)
			.setFailureType(to: Error.self)
			.fallback { self.fail("Fallback should not be called") }
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { receivedValue = $0 }
			)
			.store(in: &cancellables)

		XCTAssertEqual(receivedValue, expectedValue)
	}

	func test_fallback_deliversFallbackValueOnPrimaryFailure() {
		let expectedValue = "fallback value"
		var receivedValue: String?

		Fail<String, Error>(error: anyNSError())
			.fallback { Just(expectedValue).setFailureType(to: Error.self).eraseToAnyPublisher() }
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { receivedValue = $0 }
			)
			.store(in: &cancellables)

		XCTAssertEqual(receivedValue, expectedValue)
	}

	// MARK: - Caching Tests

	func test_caching_savesVideosToCacheOnSuccess() {
		let videos = [uniqueVideo(), uniqueVideo()]
		let cache = VideoCacheSpy()

		Just(videos)
			.setFailureType(to: Error.self)
			.caching(to: cache)
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { _ in }
			)
			.store(in: &cancellables)

		XCTAssertEqual(cache.savedVideos, videos)
	}

	func test_caching_savesPagedVideosToCacheOnSuccess() {
		let videos = [uniqueVideo(), uniqueVideo()]
		let page = Paginated(items: videos)
		let cache = VideoCacheSpy()

		Just(page)
			.setFailureType(to: Error.self)
			.caching(to: cache)
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { _ in }
			)
			.store(in: &cancellables)

		XCTAssertEqual(cache.savedVideos, videos)
	}

	func test_caching_savesImageDataToCacheForURL() {
		let data = Data("image data".utf8)
		let url = anyURL()
		let cache = ImageDataCacheSpy()

		Just(data)
			.setFailureType(to: Error.self)
			.caching(to: cache, for: url)
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { _ in }
			)
			.store(in: &cancellables)

		XCTAssertEqual(cache.savedData, data)
		XCTAssertEqual(cache.savedURL, url)
	}

	func test_caching_doesNotSaveOnFailure() {
		let cache = VideoCacheSpy()

		Fail<[Video], Error>(error: anyNSError())
			.caching(to: cache)
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { _ in }
			)
			.store(in: &cancellables)

		XCTAssertTrue(cache.savedVideos.isEmpty)
	}

	func test_caching_imageData_doesNotSaveOnFailure() {
		let url = anyURL()
		let cache = ImageDataCacheSpy()

		Fail<Data, Error>(error: anyNSError())
			.caching(to: cache, for: url)
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { _ in }
			)
			.store(in: &cancellables)

		XCTAssertNil(cache.savedData)
		XCTAssertNil(cache.savedURL)
	}

	// MARK: - Helpers

	private func uniqueVideo() -> Video {
		Video(
			id: UUID(),
			title: "any title",
			description: "any description",
			url: anyURL(),
			thumbnailURL: anyURL(),
			duration: 100
		)
	}

	private func fail(_ message: String = "Should not be called", file: StaticString = #filePath, line: UInt = #line) -> AnyPublisher<String, Error> {
		XCTFail(message, file: file, line: line)
		return Empty().eraseToAnyPublisher()
	}

	private class VideoCacheSpy: VideoCache {
		private(set) var savedVideos: [Video] = []

		func save(_ videos: [Video]) throws {
			savedVideos = videos
		}
	}

	private class ImageDataCacheSpy: VideoImageDataCache {
		private(set) var savedData: Data?
		private(set) var savedURL: URL?

		func save(_ data: Data, for url: URL) throws {
			savedData = data
			savedURL = url
		}
	}
}
