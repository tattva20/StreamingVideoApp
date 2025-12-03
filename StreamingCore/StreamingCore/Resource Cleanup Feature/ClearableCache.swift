//
//  ClearableCache.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Abstraction for any cache that can be cleared and sized
/// Note: Methods are synchronous to avoid Swift interface generation issues
/// with async closures in public APIs when BUILD_LIBRARY_FOR_DISTRIBUTION is enabled
public protocol ClearableCache: Sendable {
	/// Clear all cached items
	/// - Returns: Number of items cleared
	func clearAll() throws -> Int

	/// Estimate the current size of the cache in bytes
	/// - Returns: Estimated size in bytes (0 if unknown)
	func estimateSize() -> UInt64
}
