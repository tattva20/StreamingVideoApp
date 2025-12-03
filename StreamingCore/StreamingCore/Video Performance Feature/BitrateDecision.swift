//
//  BitrateDecision.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents a bitrate change decision made by a BitrateStrategy
public enum BitrateDecision: Equatable, Sendable {
	case maintain(Int)
	case upgrade(to: Int)
	case downgrade(to: Int, reason: DowngradeReason)

	public enum DowngradeReason: Equatable, Sendable {
		case rebuffering
		case networkDegraded
		case memoryPressure
	}

	/// The target bitrate for this decision
	public var targetBitrate: Int {
		switch self {
		case .maintain(let bitrate):
			return bitrate
		case .upgrade(let bitrate):
			return bitrate
		case .downgrade(let bitrate, _):
			return bitrate
		}
	}
}
