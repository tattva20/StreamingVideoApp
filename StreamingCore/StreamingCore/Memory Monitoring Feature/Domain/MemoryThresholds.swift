//
//  MemoryThresholds.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct MemoryThresholds: Equatable, Sendable {
	public let warningAvailableMB: Double
	public let criticalAvailableMB: Double
	public let pollingInterval: TimeInterval

	public static let `default` = MemoryThresholds(
		warningAvailableMB: 100.0,
		criticalAvailableMB: 50.0,
		pollingInterval: 2.0
	)

	public init(warningAvailableMB: Double, criticalAvailableMB: Double, pollingInterval: TimeInterval) {
		self.warningAvailableMB = warningAvailableMB
		self.criticalAvailableMB = criticalAvailableMB
		self.pollingInterval = pollingInterval
	}

	public func pressureLevel(for availableMB: Double) -> MemoryPressureLevel {
		if availableMB < criticalAvailableMB { return .critical }
		if availableMB < warningAvailableMB { return .warning }
		return .normal
	}
}
