//
//  MemoryMonitorSpy.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation
@testable import StreamingCore

final class MemoryMonitorSpy: MemoryMonitor, @unchecked Sendable {
	private let lock = NSLock()
	private var _startMonitoringCallCount = 0
	private var _stopMonitoringCallCount = 0

	private nonisolated(unsafe) let stateSubject = CurrentValueSubject<MemoryState?, Never>(nil)

	var startMonitoringCallCount: Int {
		lock.lock()
		defer { lock.unlock() }
		return _startMonitoringCallCount
	}

	var stopMonitoringCallCount: Int {
		lock.lock()
		defer { lock.unlock() }
		return _stopMonitoringCallCount
	}

	var statePublisher: AnyPublisher<MemoryState, Never> {
		stateSubject
			.compactMap { $0 }
			.eraseToAnyPublisher()
	}

	var stateStream: AsyncStream<MemoryState> {
		statePublisher.toAsyncStream()
	}

	func currentMemoryState() async -> MemoryState {
		stateSubject.value ?? makeMemoryState(availableMB: 500)
	}

	func startMonitoring() async {
		lock.lock()
		_startMonitoringCallCount += 1
		lock.unlock()
	}

	func stopMonitoring() async {
		lock.lock()
		_stopMonitoringCallCount += 1
		lock.unlock()
	}

	func simulateMemoryState(_ state: MemoryState) {
		stateSubject.send(state)
	}

	private func makeMemoryState(availableMB: Double) -> MemoryState {
		let availableBytes = UInt64(availableMB * 1_048_576)
		return MemoryState(
			availableBytes: availableBytes,
			totalBytes: 4_000_000_000,
			usedBytes: 4_000_000_000 - availableBytes,
			timestamp: Date()
		)
	}
}
