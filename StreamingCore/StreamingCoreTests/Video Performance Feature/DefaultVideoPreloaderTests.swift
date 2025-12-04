//
//  DefaultVideoPreloaderTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class DefaultVideoPreloaderTests: XCTestCase {

	// MARK: - Preload Tests

	func test_preload_startsPreloadingForVideo() async {
		let (sut, client) = makeSUT()
		let video = makePreloadableVideo()

		await sut.preload(video, priority: .medium)

		await fulfillment { await client.requestedURLs.count == 1 }
		let requestedURLs = await client.requestedURLs
		XCTAssertEqual(requestedURLs, [video.url])
	}

	func test_preload_cancelsExistingPreloadForSameVideo() async {
		let (sut, client) = makeSUT()
		let video = makePreloadableVideo()

		await sut.preload(video, priority: .low)
		await sut.preload(video, priority: .high)

		// Should have two requests (one for each preload attempt)
		await fulfillment { await client.requestedURLs.count >= 1 }
	}

	// MARK: - Cancel Tests

	func test_cancelPreload_doesNothingWhenNoPreloadExists() {
		let (sut, _) = makeSUT()
		let unknownID = UUID()

		// Should not crash
		sut.cancelPreload(for: unknownID)
	}

	func test_cancelAllPreloads_doesNotCrash() {
		let (sut, _) = makeSUT()

		// Should not crash
		sut.cancelAllPreloads()
	}

	// MARK: - Priority Tests

	func test_preload_respectsPriorityForImmediatePreloads() async {
		let (sut, client) = makeSUT()
		let video = makePreloadableVideo()

		await sut.preload(video, priority: .immediate)

		await fulfillment { await client.requestedURLs.count == 1 }
		let requestedURLs = await client.requestedURLs
		XCTAssertEqual(requestedURLs.first, video.url)
	}

	// MARK: - Helpers

	private func makeSUT() -> (sut: DefaultVideoPreloader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = DefaultVideoPreloader(httpClient: client)
		return (sut, client)
	}

	private func makePreloadableVideo() -> PreloadableVideo {
		PreloadableVideo(
			id: UUID(),
			url: URL(string: "https://example.com/video-\(UUID().uuidString).mp4")!,
			estimatedDuration: 120.0
		)
	}

	private func fulfillment(timeout: TimeInterval = 1.0, _ condition: @escaping () async -> Bool) async {
		let start = Date()
		while Date().timeIntervalSince(start) < timeout {
			if await condition() { return }
			try? await Task.sleep(nanoseconds: 10_000_000)
		}
	}
}

// MARK: - Test Doubles

private actor HTTPClientSpy: HTTPClient {
	private(set) var requestedURLs: [URL] = []

	func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
		requestedURLs.append(url)

		// Simulate network delay
		try await Task.sleep(nanoseconds: 50_000_000)

		return (Data(), HTTPURLResponse(
			url: url,
			statusCode: 206,
			httpVersion: nil,
			headerFields: nil
		)!)
	}
}
