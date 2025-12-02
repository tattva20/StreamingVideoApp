import XCTest
import StreamingCore

@MainActor
final class VideoEndpointTests: XCTestCase {

	func test_video_endpointURL() {
		let baseURL = URL(string: "http://base-url.com")!

		let received = VideoEndpoint.get().url(baseURL: baseURL)

		XCTAssertEqual(received.scheme, "http", "scheme")
		XCTAssertEqual(received.host, "base-url.com", "host")
		XCTAssertEqual(received.path, "/v1/videos", "path")
		XCTAssertEqual(received.query, "limit=10", "query")
	}

	func test_video_endpointURLAfterGivenVideo() {
		let video = uniqueVideo()
		let baseURL = URL(string: "http://base-url.com")!

		let received = VideoEndpoint.get(after: video).url(baseURL: baseURL)

		XCTAssertEqual(received.scheme, "http", "scheme")
		XCTAssertEqual(received.host, "base-url.com", "host")
		XCTAssertEqual(received.path, "/v1/videos", "path")
		XCTAssertEqual(received.query?.contains("limit=10"), true, "limit query param")
		XCTAssertEqual(received.query?.contains("after_id=\(video.id)"), true, "after_id query param")
	}

	// MARK: - Helpers

	private func uniqueVideo() -> Video {
		return Video(
			id: UUID(),
			title: "any title",
			description: "any description",
			url: URL(string: "https://any-url.com")!,
			thumbnailURL: URL(string: "https://any-url.com")!,
			duration: 120
		)
	}
}
