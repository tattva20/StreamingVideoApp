//
//  VideoPlayerPerformanceAdapterTests.swift
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
final class VideoPlayerPerformanceAdapterTests: XCTestCase {

	// MARK: - Initialization

	func test_init_doesNotStartObserving() async {
		let (_, performanceService) = makeSUT()

		let sessionID = await performanceService.currentSessionID

		XCTAssertNil(sessionID, "Should not start a session on init")
	}

	// MARK: - Start Monitoring

	func test_startMonitoring_startsPerformanceServiceSession() async {
		let (sut, performanceService) = makeSUT()
		let sessionID = UUID()

		await sut.startMonitoring(sessionID: sessionID)

		let currentSession = await performanceService.currentSessionID
		XCTAssertEqual(currentSession, sessionID)
	}

	func test_startMonitoring_startsPlayerObservation() async {
		let (sut, _) = makeSUT()

		await sut.startMonitoring(sessionID: UUID())

		XCTAssertTrue(sut.isObserving)
	}

	// MARK: - Stop Monitoring

	func test_stopMonitoring_stopsPerformanceServiceSession() async {
		let (sut, performanceService) = makeSUT()
		await sut.startMonitoring(sessionID: UUID())

		await sut.stopMonitoring()

		let currentSession = await performanceService.currentSessionID
		XCTAssertNil(currentSession)
	}

	func test_stopMonitoring_stopsPlayerObservation() async {
		let (sut, _) = makeSUT()
		await sut.startMonitoring(sessionID: UUID())

		await sut.stopMonitoring()

		XCTAssertFalse(sut.isObserving)
	}

	// MARK: - Playback State Translation

	func test_playerStartsPlaying_recordsLoadStartAndFirstFrame() async {
		let (sut, performanceService) = makeSUT()
		await sut.startMonitoring(sessionID: UUID())

		sut.simulatePlaybackStarted()
		try? await Task.sleep(nanoseconds: 100_000_000)

		let events = await performanceService.recordedEvents
		XCTAssertTrue(events.contains(.loadStarted))
		XCTAssertTrue(events.contains(.firstFrameRendered))
	}

	// MARK: - Buffering State Translation

	func test_bufferingStarted_recordsBufferingStartedEvent() async {
		let (sut, performanceService) = makeSUT()
		await sut.startMonitoring(sessionID: UUID())

		sut.simulateBufferingStarted()
		try? await Task.sleep(nanoseconds: 100_000_000)

		let events = await performanceService.recordedEvents
		XCTAssertTrue(events.contains(.bufferingStarted))
	}

	func test_bufferingEnded_recordsBufferingEndedEvent() async {
		let (sut, performanceService) = makeSUT()
		await sut.startMonitoring(sessionID: UUID())

		sut.simulateBufferingEnded()
		try? await Task.sleep(nanoseconds: 100_000_000)

		let events = await performanceService.recordedEvents
		XCTAssertTrue(events.containsBufferingEnded())
	}

	// MARK: - Network Quality Updates

	func test_networkQualityChanged_updatesPerformanceService() async {
		let (sut, performanceService) = makeSUT()
		await sut.startMonitoring(sessionID: UUID())

		await sut.updateNetworkQuality(.poor)

		let events = await performanceService.recordedEvents
		XCTAssertTrue(events.containsNetworkChanged(to: .poor))
	}

	// MARK: - Memory Updates

	func test_memoryPressureChanged_updatesPerformanceService() async {
		let (sut, performanceService) = makeSUT()
		await sut.startMonitoring(sessionID: UUID())

		await sut.updateMemory(usedMB: 500, pressure: .warning)

		let events = await performanceService.recordedEvents
		XCTAssertTrue(events.containsMemoryWarning(level: .warning))
	}

	// MARK: - Bandwidth Updates

	func test_recordBandwidthSample_updatesEstimator() async {
		let (sut, _) = makeSUT()
		await sut.startMonitoring(sessionID: UUID())

		await sut.recordBandwidthSample(bytesTransferred: 1_000_000, duration: 1.0)

		let estimate = await sut.currentBandwidthEstimate
		XCTAssertEqual(estimate.averageBandwidthBps, 8_000_000)
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: VideoPlayerPerformanceAdapter, performanceService: PerformanceMonitorSpy) {
		let performanceService = PerformanceMonitorSpy()
		let bandwidthEstimator = NetworkBandwidthEstimator()
		let sut = VideoPlayerPerformanceAdapter(
			performanceService: performanceService,
			bandwidthEstimator: bandwidthEstimator
		)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, performanceService)
	}
}

// MARK: - Test Helpers

private extension Array where Element == PerformanceEvent {
	func containsBufferingEnded() -> Bool {
		contains { event in
			if case .bufferingEnded = event { return true }
			return false
		}
	}

	func containsNetworkChanged(to quality: NetworkQuality) -> Bool {
		contains { event in
			if case .networkChanged(let q) = event { return q == quality }
			return false
		}
	}

	func containsMemoryWarning(level: MemoryPressureLevel) -> Bool {
		contains { event in
			if case .memoryWarning(let l) = event { return l == level }
			return false
		}
	}
}

// MARK: - Test Doubles

private actor PerformanceMonitorSpy: PerformanceMonitor {
	private var _sessionID: UUID?
	private var _recordedEvents: [PerformanceEvent] = []

	private nonisolated(unsafe) let metricsSubject = PassthroughSubject<PerformanceSnapshot, Never>()
	private nonisolated(unsafe) let alertSubject = PassthroughSubject<PerformanceAlert, Never>()

	nonisolated var metricsPublisher: AnyPublisher<PerformanceSnapshot, Never> {
		metricsSubject.eraseToAnyPublisher()
	}

	nonisolated var alertPublisher: AnyPublisher<PerformanceAlert, Never> {
		alertSubject.eraseToAnyPublisher()
	}

	nonisolated var metricsStream: AsyncStream<PerformanceSnapshot> {
		metricsSubject.toAsyncStream()
	}

	var currentSessionID: UUID? { _sessionID }
	var recordedEvents: [PerformanceEvent] { _recordedEvents }

	func startMonitoring(for sessionID: UUID) {
		_sessionID = sessionID
		_recordedEvents = []
	}

	func stopMonitoring() {
		_sessionID = nil
	}

	func recordEvent(_ event: PerformanceEvent) {
		_recordedEvents.append(event)
	}
}
