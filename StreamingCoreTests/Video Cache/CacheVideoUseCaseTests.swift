import XCTest
import StreamingCore

@MainActor
class CacheVideoUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let videos = [uniqueVideo(), uniqueVideo()]
        let (sut, store) = makeSUT()

        try? sut.save(videos)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedVideos])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let videos = [uniqueVideo(), uniqueVideo()]
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()

        try? sut.save(videos)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedVideos])
    }

    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let videos = uniqueVideoList()
        let (sut, store) = makeSUT(currentDate: { timestamp })

        try? sut.save(videos.models)
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCachedVideos, .insert(videos.local, timestamp)])
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
