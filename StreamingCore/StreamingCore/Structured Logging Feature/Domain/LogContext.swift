//
//  LogContext.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Contextual metadata for a log entry, including source location and optional categorization.
public struct LogContext: Equatable, Sendable {
	/// The source file name (extracted from full path)
	public let file: String

	/// The function name where the log was created
	public let function: String

	/// The line number in the source file
	public let line: UInt

	/// Optional subsystem identifier (e.g., "VideoPlayer", "Network")
	public let subsystem: String?

	/// Optional category within the subsystem (e.g., "Playback", "Buffering")
	public let category: String?

	/// Optional correlation ID for tracing related operations
	public let correlationID: UUID?

	/// Additional key-value metadata
	public let metadata: [String: String]

	public init(
		file: String = #file,
		function: String = #function,
		line: UInt = #line,
		subsystem: String? = nil,
		category: String? = nil,
		correlationID: UUID? = nil,
		metadata: [String: String] = [:]
	) {
		self.file = (file as NSString).lastPathComponent
		self.function = function
		self.line = line
		self.subsystem = subsystem
		self.category = category
		self.correlationID = correlationID
		self.metadata = metadata
	}
}
