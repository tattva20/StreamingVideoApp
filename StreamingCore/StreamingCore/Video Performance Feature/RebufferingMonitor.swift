//
//  RebufferingMonitor.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public actor RebufferingMonitor {

	// MARK: - State

	public struct State: Equatable, Sendable {
		public let isBuffering: Bool
		public let bufferingStartTime: Date?
		public let bufferingEvents: [BufferingEvent]
		public let totalBufferingDuration: TimeInterval

		public var currentBufferingDuration: TimeInterval? {
			guard isBuffering, let start = bufferingStartTime else { return nil }
			return Date().timeIntervalSince(start)
		}

		public var bufferingCount: Int {
			bufferingEvents.count
		}
	}

	// MARK: - Buffering Event

	public struct BufferingEvent: Equatable, Sendable {
		public let startTime: Date
		public let endTime: Date

		public var duration: TimeInterval {
			endTime.timeIntervalSince(startTime)
		}
	}

	// MARK: - Private Properties

	private var isBuffering = false
	private var bufferingStartTime: Date?
	private var bufferingEvents: [BufferingEvent] = []
	private var totalBufferingDuration: TimeInterval = 0
	private let currentDate: @Sendable () -> Date

	// MARK: - Initialization

	public init(currentDate: @escaping @Sendable () -> Date = { Date() }) {
		self.currentDate = currentDate
	}

	// MARK: - Public Methods

	public func bufferingStarted() {
		guard !isBuffering else { return }
		isBuffering = true
		bufferingStartTime = currentDate()
	}

	public func bufferingEnded() -> BufferingEvent? {
		guard isBuffering, let startTime = bufferingStartTime else { return nil }

		isBuffering = false
		let endTime = currentDate()
		let event = BufferingEvent(startTime: startTime, endTime: endTime)

		bufferingEvents.append(event)
		totalBufferingDuration += event.duration
		bufferingStartTime = nil

		return event
	}

	public var state: State {
		State(
			isBuffering: isBuffering,
			bufferingStartTime: bufferingStartTime,
			bufferingEvents: bufferingEvents,
			totalBufferingDuration: totalBufferingDuration
		)
	}

	public func reset() {
		isBuffering = false
		bufferingStartTime = nil
		bufferingEvents = []
		totalBufferingDuration = 0
	}

	public func eventsInLastMinute() -> Int {
		let oneMinuteAgo = currentDate().addingTimeInterval(-60)
		return bufferingEvents.filter { $0.startTime > oneMinuteAgo }.count
	}
}
