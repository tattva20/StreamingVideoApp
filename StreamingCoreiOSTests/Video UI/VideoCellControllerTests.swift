import XCTest
import StreamingCore
import StreamingCoreiOS

@MainActor
final class VideoCellControllerTests: XCTestCase {

    func test_view_loadsVideoCell() {
        let video = makeVideo()
        let (sut, _) = makeSUT(video: video)
        let tableView = UITableView()
        tableView.register(VideoCell.self, forCellReuseIdentifier: "VideoCell")

        let cell = sut.view(in: tableView)

        XCTAssertTrue(cell is VideoCell, "Expected VideoCell instance")
    }

    func test_view_configuresCellWithVideoTitle() {
        let video = makeVideo(title: "A Video Title")
        let (sut, _) = makeSUT(video: video)
        let tableView = UITableView()
        tableView.register(VideoCell.self, forCellReuseIdentifier: "VideoCell")

        let cell = sut.view(in: tableView) as? VideoCell

        XCTAssertEqual(cell?.titleLabel.text, "A Video Title")
    }

    func test_view_configuresCellWithDifferentVideoTitle() {
        let video = makeVideo(title: "Another Video Title")
        let (sut, _) = makeSUT(video: video)
        let tableView = UITableView()
        tableView.register(VideoCell.self, forCellReuseIdentifier: "VideoCell")

        let cell = sut.view(in: tableView) as? VideoCell

        XCTAssertEqual(cell?.titleLabel.text, "Another Video Title")
    }

    func test_selection_notifiesHandler() {
        let video = makeVideo()
        let (sut, spy) = makeSUT(video: video)

        sut.didSelect()

        XCTAssertEqual(spy.selectedVideos, [video])
    }

    // MARK: - Helpers

    private func makeSUT(video: Video, file: StaticString = #filePath, line: UInt = #line) -> (VideoCellController, SelectionSpy) {
        let spy = SelectionSpy()
        let sut = VideoCellController(video: video, selection: spy.select)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)
        return (sut, spy)
    }

    private func makeVideo(title: String = "any title") -> Video {
        return Video(
            id: UUID(),
            title: title,
            description: "any description",
            url: URL(string: "https://any-url.com")!,
            thumbnailURL: URL(string: "https://any-url.com")!,
            duration: 120
        )
    }

    private class SelectionSpy {
        private(set) var selectedVideos = [Video]()

        func select(_ video: Video) {
            selectedVideos.append(video)
        }
    }
}
