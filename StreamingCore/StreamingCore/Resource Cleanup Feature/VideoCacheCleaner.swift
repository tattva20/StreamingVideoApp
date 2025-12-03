//
//  VideoCacheCleaner.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A ResourceCleaner for clearing video cache files
/// High priority - video files consume significant storage
public final class VideoCacheCleaner: ResourceCleaner, @unchecked Sendable {
	public let resourceName = "Video Cache"
	public let priority: CleanupPriority = .high

	private let deleteAction: () throws -> Void
	private let statisticsCallback: (() -> (bytesFreed: UInt64, itemsRemoved: Int))?
	private let sizeEstimate: UInt64

	/// Creates a VideoCacheCleaner with injected delete action
	/// - Parameters:
	///   - deleteAction: Synchronous closure that deletes cached video files
	///   - statisticsCallback: Optional synchronous closure that returns cleanup statistics
	///   - estimateSize: Estimated cache size in bytes (0 if unknown)
	public init(
		deleteAction: @escaping () throws -> Void,
		statisticsCallback: (() -> (bytesFreed: UInt64, itemsRemoved: Int))? = nil,
		estimateSize: UInt64 = 0
	) {
		self.deleteAction = deleteAction
		self.statisticsCallback = statisticsCallback
		self.sizeEstimate = estimateSize
	}

	public func estimateCleanup() async -> UInt64 {
		sizeEstimate
	}

	public func cleanup() async -> CleanupResult {
		do {
			try deleteAction()

			let (bytesFreed, itemsRemoved): (UInt64, Int)
			if let callback = statisticsCallback {
				(bytesFreed, itemsRemoved) = callback()
			} else {
				(bytesFreed, itemsRemoved) = (0, 0)
			}

			return CleanupResult(
				resourceName: resourceName,
				bytesFreed: bytesFreed,
				itemsRemoved: itemsRemoved,
				success: true
			)
		} catch {
			return .failure(
				resourceName: resourceName,
				error: error.localizedDescription
			)
		}
	}
}
