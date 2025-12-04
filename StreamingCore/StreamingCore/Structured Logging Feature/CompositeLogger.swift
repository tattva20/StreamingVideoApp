//
//  CompositeLogger.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A logger that forwards log entries to multiple underlying loggers.
/// Useful for combining console, file, and remote logging.
/// Following Essential Feed patterns - sync protocol with internal forwarding.
public final class CompositeLogger: Logger, @unchecked Sendable {
	private let loggers: [any Logger]
	public let minimumLevel: LogLevel

	public init(loggers: [any Logger], minimumLevel: LogLevel = .debug) {
		self.loggers = loggers
		self.minimumLevel = minimumLevel
	}

	public func log(_ entry: LogEntry) {
		guard entry.level >= minimumLevel else { return }

		for logger in loggers {
			if entry.level >= logger.minimumLevel {
				logger.log(entry)
			}
		}
	}
}
