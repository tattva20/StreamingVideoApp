//
//  StreamingCoreAPIEndToEndTests.swift
//  StreamingCoreAPIEndToEndTests
//
//  Created by Octavio Rojas on 29/11/25.
//

import XCTest
import StreamingCore

@MainActor
final class StreamingCoreAPIEndToEndTests: XCTestCase {

    // Note: This test hits the real GitHub Pages API
    // It validates the API contract and ensures the endpoint is accessible
    func test_endToEndTestServerGETVideosResult_matchesFixedTestAccountData() async {
        switch await getVideosResult() {
        case let .success(videos)?:
            XCTAssertEqual(videos.count, 5, "Expected 5 videos in the GitHub Pages API")
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

    // MARK: - Helpers

    private func getVideosResult(file: StaticString = #filePath, line: UInt = #line) async -> Result<[Video], Error>? {
        let client = ephemeralClient()
        let loader = RemoteVideoLoader(url: videosTestServerURL, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)

        do {
            let videos = try await loader.load()
            return .success(videos)
        } catch {
            return .failure(error)
        }
    }

    private func ephemeralClient(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        trackForMemoryLeaks(client, file: file, line: line)
        return client
    }

    private var videosTestServerURL: URL {
        // GitHub Pages API with fixed test data
        return URL(string: "https://tattva20.github.io/streaming-videos-api/videos.json")!
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
            "550e8400-e29b-41d4-a716-446655440005"
        ][index])!
    }

    private func title(at index: Int) -> String {
        return [
            "Big Buck Bunny",
            "Elephant Dream",
            "For Bigger Blazes",
            "Sintel",
            "Tears of Steel"
        ][index]
    }

    private func description(at index: Int) -> String? {
        return [
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
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
        ][index])!
    }

    private func thumbnailURL(at index: Int) -> URL {
        return URL(string: [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/330px-Big_buck_bunny_poster_big.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Elephants_Dream_s5_both.jpg/330px-Elephants_Dream_s5_both.jpg",
            "https://via.placeholder.com/330x186/FF6B6B/FFFFFF?text=For+Bigger+Blazes",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Sintel-dragon.jpg/330px-Sintel-dragon.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Manus_%28Tears_of_Steel%29.png/330px-Manus_%28Tears_of_Steel%29.png"
        ][index])!
    }

    private func duration(at index: Int) -> TimeInterval {
        return [596.0, 653.0, 15.0, 888.0, 734.0][index]
    }

}
