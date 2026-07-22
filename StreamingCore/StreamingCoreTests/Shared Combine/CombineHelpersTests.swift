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

	// MARK: - Caching Tests

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

	private class ImageDataCacheSpy: VideoImageDataCache {
		private(set) var savedData: Data?
		private(set) var savedURL: URL?

		func save(_ data: Data, for url: URL) throws {
			savedData = data
			savedURL = url
		}
	}
}
