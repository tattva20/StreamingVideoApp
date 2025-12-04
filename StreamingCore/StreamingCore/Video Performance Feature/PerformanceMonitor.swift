//
//  PerformanceMonitor.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import Combine

/// A protocol for performance monitoring with Combine publishers.
///
/// `PerformanceMonitor` tracks playback performance metrics and emits alerts
/// when quality thresholds are exceeded, enabling adaptive quality management.
///
/// ## Thread Safety
/// Requires `@MainActor` isolation for safe state management.
@MainActor
public protocol PerformanceMonitor: AnyObject {
	/// Publisher that emits real-time performance snapshots
	var metricsPublisher: AnyPublisher<PerformanceSnapshot, Never> { get }

	/// Publisher that emits performance alerts when thresholds are exceeded
	var alertPublisher: AnyPublisher<PerformanceAlert, Never> { get }

	func startMonitoring(for sessionID: UUID)
	func stopMonitoring()
	func recordEvent(_ event: PerformanceEvent)
}

/// Extension providing default Combine helpers for convenience.
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
