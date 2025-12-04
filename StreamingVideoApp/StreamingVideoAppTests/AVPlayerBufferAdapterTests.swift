//
//  AVPlayerBufferAdapterTests.swift
//  StreamingVideoAppTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import XCTest
@testable import StreamingCore
@testable import StreamingVideoApp

@MainActor
final class AVPlayerBufferAdapterTests: XCTestCase {

	// MARK: - Setup/Teardown

	override func tearDown() {
		super.tearDown()
	}

	// MARK: - applyToNewItem

//	func test_applyToNewItem_setsPreferredForwardBufferDuration() {
//		let expectedDuration: TimeInterval = 15.0
//		let (sut, bufferManager) = makeSUT()
//		let item = AVPlayerItem(url: anyURL())
//		bufferManager.setConfiguration(.init(
//			strategy: .balanced,
//			preferredForwardBufferDuration: expectedDuration,
//			reason: "test"
//		))
//
//		sut.applyToNewItem(item)
//
//		XCTAssertEqual(item.preferredForwardBufferDuration, expectedDuration)
//	}

//	func test_applyToNewItem_appliesMinimalBuffer_whenConfiguredForMinimal() async {
//		let (sut, bufferManager) = makeSUT()
//		let item = AVPlayerItem(url: anyURL())
//		bufferManager.setConfiguration(.minimal)
//
//		await sut.applyToNewItem(item)
//
//		XCTAssertEqual(item.preferredForwardBufferDuration, 2.0)
//	}

//	func test_applyToNewItem_appliesAggressiveBuffer_whenConfiguredForAggressive() async {
//		let (sut, bufferManager) = makeSUT()
//		let item = AVPlayerItem(url: anyURL())
//		bufferManager.setConfiguration(.aggressive)
//
//		await sut.applyToNewItem(item)
//
//		XCTAssertEqual(item.preferredForwardBufferDuration, 30.0)
//	}

	// MARK: - Configuration Updates

//	func test_configurationUpdate_appliesNewBufferDuration_toCurrentItem() async {
//		let (sut, bufferManager) = makeSUT()
//		let item = AVPlayerItem(url: anyURL())
//
//		sut.player.replaceCurrentItem(with: item)
//
//		bufferManager.setConfiguration(.init(
//			strategy: .conservative,
//			preferredForwardBufferDuration: 5.0,
//			reason: "test"
//		))
//
//		// Allow publisher to propagate
//		try? await Task.sleep(nanoseconds: 100_000_000)
//
//		XCTAssertEqual(sut.player.currentItem?.preferredForwardBufferDuration, 5.0)
//	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: AVPlayerBufferAdapter, bufferManager: BufferManagerSpy) {
		let player = AVPlayer()
		let bufferManager = BufferManagerSpy()
		let sut = AVPlayerBufferAdapter(player: player, bufferManager: bufferManager)

		return (sut, bufferManager)
	}

	private func anyURL() -> URL {
		URL(string: "https://example.com/video.mp4")!
	}
}

// MARK: - Test Doubles

@MainActor
private final class BufferManagerSpy: BufferManager {
	private let configurationSubject = CurrentValueSubject<BufferConfiguration, Never>(.balanced)

	var configurationPublisher: AnyPublisher<BufferConfiguration, Never> {
		configurationSubject.eraseToAnyPublisher()
	}

	var configurationStream: AsyncStream<BufferConfiguration> {
		configurationPublisher.toAsyncStream()
	}

	var currentConfiguration: BufferConfiguration {
		configurationSubject.value
	}

	func setConfiguration(_ configuration: BufferConfiguration) {
		configurationSubject.send(configuration)
	}

	func updateMemoryState(_ state: MemoryState) {
		// No-op for tests
	}

	func updateNetworkQuality(_ quality: NetworkQuality) {
		// No-op for tests
	}
}
