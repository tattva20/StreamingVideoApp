//
//  PerformanceMonitoringIntegrationTests.swift
//  StreamingVideoAppTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import Combine
import StreamingCore
import StreamingCoreiOS
@testable import StreamingVideoApp

@MainActor
final class PerformanceMonitoringIntegrationTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		RunLoop.current.run(until: Date())
	}

	// MARK: - VideoPlayerUIComposer Integration Tests

	func test_videoPlayerComposedWith_createsControllerWithPerformanceAdapter() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertNotNil(controller.performanceAdapter, "Expected VideoPlayerViewController to have a performance adapter after composition")
	}

	func test_videoPlayerComposedWith_startsPerformanceMonitoringOnCreation() {
		let video = makeVideo()

		let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)

		XCTAssertTrue(controller.performanceAdapter?.isObserving == true, "Expected performance monitoring to be started after composition")
	}

	func test_performanceAdapter_stopsMonitoringWhenControllerDeallocates() async {
		let video = makeVideo()
		weak var weakAdapter: VideoPlayerPerformanceAdapter?

		autoreleasepool {
			let controller = VideoPlayerUIComposer.videoPlayerComposedWith(video: video)
			weakAdapter = controller.performanceAdapter
			XCTAssertNotNil(weakAdapter)
		}

		// Allow deallocation to complete
		await Task.yield()
		try? await Task.sleep(nanoseconds: 100_000_000)
		RunLoop.current.run(until: Date())

		// The adapter should be deallocated with the controller
		XCTAssertNil(weakAdapter, "Expected performance adapter to be deallocated when controller is deallocated")
	}

	// MARK: - Helpers

	private func makeVideo() -> Video {
		Video(
			id: UUID(),
			title: "Test Video",
			description: "Test Description",
			url: URL(string: "https://example.com/video.mp4")!,
			thumbnailURL: URL(string: "https://example.com/image.jpg")!,
			duration: 120
		)
	}
}
