//
//  MemoryMonitorSpy.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation
@testable import StreamingCore

@MainActor
final class MemoryMonitorSpy: MemoryMonitor {
	private var _startMonitoringCallCount = 0
	private var _stopMonitoringCallCount = 0

	private let stateSubject = CurrentValueSubject<MemoryState?, Never>(nil)

	var startMonitoringCallCount: Int { _startMonitoringCallCount }
	var stopMonitoringCallCount: Int { _stopMonitoringCallCount }

	var statePublisher: AnyPublisher<MemoryState, Never> {
		stateSubject
			.compactMap { $0 }
			.eraseToAnyPublisher()
	}

	var stateStream: AsyncStream<MemoryState> {
		statePublisher.toAsyncStream()
	}

	func currentMemoryState() -> MemoryState {
		stateSubject.value ?? makeMemoryState(availableMB: 500)
	}

	func startMonitoring() {
		_startMonitoringCallCount += 1
	}

	func stopMonitoring() {
		_stopMonitoringCallCount += 1
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
