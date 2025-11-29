import XCTest
import StreamingCore
import StreamingCoreiOS
import AVKit

@MainActor
class VideoPlayerViewControllerTests: XCTestCase {

    func test_init_configuresPlayerWithVideoURL() {
        let video = makeVideo()
        let sut = makeSUT(video: video)

        sut.loadViewIfNeeded()

        let asset = sut.player?.currentItem?.asset as? AVURLAsset
        XCTAssertEqual(asset?.url, video.url)
    }

    // MARK: - Helpers

    private func makeSUT(video: Video, file: StaticString = #filePath, line: UInt = #line) -> VideoPlayerViewController {
        let sut = VideoPlayerViewController(video: video)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func makeVideo() -> Video {
        return Video(id: UUID(), title: "a title", description: "a description", url: URL(string: "https://any-video-url.com/video.mp4")!, thumbnailURL: URL(string: "https://any-url.com")!, duration: 120)
    }
}
