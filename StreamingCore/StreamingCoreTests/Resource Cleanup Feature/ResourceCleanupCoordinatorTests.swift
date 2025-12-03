//
//  ResourceCleanupCoordinatorTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import XCTest
@testable import StreamingCore

final class ResourceCleanupCoordinatorTests: XCTestCase {
	private var cancellables = Set<AnyCancellable>()

	override func tearDown() {
		super.tearDown()
		cancellables.removeAll()
		RunLoop.current.run(until: Date())
	}

	// MARK: - Initialization Tests

	func test_init_sortsCleanersByPriorityDescending() async {
		let lowPriority = ResourceCleanerSpy(name: "Low", priority: .low)
		let highPriority = ResourceCleanerSpy(name: "High", priority: .high)
		let mediumPriority = ResourceCleanerSpy(name: "Medium", priority: .medium)

		let sut = makeSUT(cleaners: [lowPriority, highPriority, mediumPriority])

		// Cleanup all and verify order via cleanup call sequence
		let results = await sut.cleanupAll()

		// Results should be in order: high, medium, low (highest priority first)
		XCTAssertEqual(results.map(\.resourceName), ["High", "Medium", "Low"])
	}

	// MARK: - CleanupAll Tests

	func test_cleanupAll_callsCleanupOnAllCleaners() async {
		let cleaner1 = ResourceCleanerSpy(name: "Cleaner 1", priority: .low)
		let cleaner2 = ResourceCleanerSpy(name: "Cleaner 2", priority: .high)

		let sut = makeSUT(cleaners: [cleaner1, cleaner2])

		_ = await sut.cleanupAll()

		XCTAssertEqual(cleaner1.cleanupCallCount, 1)
		XCTAssertEqual(cleaner2.cleanupCallCount, 1)
	}

	func test_cleanupAll_returnsAllResults() async {
		let cleaner1 = ResourceCleanerSpy(name: "Cache A", priority: .low)
		let cleaner2 = ResourceCleanerSpy(name: "Cache B", priority: .high)

		let sut = makeSUT(cleaners: [cleaner1, cleaner2])

		let results = await sut.cleanupAll()

		XCTAssertEqual(results.count, 2)
	}

	func test_cleanupAll_withNoCleaners_returnsEmptyResults() async {
		let sut = makeSUT(cleaners: [])

		let results = await sut.cleanupAll()

		XCTAssertTrue(results.isEmpty)
	}

	// MARK: - CleanupUpTo Tests

	func test_cleanupUpTo_lowPriority_onlyCleansLowPriorityResources() async {
		let lowCleaner = ResourceCleanerSpy(name: "Low", priority: .low)
		let mediumCleaner = ResourceCleanerSpy(name: "Medium", priority: .medium)
		let highCleaner = ResourceCleanerSpy(name: "High", priority: .high)

		let sut = makeSUT(cleaners: [lowCleaner, mediumCleaner, highCleaner])

		_ = await sut.cleanupUpTo(priority: .low)

		XCTAssertEqual(lowCleaner.cleanupCallCount, 1)
		XCTAssertEqual(mediumCleaner.cleanupCallCount, 0)
		XCTAssertEqual(highCleaner.cleanupCallCount, 0)
	}

	func test_cleanupUpTo_mediumPriority_cleansLowAndMediumResources() async {
		let lowCleaner = ResourceCleanerSpy(name: "Low", priority: .low)
		let mediumCleaner = ResourceCleanerSpy(name: "Medium", priority: .medium)
		let highCleaner = ResourceCleanerSpy(name: "High", priority: .high)

		let sut = makeSUT(cleaners: [lowCleaner, mediumCleaner, highCleaner])

		_ = await sut.cleanupUpTo(priority: .medium)

		XCTAssertEqual(lowCleaner.cleanupCallCount, 1)
		XCTAssertEqual(mediumCleaner.cleanupCallCount, 1)
		XCTAssertEqual(highCleaner.cleanupCallCount, 0)
	}

	func test_cleanupUpTo_highPriority_cleansAllResources() async {
		let lowCleaner = ResourceCleanerSpy(name: "Low", priority: .low)
		let mediumCleaner = ResourceCleanerSpy(name: "Medium", priority: .medium)
		let highCleaner = ResourceCleanerSpy(name: "High", priority: .high)

		let sut = makeSUT(cleaners: [lowCleaner, mediumCleaner, highCleaner])

		_ = await sut.cleanupUpTo(priority: .high)

		XCTAssertEqual(lowCleaner.cleanupCallCount, 1)
		XCTAssertEqual(mediumCleaner.cleanupCallCount, 1)
		XCTAssertEqual(highCleaner.cleanupCallCount, 1)
	}

	// MARK: - Register Tests

