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

    // Note: This test requires a test server at the specified URL with fixed video data.
    // The test is currently disabled (prefixed with DISABLED_) until a test server is available.
    // When a test server becomes available, rename this method to remove the DISABLED_ prefix.
    func DISABLED_test_endToEndTestServerGETVideosResult_matchesFixedTestAccountData() async {
        switch await getVideosResult() {
        case let .success(videos)?:
            XCTAssertEqual(videos.count, 3, "Expected 3 videos in the test account data")
            XCTAssertEqual(videos[0], expectedVideo(at: 0))
            XCTAssertEqual(videos[1], expectedVideo(at: 1))
            XCTAssertEqual(videos[2], expectedVideo(at: 2))

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
        // TODO: Replace with actual test server URL when available
        return URL(string: "https://example.com/test-api/videos")!
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
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C"
        ][index])!
    }

    private func title(at index: Int) -> String {
        return [
            "Big Buck Bunny",
            "Elephant Dream",
            "For Bigger Blazes"
        ][index]
    }

    private func description(at index: Int) -> String? {
        return [
            "A short computer-animated comedy film",
            "The first Blender open movie",
            "Sample video for testing"
        ][index]
    }

    private func videoURL(at index: Int) -> URL {
        return URL(string: [
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
        ][index])!
    }

    private func thumbnailURL(at index: Int) -> URL {
        return URL(string: [
            "https://via.placeholder.com/150/1",
            "https://via.placeholder.com/150/2",
            "https://via.placeholder.com/150/3"
        ][index])!
    }

    private func duration(at index: Int) -> TimeInterval {
        return [596, 653, 15][index]
    }

}
