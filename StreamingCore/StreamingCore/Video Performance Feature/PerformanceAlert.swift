//
//  PerformanceAlert.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct PerformanceAlert: Equatable, Sendable, Identifiable {
	public let id: UUID
	public let sessionID: UUID
	public let type: AlertType
	public let severity: Severity
	public let timestamp: Date
	public let message: String
	public let suggestion: String?

	public init(
		id: UUID,
		sessionID: UUID,
		type: AlertType,
		severity: Severity,
		timestamp: Date,
		message: String,
		suggestion: String?
	) {
		self.id = id
		self.sessionID = sessionID
		self.type = type
		self.severity = severity
		self.timestamp = timestamp
		self.message = message
		self.suggestion = suggestion
	}

	// MARK: - Alert Type

	public enum AlertType: Equatable, Sendable {
		case slowStartup(duration: TimeInterval)
		case frequentRebuffering(count: Int, ratio: Double)
		case prolongedBuffering(duration: TimeInterval)
		case memoryPressure(level: MemoryPressureLevel)
		case networkDegradation(from: NetworkQuality, to: NetworkQuality)
		case playbackStalled
		case qualityDowngrade(fromBitrate: Int, toBitrate: Int)
	}

	// MARK: - Severity

	public enum Severity: Int, Sendable, Comparable {
		case info = 0
		case warning = 1
		case critical = 2

		public static func < (lhs: Self, rhs: Self) -> Bool {
			lhs.rawValue < rhs.rawValue
		}
	}
}
