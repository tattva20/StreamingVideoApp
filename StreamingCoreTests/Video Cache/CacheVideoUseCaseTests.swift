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
        store.completeDeletion(with: anyNSError())

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
        store.completeDeletion(with: deletionError)

        var receivedError: Error?
        do {
            try sut.save([uniqueVideo(), uniqueVideo()])
        } catch {
            receivedError = error
        }

        XCTAssertEqual(receivedError as NSError?, deletionError)
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        store.completeDeletionSuccessfully()
        store.completeInsertion(with: insertionError)

        var receivedError: Error?
        do {
            try sut.save([uniqueVideo(), uniqueVideo()])
        } catch {
            receivedError = error
        }

        XCTAssertEqual(receivedError as NSError?, insertionError)
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        let videos = [uniqueVideo(), uniqueVideo()]

        var receivedError: Error?
        do {
            try sut.save(videos)
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        } catch {
            receivedError = error
        }

        XCTAssertNil(receivedError)
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
