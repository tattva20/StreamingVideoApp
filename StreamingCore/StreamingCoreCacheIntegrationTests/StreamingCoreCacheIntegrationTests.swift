//
//  StreamingCoreCacheIntegrationTests.swift
//  StreamingCoreCacheIntegrationTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore

@MainActor
class StreamingCoreCacheIntegrationTests: XCTestCase {

	override func setUp() async throws {
		try await super.setUp()

		setupEmptyStoreState()
	}

	override func tearDown() async throws {
		try await super.tearDown()

		undoStoreSideEffects()
	}

	// MARK: - LocalVideoLoader Tests

	func test_loadVideos_deliversNoItemsOnEmptyCache() throws {
		let videoLoader = try makeVideoLoader()

		expect(videoLoader, toLoad: [])
	}

	func test_loadVideos_deliversItemsSavedOnASeparateInstance() throws {
		let videoLoaderToPerformSave = try makeVideoLoader()
		let videoLoaderToPerformLoad = try makeVideoLoader()
		let videos = uniqueVideoFeed().models

		save(videos, with: videoLoaderToPerformSave)

		expect(videoLoaderToPerformLoad, toLoad: videos)
	}

	func test_saveVideos_overridesItemsSavedOnASeparateInstance() throws {
		let videoLoaderToPerformFirstSave = try makeVideoLoader()
		let videoLoaderToPerformLastSave = try makeVideoLoader()
		let videoLoaderToPerformLoad = try makeVideoLoader()
		let firstVideos = uniqueVideoFeed().models
		let latestVideos = uniqueVideoFeed().models

		save(firstVideos, with: videoLoaderToPerformFirstSave)
		save(latestVideos, with: videoLoaderToPerformLastSave)

		expect(videoLoaderToPerformLoad, toLoad: latestVideos)
	}

	func test_validateCache_doesNotDeleteRecentlySavedVideos() throws {
		let videoLoaderToPerformSave = try makeVideoLoader()
		let videoLoaderToPerformValidation = try makeVideoLoader()
		let videos = uniqueVideoFeed().models

		save(videos, with: videoLoaderToPerformSave)
		validateCache(with: videoLoaderToPerformValidation)

		expect(videoLoaderToPerformSave, toLoad: videos)
	}

	func test_validateCache_deletesVideosSavedInADistantPast() throws {
		let videoLoaderToPerformSave = try makeVideoLoader(currentDate: .distantPast)
		let videoLoaderToPerformValidation = try makeVideoLoader(currentDate: Date())
		let videos = uniqueVideoFeed().models

		save(videos, with: videoLoaderToPerformSave)
		validateCache(with: videoLoaderToPerformValidation)

		expect(videoLoaderToPerformSave, toLoad: [])
	}

	// MARK: - LocalVideoImageDataLoader Tests

	func test_loadImageData_deliversSavedDataOnASeparateInstance() throws {
		let imageLoaderToPerformSave = try makeImageLoader()
		let imageLoaderToPerformLoad = try makeImageLoader()
		let videoLoader = try makeVideoLoader()
		let video = uniqueVideo()
		let dataToSave = anyData()

		save([video], with: videoLoader)
		save(dataToSave, for: video.thumbnailURL, with: imageLoaderToPerformSave)

		expect(imageLoaderToPerformLoad, toLoad: dataToSave, for: video.thumbnailURL)
	}

	func test_saveImageData_overridesSavedImageDataOnASeparateInstance() throws {
		let imageLoaderToPerformFirstSave = try makeImageLoader()
		let imageLoaderToPerformLastSave = try makeImageLoader()
		let imageLoaderToPerformLoad = try makeImageLoader()
		let videoLoader = try makeVideoLoader()
		let video = uniqueVideo()
		let firstImageData = Data("first".utf8)
		let lastImageData = Data("last".utf8)

		save([video], with: videoLoader)
		save(firstImageData, for: video.thumbnailURL, with: imageLoaderToPerformFirstSave)
		save(lastImageData, for: video.thumbnailURL, with: imageLoaderToPerformLastSave)

		expect(imageLoaderToPerformLoad, toLoad: lastImageData, for: video.thumbnailURL)
	}

	// MARK: - Helpers

	private func makeVideoLoader(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) throws -> LocalVideoLoader {
		let storeURL = testSpecificStoreURL()
		let store = try CoreDataVideoStore(storeURL: storeURL, contextQueue: .main)
		let sut = LocalVideoLoader(store: store, currentDate: { currentDate })
		trackForMemoryLeaks(store, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func makeImageLoader(file: StaticString = #filePath, line: UInt = #line) throws -> LocalVideoImageDataLoader {
		let storeURL = testSpecificStoreURL()
		let store = try CoreDataVideoStore(storeURL: storeURL, contextQueue: .main)
		let sut = LocalVideoImageDataLoader(store: store)
		trackForMemoryLeaks(store, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func save(_ videos: [Video], with loader: LocalVideoLoader, file: StaticString = #filePath, line: UInt = #line) {
		do {
			try loader.save(videos)
		} catch {
			XCTFail("Expected to save videos successfully, got error: \(error)", file: file, line: line)
		}
	}

	private func validateCache(with loader: LocalVideoLoader, file: StaticString = #filePath, line: UInt = #line) {
		do {
			try loader.validateCache()
		} catch {
			XCTFail("Expected to validate cache successfully, got error: \(error)", file: file, line: line)
		}
	}

	private func save(_ data: Data, for url: URL, with loader: LocalVideoImageDataLoader, file: StaticString = #filePath, line: UInt = #line) {
		do {
			try loader.save(data, for: url)
		} catch {
			XCTFail("Expected to save image data successfully, got error: \(error)", file: file, line: line)
		}
	}

	private func expect(_ sut: LocalVideoLoader, toLoad expectedVideos: [Video], file: StaticString = #filePath, line: UInt = #line) {
		do {
			let videos = try sut.load()
			XCTAssertEqual(videos, expectedVideos, file: file, line: line)
		} catch {
			XCTFail("Expected successful load, got error: \(error)", file: file, line: line)
		}
	}

	private func expect(_ sut: LocalVideoImageDataLoader, toLoad expectedData: Data, for url: URL, file: StaticString = #filePath, line: UInt = #line) {
		do {
			let loadedData = try sut.loadImageData(from: url)
			XCTAssertEqual(loadedData, expectedData, file: file, line: line)
		} catch {
			XCTFail("Expected successful image data result, got \(error) instead", file: file, line: line)
		}
	}

	private func setupEmptyStoreState() {
		deleteStoreArtifacts()
	}

	private func undoStoreSideEffects() {
		deleteStoreArtifacts()
	}

	private func deleteStoreArtifacts() {
		try? FileManager.default.removeItem(at: testSpecificStoreURL())
	}

	private func testSpecificStoreURL() -> URL {
		FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
			.first!
			.appendingPathComponent("\(type(of: self)).store")
	}

	private func uniqueVideoFeed() -> (models: [Video], local: [LocalVideo]) {
		let models = [uniqueVideo(), uniqueVideo()]
		let local = models.map { LocalVideo(id: $0.id, title: $0.title, description: $0.description, url: $0.url, thumbnailURL: $0.thumbnailURL, duration: $0.duration) }
		return (models, local)
	}

	private func uniqueVideo() -> Video {
		return Video(id: UUID(), title: "any title", description: "any description", url: anyURL(), thumbnailURL: anyURL(), duration: 120)
	}

	private func anyURL() -> URL {
		return URL(string: "https://any-url.com")!
	}

	private func anyData() -> Data {
		return Data("any data".utf8)
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}

}