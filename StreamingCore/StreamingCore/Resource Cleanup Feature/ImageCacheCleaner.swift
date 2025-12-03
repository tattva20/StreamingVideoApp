//
//  ImageCacheCleaner.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A ResourceCleaner for clearing image caches (e.g., NSCache-based caches)
/// Dependency injection via closures allows decoupling from specific cache implementations
public final class ImageCacheCleaner: ResourceCleaner, @unchecked Sendable {
	public let resourceName = "Image Cache"
	public let priority: CleanupPriority = .medium

	private let clearAction: () throws -> Int
	private let sizeEstimate: UInt64

	/// Creates an ImageCacheCleaner with injected clear action
	/// - Parameters:
	///   - clearAction: Synchronous closure that clears the cache and returns number of items removed
	///   - estimateSize: Estimated cache size in bytes (0 if unknown, as NSCache doesn't expose size)
	public init(
		clearAction: @escaping () throws -> Int,
		estimateSize: UInt64 = 0
	) {
		self.clearAction = clearAction
		self.sizeEstimate = estimateSize
	}

	public func estimateCleanup() async -> UInt64 {
		sizeEstimate
	}

	public func cleanup() async -> CleanupResult {
		do {
			let itemsRemoved = try clearAction()
			return CleanupResult(
				resourceName: resourceName,
				bytesFreed: 0, // NSCache doesn't expose size
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
