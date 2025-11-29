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

    // MARK: - Helpers

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
