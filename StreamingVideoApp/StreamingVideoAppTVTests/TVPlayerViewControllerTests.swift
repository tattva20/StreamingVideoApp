import XCTest
import AVFoundation
import AVKit
import StreamingCore
@testable import StreamingVideoAppTV

@MainActor
final class TVPlayerViewControllerTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	func test_viewDidLoad_setsAVPlayerLoadedWithVideoStreamURL() {
		let url = URL(string: "https://a-host.com/a-stream.m3u8")!
		let sut = TVPlayerViewController(video: makeVideo(url: url))

		sut.loadViewIfNeeded()

		let loadedURL = (sut.player?.currentItem?.asset as? AVURLAsset)?.url
		XCTAssertEqual(loadedURL, url, "Expected the embedded AVPlayerViewController's player to be loaded with the video's stream URL")
	}

	func test_viewDidLoad_withComments_presentsCommentsAsCustomInfoViewController() {
		let comments = UIViewController()
		let sut = TVPlayerViewController(video: makeVideo(url: anyURL()), comments: comments)

		sut.loadViewIfNeeded()

		XCTAssertTrue(sut.customInfoViewControllers.contains(comments), "Expected the comments controller to be shown as a custom info panel")
	}

	// MARK: - Helpers

	private func anyURL() -> URL { URL(string: "https://a-host.com/a-stream.m3u8")! }

	private func makeVideo(url: URL) -> Video {
		Video(
			id: UUID(),
			title: "any title",
			description: nil,
			url: url,
			thumbnailURL: URL(string: "https://a-host.com/thumb.jpg")!,
			duration: 0
		)
	}
}