	func test_register_addsCleanerToList() async {
		let sut = makeSUT(cleaners: [])
		let newCleaner = ResourceCleanerSpy(name: "New Cleaner", priority: .medium)

		await sut.register(newCleaner)
		let results = await sut.cleanupAll()

		XCTAssertEqual(results.count, 1)
		XCTAssertEqual(results.first?.resourceName, "New Cleaner")
	}

	func test_register_maintainsPriorityOrder() async {
		let lowCleaner = ResourceCleanerSpy(name: "Low", priority: .low)
		let sut = makeSUT(cleaners: [lowCleaner])

		let highCleaner = ResourceCleanerSpy(name: "High", priority: .high)
		await sut.register(highCleaner)

		let results = await sut.cleanupAll()

		// High should be cleaned first
		XCTAssertEqual(results.first?.resourceName, "High")
		XCTAssertEqual(results.last?.resourceName, "Low")
	}

	// MARK: - EstimateTotalCleanup Tests

	func test_estimateTotalCleanup_sumsAllEstimates() async {
		let cleaner1 = ResourceCleanerSpy(name: "Cache A", priority: .low)
		cleaner1.stubEstimate = 1_000_000

		let cleaner2 = ResourceCleanerSpy(name: "Cache B", priority: .high)
		cleaner2.stubEstimate = 2_000_000

		let sut = makeSUT(cleaners: [cleaner1, cleaner2])

		let total = await sut.estimateTotalCleanup()

		XCTAssertEqual(total, 3_000_000)
	}

	func test_estimateTotalCleanup_callsEstimateOnAllCleaners() async {
		let cleaner1 = ResourceCleanerSpy(name: "Cache A", priority: .low)
		let cleaner2 = ResourceCleanerSpy(name: "Cache B", priority: .high)

		let sut = makeSUT(cleaners: [cleaner1, cleaner2])

		_ = await sut.estimateTotalCleanup()

		XCTAssertEqual(cleaner1.estimateCallCount, 1)
		XCTAssertEqual(cleaner2.estimateCallCount, 1)
	}

	func test_estimateTotalCleanup_withNoCleaners_returnsZero() async {
		let sut = makeSUT(cleaners: [])

		let total = await sut.estimateTotalCleanup()

		XCTAssertEqual(total, 0)
	}

	// MARK: - Auto Cleanup Tests

	func test_enableAutoCleanup_startsMemoryMonitoring() async {
		let memoryMonitor = MemoryMonitorSpy()
		let sut = makeSUT(cleaners: [], memoryMonitor: memoryMonitor)

		await sut.enableAutoCleanup()

		XCTAssertEqual(memoryMonitor.startMonitoringCallCount, 1)
	}

	func test_enableAutoCleanup_calledTwice_startsMonitoringOnlyOnce() async {
		let memoryMonitor = MemoryMonitorSpy()
		let sut = makeSUT(cleaners: [], memoryMonitor: memoryMonitor)

		await sut.enableAutoCleanup()
		await sut.enableAutoCleanup()

		XCTAssertEqual(memoryMonitor.startMonitoringCallCount, 1)
	}

	func test_disableAutoCleanup_stopsMemoryMonitoring() async {
		let memoryMonitor = MemoryMonitorSpy()
		let sut = makeSUT(cleaners: [], memoryMonitor: memoryMonitor)

		await sut.enableAutoCleanup()
		await sut.disableAutoCleanup()

		XCTAssertEqual(memoryMonitor.stopMonitoringCallCount, 1)
	}

	// MARK: - Cleanup Results Publisher Tests

	func test_cleanupResultsPublisher_emitsWhenCleanupPerformed() async {
		let cleaner = ResourceCleanerSpy(name: "Test Cache", priority: .medium)
		let sut = makeSUT(cleaners: [cleaner])

		let expectation = expectation(description: "Results emitted")
		var receivedResults: [[CleanupResult]] = []

		sut.cleanupResultsPublisher
			.sink { results in
				receivedResults.append(results)
				expectation.fulfill()
			}
			.store(in: &cancellables)

		await sut.triggerCleanupResults([
			CleanupResult(resourceName: "Test", bytesFreed: 1000, itemsRemoved: 1, success: true)
		])

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedResults.count, 1)
	}

	// MARK: - Sendable Tests

	func test_resourceCleanupCoordinator_isSendable() async {
		let sut: any Sendable = makeSUT(cleaners: [])
		XCTAssertNotNil(sut)
	}

	// MARK: - Helpers

	private func makeSUT(
		cleaners: [ResourceCleaner],
		memoryMonitor: MemoryMonitor? = nil
	) -> ResourceCleanupCoordinator {
		let monitor = memoryMonitor ?? MemoryMonitorSpy()
		return ResourceCleanupCoordinator(cleaners: cleaners, memoryMonitor: monitor)
	}
}
