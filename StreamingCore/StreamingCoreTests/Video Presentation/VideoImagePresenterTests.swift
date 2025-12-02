import XCTest
import StreamingCore

class VideoImagePresenterTests: XCTestCase {

    func test_map_createsViewModel() {
        let video = uniqueVideo()

        let viewModel = VideoImagePresenter.map(video)

        XCTAssertEqual(viewModel.title, video.title)
        XCTAssertEqual(viewModel.description, video.description)
    }

    func test_map_videoWithNilDescription() {
        let videoWithoutDescription = Video(
            id: UUID(),
            title: "a title",
            description: nil,
            url: URL(string: "https://any-url.com")!,
            thumbnailURL: URL(string: "https://thumbnail-url.com")!,
            duration: 120.0
        )

        let viewModel = VideoImagePresenter.map(videoWithoutDescription)

        XCTAssertEqual(viewModel.title, "a title")
        XCTAssertNil(viewModel.description)
        XCTAssertFalse(viewModel.hasDescription)
    }

    func test_map_videoWithDescription() {
        let videoWithDescription = Video(
            id: UUID(),
            title: "a title",
            description: "a description",
            url: URL(string: "https://any-url.com")!,
            thumbnailURL: URL(string: "https://thumbnail-url.com")!,
            duration: 120.0
        )

        let viewModel = VideoImagePresenter.map(videoWithDescription)

        XCTAssertEqual(viewModel.title, "a title")
        XCTAssertEqual(viewModel.description, "a description")
        XCTAssertTrue(viewModel.hasDescription)
    }

    // MARK: - Helpers

    private func uniqueVideo() -> Video {
        return Video(
            id: UUID(),
            title: "any title",
            description: "any description",
            url: URL(string: "https://any-url.com")!,
            thumbnailURL: URL(string: "https://thumbnail-url.com")!,
            duration: 100.0
        )
    }
}
