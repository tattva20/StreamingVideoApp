//
//  LoggingConfiguration.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import StreamingCore
import StreamingCoreiOS

/// Configures logging based on build environment.
/// Debug builds use console + OSLog, Release builds use OSLog only with info+ level.
public enum LoggingConfiguration {

	/// Creates a logger appropriate for the current build environment
	public static func makeLogger() -> any Logger {
		#if DEBUG
		return makeDebugLogger()
		#else
		return makeReleaseLogger()
		#endif
	}

	/// Creates a logger for debug builds - verbose console output
	private static func makeDebugLogger() -> any Logger {
		let consoleLogger = ConsoleLogger(minimumLevel: .debug)
		let osLogLogger = OSLogLogger(
			subsystem: "com.streamingvideoapp.StreamingVideoApp",
			category: "VideoPlayer",
			minimumLevel: .debug
		)

		return CompositeLogger(
			loggers: [consoleLogger, osLogLogger],
			minimumLevel: .debug
		)
	}

	/// Creates a logger for release builds - only important events
	private static func makeReleaseLogger() -> any Logger {
		OSLogLogger(
			subsystem: "com.streamingvideoapp.StreamingVideoApp",
			category: "VideoPlayer",
			minimumLevel: .info
		)
	}

	/// Creates a null logger for testing or when logging is disabled
	public static func makeNullLogger() -> any Logger {
		NullLogger()
	}
}
