import XCTest
import StreamingCore

@MainActor
class ValidateVideoCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        try? sut.validateCache()
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedVideos])
    }

    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()

        try? sut.validateCache()
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_doesNotDeleteNonExpiredCache() {
        let videos = uniqueVideoList()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusVideoCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        try? sut.validateCache()
        store.completeRetrieval(with: videos.local, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_deletesCacheOnExpiration() {
        let videos = uniqueVideoList()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusVideoCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        try? sut.validateCache()
        store.completeRetrieval(with: videos.local, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedVideos])
    }

    func test_validateCache_deletesExpiredCache() {
        let videos = uniqueVideoList()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusVideoCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        try? sut.validateCache()
        store.completeRetrieval(with: videos.local, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedVideos])
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalVideoLoader, store: VideoStoreSpy) {
        let store = VideoStoreSpy()
        let sut = LocalVideoLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
