//
//  PerformanceMonitor.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import Combine

/// Protocol for performance monitoring with Combine publishers
/// Following Essential Feed's publisher-based patterns
public protocol PerformanceMonitor: AnyObject, Sendable {
	/// Publisher that emits real-time performance snapshots
	var metricsPublisher: AnyPublisher<PerformanceSnapshot, Never> { get }

	/// Publisher that emits performance alerts when thresholds are exceeded
	var alertPublisher: AnyPublisher<PerformanceAlert, Never> { get }

	/// Async sequence for Swift 6.2 Observations pattern
	var metricsStream: AsyncStream<PerformanceSnapshot> { get }

	func startMonitoring(for sessionID: UUID) async
	func stopMonitoring() async
	func recordEvent(_ event: PerformanceEvent) async
}

/// Extension providing default Combine helpers (Essential Feed pattern)
public extension PerformanceMonitor {
	/// Convenience publisher that dispatches on main thread
	var mainThreadMetricsPublisher: AnyPublisher<PerformanceSnapshot, Never> {
		metricsPublisher.dispatchOnMainThread()
	}

	/// Publisher filtered to only critical alerts
	var criticalAlertPublisher: AnyPublisher<PerformanceAlert, Never> {
		alertPublisher
			.filter { $0.severity == .critical }
			.eraseToAnyPublisher()
	}
}
