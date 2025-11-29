import XCTest
import StreamingCore

@MainActor
class VideoLoaderCompositeTests: XCTestCase {

    func test_load_deliversPrimaryVideosOnPrimaryLoaderSuccess() async throws {
        let primaryVideos = [makeVideo(), makeVideo()]
        let (sut, primaryLoader, _) = makeSUT(primaryResult: .success(primaryVideos), fallbackResult: .success([]))

        let receivedVideos = try await sut.load()

        XCTAssertEqual(receivedVideos, primaryVideos)
        XCTAssertEqual(primaryLoader.loadCallCount, 1)
    }

    func test_load_deliversFallbackVideosOnPrimaryLoaderFailure() async throws {
        let fallbackVideos = [makeVideo(), makeVideo()]
        let (sut, primaryLoader, fallbackLoader) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackVideos))

        let receivedVideos = try await sut.load()

        XCTAssertEqual(receivedVideos, fallbackVideos)
        XCTAssertEqual(primaryLoader.loadCallCount, 1)
        XCTAssertEqual(fallbackLoader.loadCallCount, 1)
    }

    func test_load_deliversErrorOnBothPrimaryAndFallbackLoaderFailure() async {
        let (sut, primaryLoader, fallbackLoader) = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .failure(anyNSError()))

        do {
            _ = try await sut.load()
            XCTFail("Expected failure, got success instead")
        } catch {
            XCTAssertEqual(primaryLoader.loadCallCount, 1)
            XCTAssertEqual(fallbackLoader.loadCallCount, 1)
        }
    }

    func test_load_doesNotInvokeFallbackLoaderOnPrimaryLoaderSuccess() async throws {
        let primaryVideos = [makeVideo()]
        let (sut, _, fallbackLoader) = makeSUT(primaryResult: .success(primaryVideos), fallbackResult: .success([]))

        _ = try await sut.load()

        XCTAssertEqual(fallbackLoader.loadCallCount, 0)
    }

    // MARK: - Helpers

    private func makeSUT(
        primaryResult: Result<[Video], Error>,
        fallbackResult: Result<[Video], Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: VideoLoaderComposite, primary: VideoLoaderSpy, fallback: VideoLoaderSpy) {
        let primaryLoader = VideoLoaderSpy(result: primaryResult)
        let fallbackLoader = VideoLoaderSpy(result: fallbackResult)
        let sut = VideoLoaderComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primaryLoader, fallbackLoader)
    }

    private func makeVideo() -> Video {
        return Video(
            id: UUID(),
            title: "a title",
            description: "a description",
            url: URL(string: "https://any-url.com")!,
            thumbnailURL: URL(string: "https://any-url.com")!,
            duration: 120
        )
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private class VideoLoaderSpy: VideoLoader {
        var loadCallCount: Int {
            return loadCalls.count
        }
        private(set) var loadCalls = [Void]()
        private let result: Result<[Video], Error>

        init(result: Result<[Video], Error>) {
            self.result = result
        }

        func load() async throws -> [Video] {
            loadCalls.append(())
            return try result.get()
        }
    }
}
