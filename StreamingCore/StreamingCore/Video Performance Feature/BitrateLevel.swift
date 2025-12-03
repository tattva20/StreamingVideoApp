//
//  BitrateLevel.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents a video quality level with its bitrate
public struct BitrateLevel: Equatable, Sendable, Comparable {
	public let bitrate: Int
	public let label: String

	public init(bitrate: Int, label: String) {
		self.bitrate = bitrate
		self.label = label
	}

	public static func < (lhs: BitrateLevel, rhs: BitrateLevel) -> Bool {
		lhs.bitrate < rhs.bitrate
	}

	/// Standard bitrate levels for common video qualities
	public static let standardLevels: [BitrateLevel] = [
		BitrateLevel(bitrate: 500_000, label: "360p"),
		BitrateLevel(bitrate: 1_000_000, label: "480p"),
		BitrateLevel(bitrate: 2_500_000, label: "720p"),
		BitrateLevel(bitrate: 5_000_000, label: "1080p"),
		BitrateLevel(bitrate: 15_000_000, label: "4K")
	]
}
