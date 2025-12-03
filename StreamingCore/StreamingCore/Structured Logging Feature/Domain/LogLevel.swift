//
//  LogLevel.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents the severity level of a log entry.
/// Levels are ordered from least severe (debug) to most severe (critical).
public enum LogLevel: Int, Comparable, Sendable, Codable {
	/// Development-only details, verbose information for debugging
	case debug = 0

	/// Normal operational events, general information
	case info = 1

	/// Potential issues that are not errors but may require attention
	case warning = 2

	/// Errors that can be recovered from
	case error = 3

	/// Critical system failures requiring immediate attention
	case critical = 4

	public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}
