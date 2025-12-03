//
//  NullLogger.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A no-op logger that discards all log entries.
/// Useful for production builds where logging is disabled, or for testing.
public struct NullLogger: Logger, Sendable {
	public let minimumLevel: LogLevel = .critical

	public init() {}

	public func log(_ entry: LogEntry) async {
		// Intentionally empty - discards all log entries
	}
}
