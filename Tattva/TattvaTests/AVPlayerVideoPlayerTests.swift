//
//  AVPlayerVideoPlayerTests.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import AVFoundation
import XCTest
@testable import Tattva
@testable import StreamingCorePlayback

@MainActor
final class AVPlayerVideoPlayerTests: XCTestCase {
	func test_duration_isFiniteWhenItemDurationIsIndefinite() {
		let item = AVPlayerItem(url: anyURL())
		let sut = AVPlayerVideoPlayer(player: AVPlayer(playerItem: item))

		XCTAssertTrue(sut.duration.isFinite)
		XCTAssertEqual(sut.duration, 0)
	}

	func test_currentTime_isFiniteForFreshPlayer() {
		let sut = AVPlayerVideoPlayer()

		XCTAssertTrue(sut.currentTime.isFinite)
	}

	// MARK: - Helpers

	private func anyURL() -> URL {
		URL(string: "https://any-url.com/video.mp4")!
	}
}
