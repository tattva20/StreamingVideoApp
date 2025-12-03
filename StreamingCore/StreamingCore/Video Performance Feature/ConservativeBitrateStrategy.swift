//
//  ConservativeBitrateStrategy.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A conservative bitrate strategy that prioritizes stable playback over quality
/// - Starts at low quality based on network
/// - Upgrades gradually when buffer health is high
/// - Downgrades immediately on rebuffering or network degradation
public struct ConservativeBitrateStrategy: BitrateStrategy, Sendable {
	private let bufferHealthThreshold: Double
	private let rebufferingThreshold: Double

	public init(
		bufferHealthThreshold: Double = 0.7,
		rebufferingThreshold: Double = 0.05
	) {
		self.bufferHealthThreshold = bufferHealthThreshold
		self.rebufferingThreshold = rebufferingThreshold
	}

	public func initialBitrate(for networkQuality: NetworkQuality, availableLevels: [BitrateLevel]) -> Int {
		guard !availableLevels.isEmpty else { return 0 }

		let sortedLevels = availableLevels.sorted()
		let index: Int

		switch networkQuality {
		case .offline, .poor:
			index = 0
		case .fair:
			index = sortedLevels.count / 3
		case .good:
			index = min(sortedLevels.count * 2 / 3, sortedLevels.count - 1)
		case .excellent:
			index = sortedLevels.count - 1
		}

		return sortedLevels[index].bitrate
	}

	public func shouldUpgrade(
		currentBitrate: Int,
		bufferHealth: Double,
		networkQuality: NetworkQuality,
		availableLevels: [BitrateLevel]
	) -> Int? {
		// Don't upgrade on poor network
		guard networkQuality >= .fair else { return nil }

		// Don't upgrade if buffer health is low
		guard bufferHealth >= bufferHealthThreshold else { return nil }

		let sortedLevels = availableLevels.sorted()

		// Find current level index
		guard let currentIndex = sortedLevels.firstIndex(where: { $0.bitrate >= currentBitrate }) else {
			return nil
		}

		// Check if there's a higher level available
		let nextIndex = currentIndex + 1
		guard nextIndex < sortedLevels.count else { return nil }

		// For excellent network with good buffer, allow upgrade
		if networkQuality >= .good && bufferHealth >= bufferHealthThreshold {
			return sortedLevels[nextIndex].bitrate
		}

		return nil
	}

	public func shouldDowngrade(
		currentBitrate: Int,
		rebufferingRatio: Double,
		networkQuality: NetworkQuality,
		availableLevels: [BitrateLevel]
	) -> Int? {
		let sortedLevels = availableLevels.sorted()

		// Find current level index
		guard let currentIndex = sortedLevels.firstIndex(where: { $0.bitrate >= currentBitrate }),
			  currentIndex > 0 else {
			return nil
		}

		// Downgrade immediately on rebuffering
		if rebufferingRatio >= rebufferingThreshold {
			return sortedLevels[currentIndex - 1].bitrate
		}

		// Downgrade on poor network
		if networkQuality <= .poor {
			return sortedLevels[currentIndex - 1].bitrate
		}

		return nil
	}
}
