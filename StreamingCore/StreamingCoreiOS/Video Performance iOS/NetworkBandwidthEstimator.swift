//
//  NetworkBandwidthEstimator.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Thread-safe bandwidth estimator that collects samples and calculates bandwidth estimates
public actor NetworkBandwidthEstimator {

	private let maxSamples: Int
	private var samples: [BandwidthSample] = []

	/// Number of samples currently stored
	public var sampleCount: Int {
		samples.count
	}

	/// Current bandwidth estimate based on stored samples
	public var currentEstimate: BandwidthEstimate {
		calculateEstimate()
	}

	public init(maxSamples: Int = 30) {
		self.maxSamples = maxSamples
	}

	/// Record a new bandwidth sample
	/// - Parameter sample: The bandwidth sample to record
	public func recordSample(_ sample: BandwidthSample) {
		// Ignore invalid samples
		guard sample.duration > 0, sample.bytesTransferred > 0 else { return }

		samples.append(sample)

		// Trim old samples if over limit
		if samples.count > maxSamples {
			samples.removeFirst(samples.count - maxSamples)
		}
	}

	/// Clear all stored samples
	public func clear() {
		samples.removeAll()
	}

	// MARK: - Private

	private func calculateEstimate() -> BandwidthEstimate {
		guard !samples.isEmpty else { return .empty }

		let bandwidths = samples.map { $0.bitsPerSecond }
		let average = bandwidths.reduce(0, +) / Double(bandwidths.count)
		let peak = bandwidths.max() ?? 0
		let minimum = bandwidths.min() ?? 0

		let stability = calculateStability(bandwidths: bandwidths, average: average)
		let confidence = calculateConfidence(sampleCount: samples.count)

		return BandwidthEstimate(
			averageBandwidthBps: average,
			peakBandwidthBps: peak,
			minimumBandwidthBps: minimum,
			stability: stability,
			confidence: confidence,
			sampleCount: samples.count
		)
	}

	/// Calculate stability based on coefficient of variation
	/// Lower variance = higher stability
	private func calculateStability(bandwidths: [Double], average: Double) -> Double {
		guard bandwidths.count > 1, average > 0 else { return 1.0 }

		// Calculate standard deviation
		let squaredDiffs = bandwidths.map { pow($0 - average, 2) }
		let variance = squaredDiffs.reduce(0, +) / Double(bandwidths.count)
		let standardDeviation = sqrt(variance)

		// Coefficient of variation (CV) = standard deviation / mean
		let cv = standardDeviation / average

		// Convert CV to stability score (0-1)
		// CV of 0 = stability of 1 (perfectly stable)
		// CV of 1+ = stability approaching 0 (very unstable)
		let stability = max(0, 1.0 - cv)
		return min(1.0, stability)
	}

	/// Calculate confidence based on sample count
	/// More samples = higher confidence
	private func calculateConfidence(sampleCount: Int) -> Double {
		// Confidence grows with sample count, approaching 1.0 asymptotically
		// 1 sample = ~0.2, 5 samples = ~0.67, 10 samples = ~0.83, 20 samples = ~0.91
		let confidence = 1.0 - exp(-Double(sampleCount) * 0.2)
		return min(1.0, confidence)
	}
}
