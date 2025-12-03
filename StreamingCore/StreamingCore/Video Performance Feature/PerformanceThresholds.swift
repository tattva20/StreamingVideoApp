//
//  PerformanceThresholds.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct PerformanceThresholds: Equatable, Sendable {
	// Startup
	public let acceptableStartupTime: TimeInterval
	public let warningStartupTime: TimeInterval
	public let criticalStartupTime: TimeInterval

	// Rebuffering
	public let acceptableRebufferingRatio: Double
	public let warningRebufferingRatio: Double
	public let criticalRebufferingRatio: Double
	public let maxBufferingDuration: TimeInterval
	public let maxBufferingEventsPerMinute: Int

	// Memory
	public let warningMemoryMB: Double
	public let criticalMemoryMB: Double

	public init(
		acceptableStartupTime: TimeInterval,
		warningStartupTime: TimeInterval,
		criticalStartupTime: TimeInterval,
		acceptableRebufferingRatio: Double,
		warningRebufferingRatio: Double,
		criticalRebufferingRatio: Double,
		maxBufferingDuration: TimeInterval,
		maxBufferingEventsPerMinute: Int,
		warningMemoryMB: Double,
		criticalMemoryMB: Double
	) {
		self.acceptableStartupTime = acceptableStartupTime
		self.warningStartupTime = warningStartupTime
		self.criticalStartupTime = criticalStartupTime
		self.acceptableRebufferingRatio = acceptableRebufferingRatio
		self.warningRebufferingRatio = warningRebufferingRatio
		self.criticalRebufferingRatio = criticalRebufferingRatio
		self.maxBufferingDuration = maxBufferingDuration
		self.maxBufferingEventsPerMinute = maxBufferingEventsPerMinute
		self.warningMemoryMB = warningMemoryMB
		self.criticalMemoryMB = criticalMemoryMB
	}

	// MARK: - Presets

	public static let `default` = PerformanceThresholds(
		acceptableStartupTime: 2.0,
		warningStartupTime: 4.0,
		criticalStartupTime: 8.0,
		acceptableRebufferingRatio: 0.01,
		warningRebufferingRatio: 0.03,
		criticalRebufferingRatio: 0.05,
		maxBufferingDuration: 10.0,
		maxBufferingEventsPerMinute: 3,
		warningMemoryMB: 150.0,
		criticalMemoryMB: 250.0
	)

	public static let strictStreaming = PerformanceThresholds(
		acceptableStartupTime: 1.5,
		warningStartupTime: 3.0,
		criticalStartupTime: 5.0,
		acceptableRebufferingRatio: 0.005,
		warningRebufferingRatio: 0.02,
		criticalRebufferingRatio: 0.03,
		maxBufferingDuration: 5.0,
		maxBufferingEventsPerMinute: 2,
		warningMemoryMB: 100.0,
		criticalMemoryMB: 200.0
	)
}
