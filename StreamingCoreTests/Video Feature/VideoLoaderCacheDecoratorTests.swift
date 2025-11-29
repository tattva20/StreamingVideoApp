import XCTest
import StreamingCore

@MainActor
class VideoLoaderCacheDecoratorTests: XCTestCase {

    func test_load_deliversLoaderVideosOnLoaderSuccess() async throws {
        let videos = [makeVideo(), makeVideo()]
        let (sut, _, _) = makeSUT(loaderResult: .success(videos))

        let receivedVideos = try await sut.load()

        XCTAssertEqual(receivedVideos, videos)
    }

    func test_load_cachesLoadedVideosOnLoaderSuccess() async throws {
        let videos = [makeVideo(), makeVideo()]
        let (sut, _, cache) = makeSUT(loaderResult: .success(videos))

        _ = try await sut.load()

        XCTAssertEqual(cache.messages, [.save(videos)])
    }

    func test_load_deliversErrorOnLoaderFailure() async {
        let (sut, _, _) = makeSUT(loaderResult: .failure(anyNSError()))

        do {
            _ = try await sut.load()
            XCTFail("Expected failure, got success instead")
        } catch {
            // Expected error
        }
    }

    func test_load_doesNotCacheOnLoaderFailure() async {
        let (sut, _, cache) = makeSUT(loaderResult: .failure(anyNSError()))

        _ = try? await sut.load()

        XCTAssertTrue(cache.messages.isEmpty)
    }

    func test_load_deliversErrorOnLoaderSuccessButCacheFailure() async {
        let videos = [makeVideo()]
        let (sut, _, cache) = makeSUT(loaderResult: .success(videos))
        cache.completeWithError()

        do {
            _ = try await sut.load()
            XCTFail("Expected failure, got success instead")
        } catch {
            // Expected cache error
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        loaderResult: Result<[Video], Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: VideoLoaderCacheDecorator, loader: VideoLoaderSpy, cache: VideoCacheSpy) {
        let loader = VideoLoaderSpy(result: loaderResult)
        let cache = VideoCacheSpy()
        let sut = VideoLoaderCacheDecorator(decoratee: loader, cache: cache)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(cache, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader, cache)
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
        private let result: Result<[Video], Error>

        init(result: Result<[Video], Error>) {
            self.result = result
        }

        func load() async throws -> [Video] {
            return try result.get()
        }
    }

    private class VideoCacheSpy: VideoCache {
        enum Message: Equatable {
            case save([Video])
        }

        private(set) var messages = [Message]()
        private var error: Error?

        func save(_ videos: [Video]) throws {
            messages.append(.save(videos))
            if let error = error {
                throw error
            }
        }

        func completeWithError() {
            error = NSError(domain: "cache error", code: 0)
        }
    }
}
