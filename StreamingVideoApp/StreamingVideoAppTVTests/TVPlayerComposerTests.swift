import XCTest
import AVFoundation
import StreamingCore
import StreamingCorePlayback
@testable import StreamingVideoAppTV

@MainActor
final class TVPlayerComposerTests: XCTestCase {

	func test_playerComposedWithVideo_loadsVideoURLIntoAVPlayer() {
		let url = anyStreamURL()

		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo(url: url))

		let loadedURL = (bundle.player.currentItem?.asset as? AVURLAsset)?.url
		XCTAssertEqual(loadedURL, url, "Expected the composed AVPlayer to be loaded with the video's stream URL")
	}

	func test_playerComposedWithVideo_startsCoordinatorObservingPlayer() {
		let bundle = TVPlayerComposer.playerComposedWith(video: makeVideo())

		XCTAssertTrue(bundle.coordinator.isObserving, "Expected the playback coordinator to start observing on composition")
	}

	// MARK: - Helpers

	private func makeVideo(url: URL = URL(string: "https://any-url.com/stream.m3u8")!) -> Video {
		Video(
			id: UUID(),
			title: "any title",
			description: nil,
			url: url,
			thumbnailURL: URL(string: "https://any-url.com/thumb.jpg")!,
			duration: 0
		)
	}

	private func anyStreamURL() -> URL {
		URL(string: "https://a-given-host.com/a-given-stream.m3u8")!
	}
}
