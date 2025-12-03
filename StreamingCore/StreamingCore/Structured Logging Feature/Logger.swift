//
//  Logger.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A protocol for logging structured log entries.
/// Implementations should be thread-safe and support async operations.
public protocol Logger: Sendable {
	/// The minimum log level this logger will process.
	/// Entries below this level should be ignored.
	var minimumLevel: LogLevel { get }

	/// Log an entry asynchronously.
	/// - Parameter entry: The log entry to record
	func log(_ entry: LogEntry) async
}

// MARK: - Convenience Methods

extension Logger {
	/// Log a debug message
	public func debug(
		_ message: String,
		context: LogContext = LogContext()
	) async {
		await log(LogEntry(level: .debug, message: message, context: context))
	}

	/// Log an info message
	public func info(
		_ message: String,
		context: LogContext = LogContext()
	) async {
		await log(LogEntry(level: .info, message: message, context: context))
	}

	/// Log a warning message
	public func warning(
		_ message: String,
		context: LogContext = LogContext()
	) async {
		await log(LogEntry(level: .warning, message: message, context: context))
	}

	/// Log an error message
	public func error(
		_ message: String,
		context: LogContext = LogContext()
	) async {
		await log(LogEntry(level: .error, message: message, context: context))
	}

	/// Log a critical message
	public func critical(
		_ message: String,
		context: LogContext = LogContext()
	) async {
		await log(LogEntry(level: .critical, message: message, context: context))
	}
}
