//
//  PollingMemoryMonitor.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

public actor PollingMemoryMonitor: MemoryMonitor {
	private let memoryReader: @Sendable () -> MemoryState
	private let thresholds: MemoryThresholds

	private nonisolated(unsafe) let stateSubject = CurrentValueSubject<MemoryState?, Never>(nil)
	private var pollingTask: Task<Void, Never>?
	private var isMonitoring = false

	public nonisolated var statePublisher: AnyPublisher<MemoryState, Never> {
		stateSubject
			.compactMap { $0 }
			.removeDuplicates()
			.eraseToAnyPublisher()
	}

	public nonisolated var stateStream: AsyncStream<MemoryState> {
		statePublisher.toAsyncStream()
	}

	public init(
		memoryReader: @escaping @Sendable () -> MemoryState,
		thresholds: MemoryThresholds = .default
	) {
		self.memoryReader = memoryReader
		self.thresholds = thresholds
	}

	public func currentMemoryState() async -> MemoryState {
		memoryReader()
	}

	public func startMonitoring() async {
		guard !isMonitoring else { return }
		isMonitoring = true

		pollingTask = Task { [weak self, thresholds, memoryReader] in
			while !Task.isCancelled {
				guard let self = self else { break }

				let state = memoryReader()
				await self.updateState(state)

				try? await Task.sleep(nanoseconds: UInt64(thresholds.pollingInterval * 1_000_000_000))
			}
		}
	}

	public func stopMonitoring() async {
		isMonitoring = false
		pollingTask?.cancel()
		pollingTask = nil
	}

	private func updateState(_ state: MemoryState) {
		stateSubject.send(state)
	}
}
