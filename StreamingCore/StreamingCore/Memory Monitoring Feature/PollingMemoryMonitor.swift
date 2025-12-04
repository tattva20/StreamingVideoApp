//
//  PollingMemoryMonitor.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

/// Thread-safe @MainActor class implementation of memory monitoring.
/// Uses @MainActor isolation following Essential Feed patterns for thread-safety.
@MainActor
public final class PollingMemoryMonitor: MemoryMonitor {
	private let memoryReader: () -> MemoryState
	private let thresholds: MemoryThresholds

	private let stateSubject = CurrentValueSubject<MemoryState?, Never>(nil)
	private var pollingTask: Task<Void, Never>?
	private var isMonitoring = false

	public var statePublisher: AnyPublisher<MemoryState, Never> {
		stateSubject
			.compactMap { $0 }
			.removeDuplicates()
			.eraseToAnyPublisher()
	}

	public var stateStream: AsyncStream<MemoryState> {
		statePublisher.toAsyncStream()
	}

	public init(
		memoryReader: @escaping @Sendable () -> MemoryState,
		thresholds: MemoryThresholds = .default
	) {
		self.memoryReader = memoryReader
		self.thresholds = thresholds
	}

	public func currentMemoryState() -> MemoryState {
		memoryReader()
	}

	public func startMonitoring() {
		guard !isMonitoring else { return }
		isMonitoring = true

		pollingTask = Task { [weak self, thresholds, memoryReader] in
			while !Task.isCancelled {
				guard let self = self else { break }

				let state = memoryReader()
				await MainActor.run {
					self.updateState(state)
				}

				try? await Task.sleep(nanoseconds: UInt64(thresholds.pollingInterval * 1_000_000_000))
			}
		}
	}

	public func stopMonitoring() {
		isMonitoring = false
		pollingTask?.cancel()
		pollingTask = nil
	}

	private func updateState(_ state: MemoryState) {
		stateSubject.send(state)
	}
}
