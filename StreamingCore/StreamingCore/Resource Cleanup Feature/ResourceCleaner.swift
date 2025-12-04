//
//  ResourceCleaner.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A protocol for components that can release resources under memory pressure.
///
/// `ResourceCleaner` defines a contract for cleanable resources, enabling
/// coordinated cleanup based on priority. Higher priority cleaners are
/// invoked first during memory pressure events.
///
/// ## Thread Safety
/// Requires `Sendable` conformance for safe cross-actor use.
///
/// ## Conformance Requirements
/// - Cleanup operations should be idempotent
/// - Estimation should not modify state
public protocol ResourceCleaner: Sendable {
	/// A human-readable name for this resource (for logging/debugging).
	var resourceName: String { get }

	/// The cleanup priority (higher values cleaned first).
	var priority: CleanupPriority { get }

	/// Estimates bytes that can be freed without performing cleanup.
	/// - Returns: Estimated bytes that would be freed
	func estimateCleanup() async -> UInt64

	/// Performs the cleanup operation.
	/// - Returns: Result indicating success/failure and bytes freed
	func cleanup() async -> CleanupResult
}
