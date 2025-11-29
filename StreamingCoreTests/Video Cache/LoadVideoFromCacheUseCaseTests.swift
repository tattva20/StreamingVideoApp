import XCTest
import StreamingCore

@MainActor
class LoadVideoFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()

        _ = try? sut.load()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }

    func test_load_deliversNoVideosOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }

    func test_load_deliversCachedVideosOnNonExpiredCache() {
        let videos = uniqueVideoList()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusVideoCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success(videos.models), when: {
            store.completeRetrieval(with: videos.local, timestamp: nonExpiredTimestamp)
        })
    }

    func test_load_deliversNoVideosOnCacheExpiration() {
        let videos = uniqueVideoList()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusVideoCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: videos.local, timestamp: expirationTimestamp)
        })
    }

    func test_load_deliversNoVideosOnExpiredCache() {
        let videos = uniqueVideoList()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusVideoCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: videos.local, timestamp: expiredTimestamp)
        })
    }

    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()

        _ = try? sut.load()
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()

        _ = try? sut.load()
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let videos = uniqueVideoList()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusVideoCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        _ = try? sut.load()
        store.completeRetrieval(with: videos.local, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
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
                       toCompleteWith expectedResult: Result<[Video], Error>,
                       when action: () -> Void,
                       file: StaticString = #filePath,
                       line: UInt = #line) {
        action()

        let receivedResult = Result { try sut.load() }

        switch (receivedResult, expectedResult) {
        case let (.success(receivedVideos), .success(expectedVideos)):
            XCTAssertEqual(receivedVideos, expectedVideos, file: file, line: line)

        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)

        default:
            XCTFail("Expected result \(expectedResult), got \(receivedResult) instead",
                    file: file, line: line)
        }
    }
}
