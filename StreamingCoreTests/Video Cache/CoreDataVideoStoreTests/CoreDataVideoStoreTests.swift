import XCTest
import StreamingCore

@MainActor
class CoreDataVideoStoreTests: XCTestCase {

    func test_retrieve_deliversEmptyOnEmptyCache() async throws {
        let sut = try await makeSUT()

        await sut.perform {
            let result = try? sut.retrieve()
            XCTAssertNil(result)
        }
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = try await makeSUT()

        await sut.perform {
            _ = try? sut.retrieve()
            _ = try? sut.retrieve()

            let result = try? sut.retrieve()
            XCTAssertNil(result)
        }
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        let sut = try await makeSUT()
        let videos = uniqueVideos().local
        let timestamp = Date()

        await sut.perform {
            try? sut.insert(videos, timestamp: timestamp)

            let retrieved = try? sut.retrieve()
            XCTAssertEqual(retrieved?.videos, videos)
            XCTAssertEqual(retrieved?.timestamp, timestamp)
        }
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() async throws {
        let sut = try await makeSUT()
        let videos = uniqueVideos().local
        let timestamp = Date()

        await sut.perform {
            try? sut.insert(videos, timestamp: timestamp)

            _ = try? sut.retrieve()

            let retrieved = try? sut.retrieve()
            XCTAssertEqual(retrieved?.videos, videos)
            XCTAssertEqual(retrieved?.timestamp, timestamp)
        }
    }

    func test_insert_deliversNoErrorOnEmptyCache() async throws {
        let sut = try await makeSUT()
        let videos = uniqueVideos().local
        let timestamp = Date()

        try await sut.perform {
            try sut.insert(videos, timestamp: timestamp)
        }
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = try await makeSUT()
        let firstVideos = uniqueVideos().local
        let secondVideos = uniqueVideos().local
        let timestamp = Date()

        try await sut.perform {
            try sut.insert(firstVideos, timestamp: timestamp)
            try sut.insert(secondVideos, timestamp: timestamp)
        }
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() async throws {
        let sut = try await makeSUT()
        let firstVideos = uniqueVideos().local
        let secondVideos = uniqueVideos().local
        let firstTimestamp = Date()
        let secondTimestamp = Date()

        await sut.perform {
            try? sut.insert(firstVideos, timestamp: firstTimestamp)
            try? sut.insert(secondVideos, timestamp: secondTimestamp)

            let retrieved = try? sut.retrieve()
            XCTAssertEqual(retrieved?.videos, secondVideos)
            XCTAssertEqual(retrieved?.timestamp, secondTimestamp)
        }
    }

    func test_delete_deliversNoErrorOnEmptyCache() async throws {
        let sut = try await makeSUT()

        try await sut.perform {
            try sut.deleteCachedVideos()
        }
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = try await makeSUT()

        await sut.perform {
            try? sut.deleteCachedVideos()

            let result = try? sut.retrieve()
            XCTAssertNil(result)
        }
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = try await makeSUT()
        let videos = uniqueVideos().local
        let timestamp = Date()

        try await sut.perform {
            try sut.insert(videos, timestamp: timestamp)
            try sut.deleteCachedVideos()
        }
    }

    func test_delete_emptiesPreviouslyInsertedCache() async throws {
        let sut = try await makeSUT()
        let videos = uniqueVideos().local
        let timestamp = Date()

        await sut.perform {
            try? sut.insert(videos, timestamp: timestamp)
            try? sut.deleteCachedVideos()

            let result = try? sut.retrieve()
            XCTAssertNil(result)
        }
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) async throws -> CoreDataVideoStore {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataVideoStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func uniqueVideos() -> (models: [Video], local: [LocalVideo]) {
        let models = [
            Video(
                id: UUID(),
                title: "a title",
                description: "a description",
                url: URL(string: "https://any-url.com")!,
                thumbnailURL: URL(string: "https://any-url.com")!,
                duration: 120
            ),
            Video(
                id: UUID(),
                title: "another title",
                description: "another description",
                url: URL(string: "https://any-url.com")!,
                thumbnailURL: URL(string: "https://any-url.com")!,
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
}
