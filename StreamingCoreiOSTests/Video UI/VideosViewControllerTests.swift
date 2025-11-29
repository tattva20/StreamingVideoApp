import XCTest
import StreamingCore
import StreamingCoreiOS

@MainActor
class VideosViewControllerTests: XCTestCase {

    func test_init_doesNotLoadVideos() {
        let (_, loader) = makeSUT()

        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsVideos() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_viewDidLoad_loadsVideosOnlyOnce() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_loadCompletion_rendersSuccessfullyLoadedVideos() {
        let video0 = makeVideo(title: "a title")
        let video1 = makeVideo(title: "another title")
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completions[0](.success([video0, video1]))

        XCTAssertEqual(sut.numberOfRenderedVideos(), 2)
    }

    func test_loadCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let video = makeVideo(title: "a title")
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completions[0](.success([video]))
        XCTAssertEqual(sut.numberOfRenderedVideos(), 1)

        loader.completions[0](.failure(anyNSError()))
        XCTAssertEqual(sut.numberOfRenderedVideos(), 1)
    }

    // MARK: - Helpers

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private func makeVideo(title: String) -> Video {
        return Video(id: UUID(), title: title, description: "a description", url: URL(string: "https://any-url.com")!, thumbnailURL: URL(string: "https://any-url.com")!, duration: 120)
    }

    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: VideosViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = VideosViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }

    private class LoaderSpy: VideoLoader {
        var loadCallCount: Int {
            return completions.count
        }
        private(set) var completions = [(Result<[Video], Error>) -> Void]()

        func load(completion: @escaping (Result<[Video], Error>) -> Void) {
            completions.append(completion)
        }
    }
}

private extension VideosViewController {
    func numberOfRenderedVideos() -> Int {
        return tableView?.numberOfRows(inSection: videosSection) ?? 0
    }

    var videosSection: Int {
        return 0
    }
}
