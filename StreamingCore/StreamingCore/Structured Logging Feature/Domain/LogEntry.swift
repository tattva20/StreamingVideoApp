//
//  LogEntry.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A structured log entry containing the message, level, context, and metadata.
public struct LogEntry: Equatable, Sendable {
	/// Unique identifier for this log entry
	public let id: UUID

	/// When the log entry was created
	public let timestamp: Date

	/// Severity level of the log
	public let level: LogLevel

	/// The log message
	public let message: String

	/// Contextual information about where the log was created
	public let context: LogContext

	public init(
		id: UUID = UUID(),
		timestamp: Date = Date(),
		level: LogLevel,
		message: String,
		context: LogContext
	) {
		self.id = id
		self.timestamp = timestamp
		self.level = level
		self.message = message
		self.context = context
	}
}

extension LogEntry {
	/// A formatted version of the log message including level and context
	public var formattedMessage: String {
		var result = "[\(level)] \(message)"

		if let subsystem = context.subsystem {
			result = "[\(subsystem)] " + result
		}

		if let correlationID = context.correlationID {
			result += " [cid:\(correlationID.uuidString.prefix(8))]"
		}

		return result
	}
}
