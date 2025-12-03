//
//  PerformanceEvent.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

// MARK: - Memory Pressure Level

public enum MemoryPressureLevel: Int, Sendable, Comparable, Codable, Equatable {
	case normal = 0
	case warning = 1
	case critical = 2

	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}

// MARK: - Network Quality

public enum NetworkQuality: Int, Sendable, Comparable, Codable, Equatable {
	case offline = 0
	case poor = 1
	case fair = 2
	case good = 3
	case excellent = 4

	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}

// MARK: - Performance Event

public enum PerformanceEvent: Equatable, Sendable {
	case loadStarted
	case firstFrameRendered
	case bufferingStarted
	case bufferingEnded(duration: TimeInterval)
	case playbackStalled
	case playbackResumed
	case qualityChanged(bitrate: Int)
	case memoryWarning(level: MemoryPressureLevel)
	case networkChanged(quality: NetworkQuality)
	case bytesTransferred(bytes: Int64, duration: TimeInterval)
}
