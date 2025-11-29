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
