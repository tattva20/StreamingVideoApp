//
//  BufferManagerIntegrationTests.swift
//  StreamingVideoAppTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import XCTest
import StreamingCore
@testable import StreamingVideoApp

@MainActor
final class BufferManagerIntegrationTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
		RunLoop.current.run(until: Date())
	}

	// MARK: - SceneDelegate Integration Tests

	func test_sceneDelegate_hasBufferManagerConfigured() {
		let sut = SceneDelegate()

		XCTAssertNotNil(sut.bufferManager, "Expected SceneDelegate to have a configured buffer manager")
	}

	func test_bufferManager_respondsToMemoryPressure() async {
		let memoryMonitor = MemoryMonitorSpy()
		let bufferManager = AdaptiveBufferManager()
		let sut = makeSceneDelegate(memoryMonitor: memoryMonitor, bufferManager: bufferManager)

		let expectation = expectation(description: "Buffer configuration changed")
		sut.bufferManager.configurationPublisher
			.dropFirst() // Skip initial value
			.first()
			.sink { _ in
				expectation.fulfill()
			}
			.store(in: &cancellables)

		sut.startBufferManagerMemoryBinding()

		// Simulate critical memory pressure
		let criticalState = makeMemoryState(availableMB: 40)
		memoryMonitor.simulateMemoryState(criticalState)

		await fulfillment(of: [expectation], timeout: 2.0)

		XCTAssertEqual(sut.bufferManager.currentConfiguration.strategy, .minimal, "Expected minimal buffer strategy on critical memory pressure")
	}

	func test_bufferManager_startsWithBalancedConfiguration() {
		let sut = SceneDelegate()

		XCTAssertEqual(sut.bufferManager.currentConfiguration.strategy, .balanced, "Expected buffer manager to start with balanced configuration")
	}

	// MARK: - Helpers

	private func makeSceneDelegate(
		memoryMonitor: MemoryMonitorSpy,
		bufferManager: AdaptiveBufferManager
	) -> TestableSceneDelegate {
		TestableSceneDelegate(
			memoryMonitor: memoryMonitor,
			bufferManager: bufferManager
		)
	}

	private func makeMemoryState(availableMB: Double) -> MemoryState {
		let availableBytes = UInt64(availableMB * 1_048_576)
		let totalBytes: UInt64 = 4_000_000_000
		return MemoryState(
			availableBytes: availableBytes,
			totalBytes: totalBytes,
			usedBytes: totalBytes - availableBytes,
			timestamp: Date()
		)
	}
}

// MARK: - Test Doubles

@MainActor
private final class MemoryMonitorSpy: MemoryMonitor {
	private let stateSubject = CurrentValueSubject<MemoryState?, Never>(nil)

	var statePublisher: AnyPublisher<MemoryState, Never> {
		stateSubject
			.compactMap { $0 }
			.eraseToAnyPublisher()
	}

	func currentMemoryState() -> MemoryState {
		stateSubject.value ?? MemoryState(
			availableBytes: 500_000_000,
			totalBytes: 4_000_000_000,
			usedBytes: 3_500_000_000,
			timestamp: Date()
		)
	}

	func startMonitoring() {}
	func stopMonitoring() {}

	func simulateMemoryState(_ state: MemoryState) {
		stateSubject.send(state)
	}
}

@MainActor
private final class TestableSceneDelegate {
	let memoryMonitor: MemoryMonitorSpy
	let bufferManager: AdaptiveBufferManager
	private var cancellables = Set<AnyCancellable>()

	init(memoryMonitor: MemoryMonitorSpy, bufferManager: AdaptiveBufferManager) {
		self.memoryMonitor = memoryMonitor
		self.bufferManager = bufferManager
	}

	func startBufferManagerMemoryBinding() {
		memoryMonitor.statePublisher
			.sink { [bufferManager] state in
				bufferManager.updateMemoryState(state)
			}
			.store(in: &cancellables)
	}
}
