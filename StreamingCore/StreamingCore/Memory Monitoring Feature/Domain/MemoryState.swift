//
//  MemoryState.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct MemoryState: Equatable, Sendable {
	public let availableBytes: UInt64
	public let totalBytes: UInt64
	public let usedBytes: UInt64
	public let timestamp: Date

	public var availableMB: Double {
		Double(availableBytes) / 1_048_576.0
	}

	public var usedMB: Double {
		Double(usedBytes) / 1_048_576.0
	}

	public var usagePercentage: Double {
		guard totalBytes > 0 else { return 0 }
		return Double(usedBytes) / Double(totalBytes) * 100
	}

	public init(availableBytes: UInt64, totalBytes: UInt64, usedBytes: UInt64, timestamp: Date) {
		self.availableBytes = availableBytes
		self.totalBytes = totalBytes
		self.usedBytes = usedBytes
		self.timestamp = timestamp
	}

	public func pressureLevel(thresholds: MemoryThresholds) -> MemoryPressureLevel {
		thresholds.pressureLevel(for: availableMB)
	}
}
