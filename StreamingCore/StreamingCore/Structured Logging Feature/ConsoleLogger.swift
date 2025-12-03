//
//  ConsoleLogger.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// A logger that outputs formatted log entries to the console.
/// Uses Swift actors for thread-safety.
public actor ConsoleLogger: Logger {
	public nonisolated let minimumLevel: LogLevel
	private let dateFormatter: ISO8601DateFormatter

	public init(minimumLevel: LogLevel = .debug) {
		self.minimumLevel = minimumLevel
		self.dateFormatter = ISO8601DateFormatter()
		self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
	}

	public func log(_ entry: LogEntry) async {
		guard entry.level >= minimumLevel else { return }

		let timestamp = dateFormatter.string(from: entry.timestamp)
		var output = "\(timestamp) \(entry.formattedMessage)"

		if !entry.context.metadata.isEmpty {
			let meta = entry.context.metadata
				.sorted { $0.key < $1.key }
				.map { "\($0.key)=\($0.value)" }
				.joined(separator: ", ")
			output += " {\(meta)}"
		}

		output += " (\(entry.context.file):\(entry.context.line))"

		print(output)
	}
}
