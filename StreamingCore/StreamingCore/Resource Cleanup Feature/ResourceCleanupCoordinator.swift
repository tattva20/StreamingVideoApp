//
//  ResourceCleanupCoordinator.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

public actor ResourceCleanupCoordinator {
	private var cleaners: [ResourceCleaner]
	private let memoryMonitor: MemoryMonitor
	private var isAutoCleanupEnabled = false
	private var monitoringTask: Task<Void, Never>?

	private nonisolated(unsafe) let cleanupSubject = PassthroughSubject<[CleanupResult], Never>()

	public nonisolated var cleanupResultsPublisher: AnyPublisher<[CleanupResult], Never> {
		cleanupSubject.eraseToAnyPublisher()
	}

	public init(cleaners: [ResourceCleaner], memoryMonitor: MemoryMonitor) {
		// Sort by priority (highest first for cleanup)
		self.cleaners = cleaners.sorted { $0.priority > $1.priority }
		self.memoryMonitor = memoryMonitor
	}

	public func register(_ cleaner: ResourceCleaner) {
		cleaners.append(cleaner)
		cleaners.sort { $0.priority > $1.priority }
	}

	public func enableAutoCleanup() async {
		guard !isAutoCleanupEnabled else { return }
		isAutoCleanupEnabled = true

		await memoryMonitor.startMonitoring()

		monitoringTask = Task { [weak self] in
			guard let self = self else { return }

			for await state in await self.memoryMonitor.stateStream {
				guard !Task.isCancelled else { break }

				let thresholds = MemoryThresholds.default
				let pressureLevel = state.pressureLevel(thresholds: thresholds)

				switch pressureLevel {
				case .critical:
					// Critical: Clean everything possible
					let results = await self.cleanupAll()
					await self.triggerCleanupResults(results)

				case .warning:
					// Warning: Clean low and medium priority only
					let results = await self.cleanupUpTo(priority: .medium)
					if !results.isEmpty {
						await self.triggerCleanupResults(results)
					}

				case .normal:
					break // No cleanup needed
				}
			}
		}
	}

	public func disableAutoCleanup() async {
		isAutoCleanupEnabled = false
		monitoringTask?.cancel()
		monitoringTask = nil
		await memoryMonitor.stopMonitoring()
	}

	/// Clean all registered resources (highest priority first)
	public func cleanupAll() async -> [CleanupResult] {
		var results: [CleanupResult] = []

		for cleaner in cleaners {
			let result = await cleaner.cleanup()
			results.append(result)
		}

		return results
	}

	/// Clean resources up to and including specified priority
	public func cleanupUpTo(priority: CleanupPriority) async -> [CleanupResult] {
		var results: [CleanupResult] = []

		for cleaner in cleaners where cleaner.priority <= priority {
			let result = await cleaner.cleanup()
			results.append(result)
		}

		return results
	}

	/// Estimate total bytes that could be freed
	public func estimateTotalCleanup() async -> UInt64 {
		var total: UInt64 = 0
		for cleaner in cleaners {
			total += await cleaner.estimateCleanup()
		}
		return total
	}

	/// Trigger cleanup results through the publisher (for testing and manual triggers)
	public func triggerCleanupResults(_ results: [CleanupResult]) {
		cleanupSubject.send(results)
	}
}
