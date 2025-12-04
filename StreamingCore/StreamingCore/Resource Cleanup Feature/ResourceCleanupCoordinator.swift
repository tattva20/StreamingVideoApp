//
//  ResourceCleanupCoordinator.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

/// Thread-safe @MainActor class implementation of resource cleanup coordination.
/// Uses @MainActor isolation for thread-safety.
@MainActor
public final class ResourceCleanupCoordinator {
	private var cleaners: [ResourceCleaner]
	private let memoryMonitor: MemoryMonitor
	private var isAutoCleanupEnabled = false
	private var monitoringCancellable: AnyCancellable?

	private let cleanupSubject = PassthroughSubject<[CleanupResult], Never>()

	public var cleanupResultsPublisher: AnyPublisher<[CleanupResult], Never> {
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

	public func enableAutoCleanup() {
		guard !isAutoCleanupEnabled else { return }
		isAutoCleanupEnabled = true

		memoryMonitor.startMonitoring()

		monitoringCancellable = memoryMonitor.statePublisher
			.receive(on: RunLoop.main)
			.sink { [weak self] state in
				guard let self = self else { return }

				let thresholds = MemoryThresholds.default
				let pressureLevel = state.pressureLevel(thresholds: thresholds)

				Task { @MainActor [weak self] in
					guard let self = self else { return }

					switch pressureLevel {
					case .critical:
						// Critical: Clean everything possible
						let results = await self.cleanupAll()
						self.triggerCleanupResults(results)

					case .warning:
						// Warning: Clean low and medium priority only
						let results = await self.cleanupUpTo(priority: .medium)
						if !results.isEmpty {
							self.triggerCleanupResults(results)
						}

					case .normal:
						break
					}
				}
			}
	}

	public func disableAutoCleanup() {
		isAutoCleanupEnabled = false
		monitoringCancellable?.cancel()
		monitoringCancellable = nil
		memoryMonitor.stopMonitoring()
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
