//
//  StreamingCoreCacheIntegrationTests.swift
//  StreamingCoreCacheIntegrationTests
//
//  Created by Octavio Rojas on 29/11/25.
//

import XCTest
import StreamingCore

@MainActor
final class StreamingCoreCacheIntegrationTests: XCTestCase {
    private var store: InMemoryVideoStore!

    override func setUp() {
        super.setUp()
        store = InMemoryVideoStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    func test_load_deliversNoVideosOnEmptyCache() throws {
        let sut = makeSUT()

        expect(sut, toLoad: [])
    }

    func test_load_deliversVideosSavedOnASeparateLoaderInstance() throws {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let videos = uniqueVideos().models

        save(videos, with: sutToPerformSave)

        expect(sutToPerformLoad, toLoad: videos)
    }

    func test_save_overridesVideosSavedOnASeparateLoaderInstance() throws {
        let sutToPerformFirstSave = makeSUT()
        let sutToPerformLastSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let firstVideos = uniqueVideos().models
        let lastVideos = uniqueVideos().models

        save(firstVideos, with: sutToPerformFirstSave)
        save(lastVideos, with: sutToPerformLastSave)

        expect(sutToPerformLoad, toLoad: lastVideos)
    }

    func test_validateCache_doesNotDeleteRecentlySavedVideos() throws {
        let sutToPerformSave = makeSUT()
        let sutToPerformValidation = makeSUT()
        let videos = uniqueVideos().models

        save(videos, with: sutToPerformSave)
        validateCache(with: sutToPerformValidation)

        expect(sutToPerformSave, toLoad: videos)
    }

    func test_validateCache_deletesVideosSavedInADistantPast() throws {
        let sutToPerformSave = makeSUT(currentDate: .distantPast)
        let sutToPerformValidation = makeSUT(currentDate: Date())
        let videos = uniqueVideos().models

        save(videos, with: sutToPerformSave)
        validateCache(with: sutToPerformValidation)

        expect(sutToPerformSave, toLoad: [])
    }

    // MARK: - Helpers

    private func makeSUT(
        currentDate: Date = Date(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> LocalVideoLoader {
        let sut = LocalVideoLoader(store: store, currentDate: { currentDate })
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

    private func expect(_ sut: LocalVideoLoader, toLoad expectedVideos: [Video], file: StaticString = #filePath, line: UInt = #line) {
        do {
            let loadedVideos = try sut.load()
            XCTAssertEqual(loadedVideos, expectedVideos, file: file, line: line)
        } catch {
            XCTFail("Expected successful load, got error: \(error)", file: file, line: line)
        }
    }

    private func uniqueVideos() -> (models: [Video], local: [LocalVideo]) {
        let models = [
            Video(
                id: UUID(),
                title: "a title",
                description: "a description",
                url: anyURL(),
                thumbnailURL: anyURL(),
                duration: 120
            ),
            Video(
                id: UUID(),
                title: "another title",
                description: "another description",
                url: anyURL(),
                thumbnailURL: anyURL(),
                duration: 180
            )
        ]
        let local = models.map { video in
            LocalVideo(
                id: video.id,
                title: video.title,
                description: video.description,
                url: video.url,
                thumbnailURL: video.thumbnailURL,
                duration: video.duration
            )
        }
        return (models, local)
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

}
