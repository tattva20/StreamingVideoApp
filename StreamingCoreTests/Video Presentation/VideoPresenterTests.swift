import XCTest
import StreamingCore

@MainActor
class VideoPresenterTests: XCTestCase {

    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()

        XCTAssertTrue(view.messages.isEmpty)
    }

    func test_didStartLoading_displaysLoadingState() {
        let (sut, view) = makeSUT()

        sut.didStartLoading()

        XCTAssertEqual(view.messages, [.display(isLoading: true)])
    }

    func test_didFinishLoadingWithVideos_displaysVideosAndStopsLoading() {
        let (sut, view) = makeSUT()
        let videos = [uniqueVideo(), uniqueVideo()]

        sut.didFinishLoading(with: videos)

        XCTAssertEqual(view.messages, [
            .display(isLoading: false),
            .display(videos: videos)
        ])
    }

    func test_didFinishLoadingWithError_displaysErrorMessageAndStopsLoading() {
        let (sut, view) = makeSUT()

        sut.didFinishLoading(with: anyNSError())

        XCTAssertEqual(view.messages, [
            .display(isLoading: false),
            .display(error: "Could not load videos. Please try again.")
        ])
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: VideoPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = VideoPresenter(view: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    private class ViewSpy: VideoView {
        enum Message: Equatable {
            case display(isLoading: Bool)
            case display(videos: [Video])
            case display(error: String)
        }

        private(set) var messages = [Message]()

        func display(isLoading: Bool) {
            messages.append(.display(isLoading: isLoading))
        }

        func display(videos: [Video]) {
            messages.append(.display(videos: videos))
        }

        func display(error: String) {
            messages.append(.display(error: error))
        }
    }
}
