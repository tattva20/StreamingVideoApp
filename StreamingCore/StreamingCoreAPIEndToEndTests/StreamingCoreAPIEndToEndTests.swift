//
//  StreamingCoreAPIEndToEndTests.swift
//  StreamingCoreAPIEndToEndTests
//
//  Created by Octavio Rojas on 29/11/25.
//

import XCTest
import StreamingCore

@MainActor
class StreamingCoreAPIEndToEndTests: XCTestCase {

	func test_endToEndTestServerGETVideosResult_matchesFixedTestAccountData() async {
		switch await getVideosResult() {
		case let .success(videos)?:
			XCTAssertEqual(videos.count, 10, "Expected 10 videos in the first page of Vercel API")
			XCTAssertEqual(videos[0], expectedVideo(at: 0))
			XCTAssertEqual(videos[1], expectedVideo(at: 1))
			XCTAssertEqual(videos[2], expectedVideo(at: 2))
			XCTAssertEqual(videos[3], expectedVideo(at: 3))
			XCTAssertEqual(videos[4], expectedVideo(at: 4))

		case let .failure(error)?:
			XCTFail("Expected successful videos result, got \(error) instead")

		default:
			XCTFail("Expected successful videos result, got no result instead")
		}
	}

	func test_endToEndTestServerGETVideoImageDataResult_matchesFixedTestAccountData() async {
		switch await getVideoImageDataResult() {
		case let .success(data)?:
			XCTAssertFalse(data.isEmpty, "Expected non-empty image data")

		case let .failure(error)?:
			XCTFail("Expected successful image data result, got \(error) instead")

		default:
			XCTFail("Expected successful image data result, got no result instead")
		}
	}

	// MARK: - Helpers

	private func getVideosResult(file: StaticString = #filePath, line: UInt = #line) async -> Swift.Result<[Video], Error>? {
		let client = ephemeralClient()

		do {
			let (data, response) = try await client.get(from: videosTestServerURL)
			return .success(try VideoItemsMapper.map(data, from: response))
		} catch {
			return .failure(error)
		}
	}

	private func getVideoImageDataResult(file: StaticString = #filePath, line: UInt = #line) async -> Result<Data, Error>? {
		let client = ephemeralClient()
		let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg")!

		do {
			let (data, response) = try await client.get(from: url)
			return .success(try VideoImageDataMapper.map(data, from: response))
		} catch {
			return .failure(error)
		}
	}

	private var videosTestServerURL: URL {
		// Vercel API with pagination support
		return URL(string: "https://streaming-videos-ejci3r0dw-financieraufc-5358s-projects.vercel.app/v1/videos?limit=10")!
	}

	private func ephemeralClient(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
		let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
		trackForMemoryLeaks(client, file: file, line: line)
		return client
	}

	private func expectedVideo(at index: Int) -> Video {
		return Video(
			id: id(at: index),
			title: title(at: index),
			description: description(at: index),
			url: videoURL(at: index),
			thumbnailURL: thumbnailURL(at: index),
			duration: duration(at: index)
		)
	}

	private func id(at index: Int) -> UUID {
		return UUID(uuidString: [
			"550e8400-e29b-41d4-a716-446655440001",
			"550e8400-e29b-41d4-a716-446655440002",
			"550e8400-e29b-41d4-a716-446655440003",
			"550e8400-e29b-41d4-a716-446655440004",
			"550e8400-e29b-41d4-a716-446655440005",
			"550e8400-e29b-41d4-a716-446655440006",
			"550e8400-e29b-41d4-a716-446655440007",
			"550e8400-e29b-41d4-a716-446655440008",
			"550e8400-e29b-41d4-a716-446655440009",
			"550e8400-e29b-41d4-a716-446655440010"
		][index])!
	}

	private func title(at index: Int) -> String {
		return [
			"Big Buck Bunny",
			"Elephant Dream",
			"For Bigger Blazes",
			"Sintel",
			"Tears of Steel",
			"Big Buck Bunny 2",
			"Elephant Dream 2",
			"For Bigger Blazes 2",
			"Sintel 2",
			"Tears of Steel 2"
		][index]
	}

	private func description(at index: Int) -> String? {
		return [
			"A large and lovable rabbit deals with three tiny bullies, led by a flying squirrel, who are determined to squelch his happiness.",
			"The first Blender open movie project. Two men navigate through a surreal, mechanical world.",
			"HBO GO now works with Chromecast. Streaming entertainment has never been easier.",
			"A lonely young woman, Sintel, helps and befriends a dragon, whom she calls Scales.",
			"A group of warriors and scientists battle to protect their city against robots in a future Amsterdam.",
			"A large and lovable rabbit deals with three tiny bullies, led by a flying squirrel, who are determined to squelch his happiness.",
			"The first Blender open movie project. Two men navigate through a surreal, mechanical world.",
			"HBO GO now works with Chromecast. Streaming entertainment has never been easier.",
			"A lonely young woman, Sintel, helps and befriends a dragon, whom she calls Scales.",
			"A group of warriors and scientists battle to protect their city against robots in a future Amsterdam."
		][index]
	}

	private func videoURL(at index: Int) -> URL {
		return URL(string: [
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
		][index])!
	}

	private func thumbnailURL(at index: Int) -> URL {
		return URL(string: [
			"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/330px-Big_buck_bunny_poster_big.jpg",
			"https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Elephants_Dream_s5_both.jpg/330px-Elephants_Dream_s5_both.jpg",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg",
			"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/330px-Big_buck_bunny_poster_big.jpg",
			"https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Elephants_Dream_s5_both.jpg/330px-Elephants_Dream_s5_both.jpg",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg",
			"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg"
		][index])!
	}

	private func duration(at index: Int) -> TimeInterval {
		return [596.0, 653.0, 15.0, 888.0, 734.0, 596.0, 653.0, 15.0, 888.0, 734.0][index]
	}
}

extension StreamingCoreAPIEndToEndTests {
	func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}
}