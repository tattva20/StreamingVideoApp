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

final class AVPlayerBufferAdapterTests: XCTestCase {

	// MARK: - Setup/Teardown

	override func tearDown() {
		super.tearDown()
		// Allow pending UIKit/AVFoundation cleanup
		RunLoop.current.run(until: Date())
	}

	// MARK: - applyToNewItem

	func test_applyToNewItem_setsPreferredForwardBufferDuration() async {
		let expectedDuration: TimeInterval = 15.0
		let (sut, bufferManager) = makeSUT()
		let item = AVPlayerItem(url: anyURL())
		await bufferManager.setConfiguration(.init(
			strategy: .balanced,
			preferredForwardBufferDuration: expectedDuration,
			reason: "test"
		))

		await sut.applyToNewItem(item)

		await MainActor.run {
			XCTAssertEqual(item.preferredForwardBufferDuration, expectedDuration)
		}
	}

	func test_applyToNewItem_appliesMinimalBuffer_whenConfiguredForMinimal() async {
		let (sut, bufferManager) = makeSUT()
		let item = AVPlayerItem(url: anyURL())
		await bufferManager.setConfiguration(.minimal)

		await sut.applyToNewItem(item)

		await MainActor.run {
			XCTAssertEqual(item.preferredForwardBufferDuration, 2.0)
		}
	}

	func test_applyToNewItem_appliesAggressiveBuffer_whenConfiguredForAggressive() async {
		let (sut, bufferManager) = makeSUT()
		let item = AVPlayerItem(url: anyURL())
		await bufferManager.setConfiguration(.aggressive)

		await sut.applyToNewItem(item)

		await MainActor.run {
			XCTAssertEqual(item.preferredForwardBufferDuration, 30.0)
		}
	}

	// MARK: - Configuration Updates

	func test_configurationUpdate_appliesNewBufferDuration_toCurrentItem() async {
		let (sut, bufferManager) = makeSUT()
		let item = AVPlayerItem(url: anyURL())

		await MainActor.run {
			sut.player.replaceCurrentItem(with: item)
		}

		await bufferManager.setConfiguration(.init(
			strategy: .conservative,
			preferredForwardBufferDuration: 5.0,
			reason: "test"
		))

		// Allow publisher to propagate
		try? await Task.sleep(nanoseconds: 100_000_000)

		await MainActor.run {
			XCTAssertEqual(sut.player.currentItem?.preferredForwardBufferDuration, 5.0)
		}
	}

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

private actor BufferManagerSpy: BufferManager {
	private nonisolated(unsafe) let configurationSubject = CurrentValueSubject<BufferConfiguration, Never>(.balanced)

	nonisolated var configurationPublisher: AnyPublisher<BufferConfiguration, Never> {
		configurationSubject.eraseToAnyPublisher()
	}

	nonisolated var configurationStream: AsyncStream<BufferConfiguration> {
		AsyncStream { continuation in
			let cancellable = configurationSubject.sink { configuration in
				continuation.yield(configuration)
			}
			continuation.onTermination = { _ in
				cancellable.cancel()
			}
		}
	}

	var currentConfiguration: BufferConfiguration {
		configurationSubject.value
	}

	func setConfiguration(_ configuration: BufferConfiguration) {
		configurationSubject.send(configuration)
	}

	func updateMemoryState(_ state: MemoryState) async {
		// No-op for tests
	}

	func updateNetworkQuality(_ quality: NetworkQuality) async {
		// No-op for tests
	}
}
