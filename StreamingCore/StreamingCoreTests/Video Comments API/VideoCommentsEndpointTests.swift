//
//  VideoCommentsEndpointTests.swift
//  StreamingCoreTests
//

import XCTest
import StreamingCore

class VideoCommentsEndpointTests: XCTestCase {

	func test_videoComments_endpointURL() {
		let videoID = UUID(uuidString: "2239CBA2-CB35-4392-ADC0-24A37D38E010")!
		let baseURL = URL(string: "http://base-url.com")!

		let received = VideoCommentsEndpoint.get(videoID).url(baseURL: baseURL)
		let expected = URL(string: "http://base-url.com/v1/videos/2239CBA2-CB35-4392-ADC0-24A37D38E010/comments")!

		XCTAssertEqual(received, expected)
	}
}
