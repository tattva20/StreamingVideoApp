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

    func test_viewDidLoad_rendersTableView() {
        let (sut, _) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertNotNil(sut.tableView)
    }

    func test_init_setsOnVideoSelectionHandler() {
        var selectedVideo: Video?
        let loader = LoaderSpy()
        let sut = VideosViewController(loader: loader, onVideoSelection: { selectedVideo = $0 })

        XCTAssertNil(selectedVideo)

        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
    }

    func test_loadActions_requestVideosFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view is loaded")

        loader.completeLoading(at: 0)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")

        loader.completeLoading(at: 1)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected yet another loading request once user initiates another reload")
    }

    func test_loadingIndicator_isVisibleWhileLoadingVideos() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loader.completeLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully")

        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")

        loader.completeLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading completes with error")
    }

    func test_loadCompletion_rendersSuccessfullyLoadedVideos() {
        let video0 = makeVideo(title: "a title", description: "a description")
        let video1 = makeVideo(title: "another title", description: "another description")

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])

        loader.completeLoading(with: [video0], at: 0)
        assertThat(sut, isRendering: [video0])

        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [video0, video1], at: 1)
        assertThat(sut, isRendering: [video0, video1])
    }

    func test_loadCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let video0 = makeVideo()
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeLoading(with: [video0], at: 0)
        assertThat(sut, isRendering: [video0])

        sut.simulateUserInitiatedReload()
        loader.completeLoadingWithError(at: 1)
        assertThat(sut, isRendering: [video0])
    }

    func test_loadCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeLoading(at: 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }

    func test_loadCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.errorMessage, nil)

        loader.completeLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }

    // MARK: - Helpers

    private func assertThat(_ sut: VideosViewController, isRendering videos: [Video], file: StaticString = #filePath, line: UInt = #line) {
        sut.tableView.layoutIfNeeded()
        RunLoop.main.run(until: Date())

        guard sut.numberOfRenderedVideos() == videos.count else {
            return XCTFail("Expected \(videos.count) videos, got \(sut.numberOfRenderedVideos()) instead.", file: file, line: line)
        }

        videos.enumerated().forEach { index, video in
            assertThat(sut, hasViewConfiguredFor: video, at: index, file: file, line: line)
        }
    }

    private func assertThat(_ sut: VideosViewController, hasViewConfiguredFor video: Video, at index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let view = sut.videoView(at: index)

        guard let cell = view as? VideoCell else {
            return XCTFail("Expected \(VideoCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }

        XCTAssertEqual(cell.titleText, video.title, "Expected title text to be \(String(describing: video.title)) for video view at index (\(index))", file: file, line: line)
        XCTAssertEqual(cell.descriptionText, video.description, "Expected description text to be \(String(describing: video.description)) for video view at index (\(index))", file: file, line: line)
    }

    private var loadError: String {
        LoadResourcePresenter<Any, DummyView>.loadError
    }

    private func makeVideo(title: String = "any title", description: String = "any description") -> Video {
        return Video(
            id: UUID(),
            title: title,
            description: description,
            url: URL(string: "https://any-url.com/video.mp4")!,
            thumbnailURL: URL(string: "https://any-url.com/thumbnail.jpg")!,
            duration: 120
        )
    }

    private class DummyView: ResourceView {
        func display(_ viewModel: Any) {}
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
        private struct LoadError: Error {}
        private struct NoResponse: Error {}

        private(set) var requests = [(
            stream: AsyncThrowingStream<[Video], Error>,
            continuation: AsyncThrowingStream<[Video], Error>.Continuation,
            result: AsyncResult?
        )]()

        var loadCallCount: Int {
            return requests.count
        }

        func load() async throws -> [Video] {
            let (stream, continuation) = AsyncThrowingStream<[Video], Error>.makeStream()
            let index = requests.count
            requests.append((stream, continuation, nil))

            do {
                for try await result in stream {
                    try Task.checkCancellation()
                    requests[index].result = .success
                    return result
                }

                try Task.checkCancellation()
                throw NoResponse()
            } catch {
                requests[index].result = Task.isCancelled ? .cancelled : .failure
                throw error
            }
        }

        func completeLoading(with videos: [Video] = [], at index: Int = 0) {
            requests[index].continuation.yield(videos)
            requests[index].continuation.finish()

            while requests[index].result == nil { RunLoop.current.run(until: Date()) }
        }

        func completeLoadingWithError(at index: Int = 0) {
            requests[index].continuation.finish(throwing: LoadError())

            while requests[index].result == nil { RunLoop.current.run(until: Date()) }
        }
    }

    private enum AsyncResult {
        case success
        case failure
        case cancelled
    }
}

private extension VideosViewController {
    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }

    func numberOfRenderedVideos() -> Int {
        return tableView.numberOfRows(inSection: videosSection)
    }

    func videoView(at row: Int) -> UITableViewCell? {
        guard numberOfRenderedVideos() > row else {
            return nil
        }
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: videosSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }

    private var videosSection: Int { 0 }

    var errorMessage: String? {
        return errorView?.message
    }

    private var errorView: ErrorView? {
        return listViewController?.errorView
    }

    private var listViewController: ListViewController? {
        return children.first as? ListViewController
    }

    private var refreshControl: UIRefreshControl? {
        return listViewController?.refreshControl
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        simulate(event: .valueChanged)
    }
}

private extension VideoCell {
    var titleText: String? {
        return titleLabel.text
    }

    var descriptionText: String? {
        return descriptionLabel.text
    }
}
