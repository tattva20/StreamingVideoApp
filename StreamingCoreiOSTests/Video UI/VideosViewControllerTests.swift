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

    // MARK: - Helpers

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
