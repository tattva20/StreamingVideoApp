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

	// MARK: - Start Monitoring

//	func test_startMonitoring_startsPerformanceServiceSession() {
//		let (sut, performanceService) = makeSUT()
//		let sessionID = UUID()
//
//		sut.startMonitoring(sessionID: sessionID)
//
//		XCTAssertEqual(performanceService.currentSessionID, sessionID)
//	}

//	func test_startMonitoring_startsPlayerObservation() {
//		let (sut, _) = makeSUT()
//
//		sut.startMonitoring(sessionID: UUID())
//
//		XCTAssertTrue(sut.isObserving)
//	}

	// MARK: - Network Quality Updates

//	func test_networkQualityChanged_updatesPerformanceService() {
//		let (sut, performanceService) = makeSUT()
//		sut.startMonitoring(sessionID: UUID())
//
//		sut.updateNetworkQuality(.poor)
//
//		XCTAssertTrue(performanceService.recordedEvents.containsNetworkChanged(to: .poor))
//	}

	// MARK: - Memory Updates

//	func test_memoryPressureChanged_updatesPerformanceService() {
//		let (sut, performanceService) = makeSUT()
//		sut.startMonitoring(sessionID: UUID())
//
//		sut.updateMemory(usedMB: 500, pressure: .warning)
//
//		XCTAssertTrue(performanceService.recordedEvents.containsMemoryWarning(level: .warning))
//	}

	// MARK: - Bandwidth Updates

//	func test_recordBandwidthSample_updatesEstimator() {
//		let (sut, _) = makeSUT()
//		sut.startMonitoring(sessionID: UUID())
//
//		sut.recordBandwidthSample(bytesTransferred: 1_000_000, duration: 1.0)
//
//		XCTAssertEqual(sut.currentBandwidthEstimate.averageBandwidthBps, 8_000_000)
//	}

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
		return (sut, performanceService)
	}
}

// MARK: - Test Helpers

private extension Array where Element == PerformanceEvent {
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

@MainActor
private final class PerformanceMonitorSpy: PerformanceMonitor {
	private var _sessionID: UUID?
	private var _recordedEvents: [PerformanceEvent] = []

	var metricsPublisher: AnyPublisher<PerformanceSnapshot, Never> {
		Empty().eraseToAnyPublisher()
	}

	var alertPublisher: AnyPublisher<PerformanceAlert, Never> {
		Empty().eraseToAnyPublisher()
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
