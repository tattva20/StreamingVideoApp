//
//  SystemMemoryProvider.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import os
import StreamingCore

/// Provides actual system memory state using iOS system APIs
public enum SystemMemoryProvider {
	/// Returns the current memory state from the operating system
	/// This is a pure computation that can be safely called from any context
	public static let memoryReader: @Sendable () -> MemoryState = {
		let availableBytes = UInt64(os_proc_available_memory())
		let totalBytes = ProcessInfo.processInfo.physicalMemory
		let usedBytes = totalBytes > availableBytes ? totalBytes - availableBytes : 0

		return MemoryState(
			availableBytes: availableBytes,
			totalBytes: totalBytes,
			usedBytes: usedBytes,
			timestamp: Date()
		)
	}
}

/// Factory for creating a PollingMemoryMonitor with system memory reader
public enum MemoryMonitorFactory {
	/// Creates a PollingMemoryMonitor that reads actual system memory
	/// - Parameter thresholds: Memory thresholds for pressure level detection
	/// - Returns: A configured PollingMemoryMonitor
	@MainActor
	public static func makeSystemMemoryMonitor(
		thresholds: MemoryThresholds = .default
	) -> PollingMemoryMonitor {
		PollingMemoryMonitor(
			memoryReader: SystemMemoryProvider.memoryReader,
			thresholds: thresholds
		)
	}
}
