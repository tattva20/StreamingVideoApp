//
//  LoggerSpy.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import StreamingCore

/// An actor-based spy for testing logger implementations.
/// Thread-safe by design using Swift actors.
actor LoggerSpy: Logger {
	private var _loggedEntries: [LogEntry] = []
	private let _minimumLevel: LogLevel

	nonisolated var minimumLevel: LogLevel { _minimumLevel }

	var loggedEntries: [LogEntry] {
		_loggedEntries
	}

	var loggedMessages: [String] {
		_loggedEntries.map(\.message)
	}

	var loggedLevels: [LogLevel] {
		_loggedEntries.map(\.level)
	}

	init(minimumLevel: LogLevel = .debug) {
		self._minimumLevel = minimumLevel
	}

	func log(_ entry: LogEntry) async {
		guard entry.level >= minimumLevel else { return }
		_loggedEntries.append(entry)
	}

	func reset() {
		_loggedEntries.removeAll()
	}
}
