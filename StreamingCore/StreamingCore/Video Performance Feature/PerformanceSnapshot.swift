//
//  PerformanceSnapshot.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct PerformanceSnapshot: Equatable, Sendable {
	public let timestamp: Date
	public let sessionID: UUID

	// Startup
	public let timeToFirstFrame: TimeInterval?
	public let isBuffering: Bool

	// Rebuffering
	public let bufferingCount: Int
	public let totalBufferingDuration: TimeInterval
	public let currentBufferingDuration: TimeInterval?

	// Quality
	public let currentBitrate: Int?
	public let networkQuality: NetworkQuality

	// Memory
	public let memoryUsageMB: Double
	public let memoryPressure: MemoryPressureLevel

	// Session
	private let sessionStartTime: Date

	public init(
		timestamp: Date,
		sessionID: UUID,
		timeToFirstFrame: TimeInterval?,
		isBuffering: Bool,
		bufferingCount: Int,
		totalBufferingDuration: TimeInterval,
		currentBufferingDuration: TimeInterval?,
		currentBitrate: Int?,
		networkQuality: NetworkQuality,
		memoryUsageMB: Double,
		memoryPressure: MemoryPressureLevel,
		sessionStartTime: Date
	) {
		self.timestamp = timestamp
		self.sessionID = sessionID
		self.timeToFirstFrame = timeToFirstFrame
		self.isBuffering = isBuffering
		self.bufferingCount = bufferingCount
		self.totalBufferingDuration = totalBufferingDuration
		self.currentBufferingDuration = currentBufferingDuration
		self.currentBitrate = currentBitrate
		self.networkQuality = networkQuality
		self.memoryUsageMB = memoryUsageMB
		self.memoryPressure = memoryPressure
		self.sessionStartTime = sessionStartTime
	}

	// MARK: - Computed Properties

	public var rebufferingRatio: Double {
		let sessionDuration = timestamp.timeIntervalSince(sessionStartTime)
		guard sessionDuration > 0 else { return 0 }
		return totalBufferingDuration / sessionDuration
	}

	public var isHealthy: Bool {
		rebufferingRatio < 0.02 &&
		memoryPressure == .normal &&
		(timeToFirstFrame ?? 0) < 3.0
	}
}
