//
//  MemoryMonitor.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

/// A protocol for querying current memory state on demand.
///
/// `MemoryStateProvider` allows synchronous access to memory information
/// without requiring continuous monitoring.
///
/// ## Thread Safety
/// Requires `@MainActor` isolation for safe state access.
@MainActor
public protocol MemoryStateProvider: AnyObject {
	/// Returns the current memory state snapshot.
	/// - Returns: The current memory usage and available memory
	func currentMemoryState() -> MemoryState
}

/// A protocol for continuous memory monitoring with reactive updates.
///
/// `MemoryMonitor` tracks device memory usage and publishes state changes,
/// enabling proactive memory management and resource cleanup.
///
/// ## Thread Safety
/// Requires `@MainActor` isolation for safe state publishing.
///
/// ## Conformance Requirements
/// - Must inherit from `MemoryStateProvider`
/// - Monitoring should be explicitly started/stopped for resource efficiency
@MainActor
public protocol MemoryMonitor: MemoryStateProvider {
	/// A publisher emitting memory state updates during monitoring.
	var statePublisher: AnyPublisher<MemoryState, Never> { get }

	/// Starts continuous memory monitoring.
	func startMonitoring()

	/// Stops memory monitoring and releases resources.
	func stopMonitoring()
}
