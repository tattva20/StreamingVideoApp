import XCTest
import StreamingCore
import StreamingCoreiOS

@MainActor
class VideosViewControllerTests: XCTestCase {

    func test_init_doesNotLoadVideos() {
        let (_, loader) = makeSUT()

        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsVideos() async {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()

        await Task.yield()

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_viewDidLoad_loadsVideosOnlyOnce() async {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        sut.loadViewIfNeeded()

        await Task.yield()

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_loadCompletion_rendersSuccessfullyLoadedVideos() async {
        let video0 = makeVideo(title: "a title")
        let video1 = makeVideo(title: "another title")
        let (sut, loader) = makeSUT()

        loader.stub = .success([video0, video1])
        sut.loadViewIfNeeded()

        await Task.yield()

        XCTAssertEqual(sut.numberOfRenderedVideos(), 2)
    }

    func test_loadCompletion_doesNotAlterCurrentRenderingStateOnError() async {
        let video = makeVideo(title: "a title")
        let (sut, loader) = makeSUT()

        loader.stub = .success([video])
        sut.loadViewIfNeeded()

        await Task.yield()

        XCTAssertEqual(sut.numberOfRenderedVideos(), 1)

        loader.stub = .failure(anyNSError())
        XCTAssertEqual(sut.numberOfRenderedVideos(), 1)
    }

    func test_videoView_hasTitle() async {
        let video = makeVideo(title: "a title")
        let (sut, loader) = makeSUT()

        loader.stub = .success([video])
        sut.loadViewIfNeeded()

        await Task.yield()

        let view = sut.videoView(at: 0)

        XCTAssertNotNil(view?.titleLabel.text)
    }

    func test_videoSelection_notifiesDelegate() async {
        let video0 = makeVideo(title: "a title")
        let video1 = makeVideo(title: "another title")
        var selectedVideos = [Video]()
        let loader = LoaderSpy()
        let sut = VideosViewController(loader: loader, onVideoSelection: { selectedVideos.append($0) })

        loader.stub = .success([video0, video1])
        sut.loadViewIfNeeded()

        await Task.yield()

        sut.simulateTapOnVideo(at: 0)
        XCTAssertEqual(selectedVideos, [video0])

        sut.simulateTapOnVideo(at: 1)
        XCTAssertEqual(selectedVideos, [video0, video1])
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
        let sut = VideosViewController(loader: loader, onVideoSelection: nil)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }

    private class LoaderSpy: VideoLoader {
        var loadCallCount: Int {
            return loadCalls.count
        }
        private(set) var loadCalls = [Void]()
        var stub: Result<[Video], Error> = .success([])

        func load() async throws -> [Video] {
            loadCalls.append(())
            return try stub.get()
        }
    }
}

private extension VideosViewController {
    func numberOfRenderedVideos() -> Int {
        return tableView?.numberOfRows(inSection: videosSection) ?? 0
    }

    func videoView(at row: Int) -> VideoCell? {
        let dataSource = tableView?.dataSource
        let index = IndexPath(row: row, section: videosSection)
        return dataSource?.tableView(tableView!, cellForRowAt: index) as? VideoCell
    }

    func simulateTapOnVideo(at row: Int) {
        let delegate = tableView?.delegate
        let index = IndexPath(row: row, section: videosSection)
        delegate?.tableView?(tableView!, didSelectRowAt: index)
    }

    var videosSection: Int {
        return 0
    }
}
