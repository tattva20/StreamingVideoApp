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

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()

        expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
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

    private func expect(_ sut: LocalVideoLoader,
                       toCompleteWithError expectedError: NSError,
                       when action: () -> Void,
                       file: StaticString = #filePath,
                       line: UInt = #line) {
        let videos = [uniqueVideo(), uniqueVideo()]

        var receivedError: Error?
        do {
            try sut.save(videos)
            action()
        } catch {
            receivedError = error
        }

        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }
}
