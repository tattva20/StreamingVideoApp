//
//  PollingMemoryMonitorTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import XCTest
@testable import StreamingCore

final class PollingMemoryMonitorTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
		RunLoop.current.run(until: Date())
	}

	// MARK: - Initialization Tests

	func test_init_doesNotStartMonitoring() async {
		let counter = Counter()
		let _ = makeSUT(memoryReader: {
			counter.increment()
			return self.makeMemoryState()
		})

		await Task.yield()
		try? await Task.sleep(nanoseconds: 100_000_000)

		XCTAssertEqual(counter.value, 0)
	}

	// MARK: - Current Memory State Tests

	func test_currentMemoryState_returnsMemoryFromReader() async {
		let expectedState = makeMemoryState(availableBytes: 123_456_789)
		let sut = makeSUT(memoryReader: { expectedState })

		let state = await sut.currentMemoryState()

		XCTAssertEqual(state, expectedState)
	}

	// MARK: - Start Monitoring Tests

	func test_startMonitoring_beginsPolling() async {
		let counter = Counter()
		let sut = makeSUT(
			memoryReader: {
				counter.increment()
				return self.makeMemoryState()
			},
			pollingInterval: 0.05
		)

		await sut.startMonitoring()
		try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

		XCTAssertGreaterThanOrEqual(counter.value, 2)

		await sut.stopMonitoring()
	}

	func test_startMonitoring_emitsStateViaPublisher() async {
		let expectedState = makeMemoryState(availableBytes: 500_000_000)
		let sut = makeSUT(
			memoryReader: { expectedState },
			pollingInterval: 0.05
		)

		let expectation = expectation(description: "State received")
		var receivedState: MemoryState?

		sut.statePublisher
			.first()
			.sink { state in
				receivedState = state
				expectation.fulfill()
			}
			.store(in: &cancellables)

		await sut.startMonitoring()

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedState, expectedState)

		await sut.stopMonitoring()
	}

	func test_startMonitoring_calledTwice_doesNotCreateDuplicatePolling() async {
		let counter = Counter()
		let sut = makeSUT(
			memoryReader: {
				counter.increment()
				return self.makeMemoryState()
			},
			pollingInterval: 0.05
		)

		await sut.startMonitoring()
		await sut.startMonitoring() // Second call should be ignored

		try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

		// Should have roughly 2-3 reads, not double
		XCTAssertLessThan(counter.value, 6)

		await sut.stopMonitoring()
	}

	// MARK: - Stop Monitoring Tests

	func test_stopMonitoring_stopsPolling() async {
		let counter = Counter()
		let sut = makeSUT(
			memoryReader: {
				counter.increment()
				return self.makeMemoryState()
			},
			pollingInterval: 0.05
		)

		await sut.startMonitoring()
		try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

		await sut.stopMonitoring()

		let countAfterStop = counter.value
		try? await Task.sleep(nanoseconds: 150_000_000) // 150ms more

		// Allow tolerance of 1 additional read due to race condition between stop and last poll
		XCTAssertLessThanOrEqual(counter.value, countAfterStop + 1, "Read count should not increase significantly after stop")
	}

	func test_stopMonitoring_calledWithoutStart_doesNothing() async {
		let sut = makeSUT()

		await sut.stopMonitoring()

		// Should not crash or have any side effects
	}

	// MARK: - State Stream Tests

	func test_stateStream_emitsStatesFromPublisher() async {
		let expectedState = makeMemoryState(availableBytes: 300_000_000)
		let sut = makeSUT(
			memoryReader: { expectedState },
			pollingInterval: 0.05
		)

		await sut.startMonitoring()

		var receivedState: MemoryState?
		for await state in sut.stateStream.prefix(1) {
			receivedState = state
		}

		XCTAssertEqual(receivedState, expectedState)

		await sut.stopMonitoring()
	}

	// MARK: - Duplicate State Filtering Tests

	func test_statePublisher_removeDuplicates() async {
		let counter = Counter()
		let constantState = makeMemoryState(availableBytes: 500_000_000)
		let sut = makeSUT(
			memoryReader: {
				counter.increment()
				return constantState
			},
			pollingInterval: 0.05
		)

		var receivedCount = 0
		sut.statePublisher
			.sink { _ in receivedCount += 1 }
			.store(in: &cancellables)

		await sut.startMonitoring()
		try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

		await sut.stopMonitoring()

		// Memory reader called multiple times, but publisher should emit only once (due to removeDuplicates)
		XCTAssertGreaterThan(counter.value, 2)
		XCTAssertEqual(receivedCount, 1)
	}

	// MARK: - Memory Pressure Level Tests

	func test_emittedState_hasCorrectPressureLevel() async {
		let lowMemoryState = makeMemoryState(availableBytes: 40_000_000) // 40MB = critical
		let thresholds = MemoryThresholds.default
		let sut = makeSUT(
			memoryReader: { lowMemoryState },
			thresholds: thresholds,
			pollingInterval: 0.05
		)

		let expectation = expectation(description: "State received")
		var receivedState: MemoryState?

		sut.statePublisher
			.first()
			.sink { state in
				receivedState = state
				expectation.fulfill()
			}
			.store(in: &cancellables)

		await sut.startMonitoring()

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedState?.pressureLevel(thresholds: thresholds), .critical)

		await sut.stopMonitoring()
	}

	// MARK: - Sendable Tests

	func test_pollingMemoryMonitor_isSendable() async {
		let sut: any Sendable = makeSUT()
		XCTAssertNotNil(sut)
	}

	// MARK: - Helpers

	private func makeSUT(
		memoryReader: @escaping @Sendable () -> MemoryState = { MemoryState(availableBytes: 500_000_000, totalBytes: 4_000_000_000, usedBytes: 3_500_000_000, timestamp: Date()) },
		thresholds: MemoryThresholds = .default,
		pollingInterval: TimeInterval = 2.0
	) -> PollingMemoryMonitor {
		let adjustedThresholds = MemoryThresholds(
			warningAvailableMB: thresholds.warningAvailableMB,
			criticalAvailableMB: thresholds.criticalAvailableMB,
			pollingInterval: pollingInterval
		)

		return PollingMemoryMonitor(
			memoryReader: memoryReader,
			thresholds: adjustedThresholds
		)
	}

	private func makeMemoryState(
		availableBytes: UInt64 = 500_000_000,
		totalBytes: UInt64 = 4_000_000_000,
		usedBytes: UInt64 = 3_500_000_000,
		timestamp: Date = Date()
	) -> MemoryState {
		MemoryState(
			availableBytes: availableBytes,
			totalBytes: totalBytes,
			usedBytes: usedBytes,
			timestamp: timestamp
		)
	}
}

// MARK: - Thread-Safe Counter for Testing

private final class Counter: @unchecked Sendable {
	private var _value: Int = 0
	private let lock = NSLock()

	var value: Int {
		lock.lock()
		defer { lock.unlock() }
		return _value
	}

	func increment() {
		lock.lock()
		defer { lock.unlock() }
		_value += 1
	}
}
