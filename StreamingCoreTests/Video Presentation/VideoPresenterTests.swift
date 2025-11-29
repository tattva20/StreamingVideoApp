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
