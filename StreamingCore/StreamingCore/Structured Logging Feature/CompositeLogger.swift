//
//  CompositeLogger.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A logger that forwards log entries to multiple underlying loggers.
/// Useful for combining console, file, and remote logging.
public final class CompositeLogger: Logger, @unchecked Sendable {
	private let loggers: [any Logger]
	public let minimumLevel: LogLevel

	public init(loggers: [any Logger], minimumLevel: LogLevel = .debug) {
		self.loggers = loggers
		self.minimumLevel = minimumLevel
	}

	public func log(_ entry: LogEntry) async {
		guard entry.level >= minimumLevel else { return }

		await withTaskGroup(of: Void.self) { group in
			for logger in loggers {
				if entry.level >= logger.minimumLevel {
					group.addTask {
						await logger.log(entry)
					}
				}
			}
		}
	}
}
