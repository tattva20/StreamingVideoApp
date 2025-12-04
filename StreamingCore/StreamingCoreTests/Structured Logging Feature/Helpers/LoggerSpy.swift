//
//  LoggerSpy.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import StreamingCore

/// A class-based spy for testing logger implementations.
/// Following Essential Feed patterns - simple class with sync protocol.
/// Uses @unchecked Sendable for test-only code that doesn't need thread-safety.
final class LoggerSpy: Logger, @unchecked Sendable {
	private(set) var loggedEntries: [LogEntry] = []
	let minimumLevel: LogLevel

	var loggedMessages: [String] {
		loggedEntries.map(\.message)
	}

	var loggedLevels: [LogLevel] {
		loggedEntries.map(\.level)
	}

	init(minimumLevel: LogLevel = .debug) {
		self.minimumLevel = minimumLevel
	}

	func log(_ entry: LogEntry) {
		guard entry.level >= minimumLevel else { return }
		loggedEntries.append(entry)
	}

	func reset() {
		loggedEntries.removeAll()
	}
}
