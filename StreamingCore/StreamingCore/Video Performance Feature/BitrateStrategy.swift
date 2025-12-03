//
//  BitrateStrategy.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Protocol for adaptive bitrate selection strategies
public protocol BitrateStrategy: Sendable {
	/// Determine initial bitrate based on network quality
	/// - Parameters:
	///   - networkQuality: Current network quality
	///   - availableLevels: Available bitrate levels to choose from
	/// - Returns: Initial bitrate to use
	func initialBitrate(for networkQuality: NetworkQuality, availableLevels: [BitrateLevel]) -> Int

	/// Determine if bitrate should be upgraded
	/// - Parameters:
	///   - currentBitrate: Current playback bitrate
	///   - bufferHealth: Buffer health (0-1, higher is better)
	///   - networkQuality: Current network quality
	///   - availableLevels: Available bitrate levels
	/// - Returns: New bitrate if upgrade recommended, nil otherwise
	func shouldUpgrade(
		currentBitrate: Int,
		bufferHealth: Double,
		networkQuality: NetworkQuality,
		availableLevels: [BitrateLevel]
	) -> Int?

	/// Determine if bitrate should be downgraded
	/// - Parameters:
	///   - currentBitrate: Current playback bitrate
	///   - rebufferingRatio: Ratio of time spent rebuffering (0-1)
	///   - networkQuality: Current network quality
	///   - availableLevels: Available bitrate levels
	/// - Returns: New bitrate if downgrade recommended, nil otherwise
	func shouldDowngrade(
		currentBitrate: Int,
		rebufferingRatio: Double,
		networkQuality: NetworkQuality,
		availableLevels: [BitrateLevel]
	) -> Int?
}
