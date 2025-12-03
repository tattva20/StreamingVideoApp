//
//  BandwidthSample.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents a single bandwidth measurement sample
public struct BandwidthSample: Equatable, Sendable {
	/// Number of bytes transferred during the sample period
	public let bytesTransferred: Int64

	/// Duration of the sample period in seconds
	public let duration: TimeInterval

	/// Timestamp when the sample was recorded
	public let timestamp: Date

	public init(bytesTransferred: Int64, duration: TimeInterval, timestamp: Date) {
		self.bytesTransferred = bytesTransferred
		self.duration = duration
		self.timestamp = timestamp
	}

	/// Calculated bandwidth in bits per second
	public var bitsPerSecond: Double {
		guard duration > 0 else { return 0 }
		return Double(bytesTransferred * 8) / duration
	}

	/// Calculated bandwidth in megabits per second
	public var megabitsPerSecond: Double {
		bitsPerSecond / 1_000_000
	}
}
