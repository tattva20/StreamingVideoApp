import XCTest
import StreamingCore

@MainActor
class VideoItemsMapperTests: XCTestCase {

	func test_map_throwsErrorOnNon200HTTPResponse() throws {
		let json = makeItemsJSON([])
		let samples = [199, 201, 300, 400, 500]

		try samples.forEach { code in
			XCTAssertThrowsError(
				try VideoItemsMapper.map(json, from: HTTPURLResponse(statusCode: code))
			)
		}
	}

	func test_map_throwsErrorOn200HTTPResponseWithInvalidJSON() {
		let invalidJSON = Data("invalid json".utf8)

		XCTAssertThrowsError(
			try VideoItemsMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: 200))
		)
	}

	func test_map_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() throws {
		let emptyListJSON = makeItemsJSON([])

		let result = try VideoItemsMapper.map(emptyListJSON, from: HTTPURLResponse(statusCode: 200))

		XCTAssertEqual(result, [])
	}

	func test_map_deliversItemsOn200HTTPResponseWithJSONItems() throws {
		let item1 = makeItem(
			id: UUID(),
			title: "a title",
			description: "a description",
			url: URL(string: "https://any-url.com/video1.mp4")!,
			thumbnailURL: URL(string: "https://any-url.com/thumb1.jpg")!,
			duration: 120)

		let item2 = makeItem(
			id: UUID(),
			title: "another title",
			description: nil,
			url: URL(string: "https://any-url.com/video2.mp4")!,
			thumbnailURL: URL(string: "https://any-url.com/thumb2.jpg")!,
			duration: 240)

		let json = makeItemsJSON([item1.json, item2.json])

		let result = try VideoItemsMapper.map(json, from: HTTPURLResponse(statusCode: 200))

		XCTAssertEqual(result, [item1.model, item2.model])
	}

	// MARK: - Helpers

	private func makeItem(id: UUID, title: String, description: String? = nil, url: URL, thumbnailURL: URL, duration: TimeInterval) -> (model: Video, json: [String: Any]) {
		let item = Video(id: id, title: title, description: description, url: url, thumbnailURL: thumbnailURL, duration: duration)

		let json = [
			"id": id.uuidString,
			"title": title,
			"description": description as Any,
			"url": url.absoluteString,
			"thumbnail_url": thumbnailURL.absoluteString,
			"duration": duration
		].compactMapValues { $0 }

		return (item, json)
	}

	private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["videos": items]
		return try! JSONSerialization.data(withJSONObject: json)
	}

}
