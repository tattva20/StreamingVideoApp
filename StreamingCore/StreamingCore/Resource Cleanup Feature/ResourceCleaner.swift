//
//  ResourceCleaner.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public protocol ResourceCleaner: Sendable {
	var resourceName: String { get }
	var priority: CleanupPriority { get }

	/// Estimate how much can be freed without actually cleaning
	func estimateCleanup() async -> UInt64

	/// Perform the cleanup and return result
	func cleanup() async -> CleanupResult
}
