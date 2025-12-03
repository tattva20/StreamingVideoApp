//
//  BandwidthEstimate.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents calculated bandwidth estimates based on multiple samples
public struct BandwidthEstimate: Equatable, Sendable {
	/// Average bandwidth in bits per second
	public let averageBandwidthBps: Double

	/// Peak (maximum) bandwidth observed in bits per second
	public let peakBandwidthBps: Double

	/// Minimum bandwidth observed in bits per second
	public let minimumBandwidthBps: Double

	/// Bandwidth stability score (0-1, where 1 is most stable)
	public let stability: Double

	/// Confidence score in the estimate (0-1, where 1 is most confident)
	public let confidence: Double

	/// Number of samples used to calculate this estimate
	public let sampleCount: Int

	public init(
		averageBandwidthBps: Double,
		peakBandwidthBps: Double,
		minimumBandwidthBps: Double,
		stability: Double,
		confidence: Double,
		sampleCount: Int
	) {
		self.averageBandwidthBps = averageBandwidthBps
		self.peakBandwidthBps = peakBandwidthBps
		self.minimumBandwidthBps = minimumBandwidthBps
		self.stability = stability
		self.confidence = confidence
		self.sampleCount = sampleCount
	}

	/// Conservative recommended maximum bitrate (70% of minimum observed bandwidth)
	public var recommendedMaxBitrate: Int {
		Int(minimumBandwidthBps * 0.7)
	}

	/// Average bandwidth in megabits per second
	public var averageMegabitsPerSecond: Double {
		averageBandwidthBps / 1_000_000
	}

	/// Whether this estimate is reliable enough to base decisions on
	/// Requires high confidence, good stability, and sufficient samples
	public var isReliable: Bool {
		confidence >= 0.5 && stability >= 0.5 && sampleCount >= 3
	}

	/// Empty estimate representing no bandwidth data
	public static let empty = BandwidthEstimate(
		averageBandwidthBps: 0,
		peakBandwidthBps: 0,
		minimumBandwidthBps: 0,
		stability: 0,
		confidence: 0,
		sampleCount: 0
	)
}
