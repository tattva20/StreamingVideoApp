//
//  StartupTimeTracker.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public final class StartupTimeTracker: Sendable {

	// MARK: - Measurement

	public struct Measurement: Equatable, Sendable {
		public let loadStartTime: Date
		public let firstFrameTime: Date?

		public var timeToFirstFrame: TimeInterval? {
			guard let firstFrameTime else { return nil }
			return firstFrameTime.timeIntervalSince(loadStartTime)
		}

		public var isComplete: Bool {
			firstFrameTime != nil
		}
	}

	// MARK: - Private Properties

	private let lock = NSLock()
	// Safe because access is synchronized via lock
	private nonisolated(unsafe) var _measurement: Measurement?

	// MARK: - Initialization

	public init() {}

	// MARK: - Public Properties

	public var measurement: Measurement? {
		lock.withLock { _measurement }
	}

	// MARK: - Public Methods

	public func recordLoadStart(at time: Date = Date()) {
		lock.withLock {
			guard _measurement == nil else { return }
			_measurement = Measurement(loadStartTime: time, firstFrameTime: nil)
		}
	}

	public func recordFirstFrame(at time: Date = Date()) {
		lock.withLock {
			guard let current = _measurement, current.firstFrameTime == nil else { return }
			_measurement = Measurement(loadStartTime: current.loadStartTime, firstFrameTime: time)
		}
	}

	public func reset() {
		lock.withLock {
			_measurement = nil
		}
	}
}
