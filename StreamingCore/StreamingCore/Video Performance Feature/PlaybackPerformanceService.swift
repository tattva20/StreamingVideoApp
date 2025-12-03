//
//  PlaybackPerformanceService.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation
import Combine

public actor PlaybackPerformanceService: PerformanceMonitor {

	// MARK: - Private Properties

	private let thresholds: PerformanceThresholds
	private let currentDate: @Sendable () -> Date
	private let uuidGenerator: @Sendable () -> UUID

	private var sessionID: UUID?
	private var sessionStartTime: Date?

	private let startupTracker = StartupTimeTracker()
	private var rebufferingMonitor: RebufferingMonitor?

	private var currentMemory: (usedMB: Double, pressure: MemoryPressureLevel) = (0, .normal)
	private var currentNetwork: NetworkQuality = .excellent
	private var currentBitrate: Int?
	private var previousBitrate: Int?

	// Combine subjects - nonisolated(unsafe) is safe because PassthroughSubject is thread-safe
	private nonisolated(unsafe) let metricsSubject = PassthroughSubject<PerformanceSnapshot, Never>()
	private nonisolated(unsafe) let alertSubject = PassthroughSubject<PerformanceAlert, Never>()

	// MARK: - PerformanceMonitor Protocol

	public nonisolated var metricsPublisher: AnyPublisher<PerformanceSnapshot, Never> {
		metricsSubject.eraseToAnyPublisher()
	}

	public nonisolated var alertPublisher: AnyPublisher<PerformanceAlert, Never> {
		alertSubject.eraseToAnyPublisher()
	}

	public nonisolated var metricsStream: AsyncStream<PerformanceSnapshot> {
		metricsSubject.toAsyncStream()
	}

	// MARK: - Initialization

	public init(
		thresholds: PerformanceThresholds = .default,
		currentDate: @escaping @Sendable () -> Date = { Date() },
		uuidGenerator: @escaping @Sendable () -> UUID = { UUID() }
	) {
		self.thresholds = thresholds
		self.currentDate = currentDate
		self.uuidGenerator = uuidGenerator
	}

	// MARK: - Public Methods

	public func startMonitoring(for sessionID: UUID) {
		self.sessionID = sessionID
		self.sessionStartTime = currentDate()
		startupTracker.reset()
		rebufferingMonitor = RebufferingMonitor(currentDate: currentDate)
		currentMemory = (0, .normal)
		currentNetwork = .excellent
		currentBitrate = nil
		previousBitrate = nil
	}

	public func stopMonitoring() {
		sessionID = nil
		sessionStartTime = nil
		rebufferingMonitor = nil
	}

	public func recordEvent(_ event: PerformanceEvent) {
		guard let sessionID else { return }

		switch event {
		case .loadStarted:
			startupTracker.recordLoadStart(at: currentDate())

		case .firstFrameRendered:
			startupTracker.recordFirstFrame(at: currentDate())
			checkStartupTime(sessionID: sessionID)

		case .bufferingStarted:
			Task {
				await rebufferingMonitor?.bufferingStarted()
			}

		case .bufferingEnded:
			Task {
				if let event = await rebufferingMonitor?.bufferingEnded() {
					await checkRebuffering(sessionID: sessionID, event: event)
				}
			}

		case .playbackStalled:
			emitAlert(PerformanceAlert(
				id: uuidGenerator(),
				sessionID: sessionID,
				type: .playbackStalled,
				severity: .critical,
				timestamp: currentDate(),
				message: "Playback has stalled",
				suggestion: "Check network connection"
			))

		case .playbackResumed:
			break

		case .qualityChanged(let bitrate):
			previousBitrate = currentBitrate
			currentBitrate = bitrate
			checkQualityChange(sessionID: sessionID)

		case .memoryWarning(let level):
			currentMemory.pressure = level
			if level >= .warning {
				emitAlert(PerformanceAlert(
					id: uuidGenerator(),
					sessionID: sessionID,
					type: .memoryPressure(level: level),
					severity: level == .critical ? .critical : .warning,
					timestamp: currentDate(),
					message: "Memory pressure detected",
					suggestion: level == .critical ? "Reduce quality or close other apps" : nil
				))
			}

		case .networkChanged(let quality):
			let previousNetwork = currentNetwork
			currentNetwork = quality
			if quality < previousNetwork {
				emitAlert(PerformanceAlert(
					id: uuidGenerator(),
					sessionID: sessionID,
					type: .networkDegradation(from: previousNetwork, to: quality),
					severity: quality == .poor || quality == .offline ? .critical : .warning,
					timestamp: currentDate(),
					message: "Network quality degraded",
					suggestion: quality == .offline ? "Check network connection" : nil
				))
			}

		case .bytesTransferred:
			break
		}

		emitSnapshot()
	}

	public func updateMemory(usedMB: Double, pressure: MemoryPressureLevel) {
		currentMemory = (usedMB, pressure)
	}

	public func updateNetwork(_ quality: NetworkQuality) {
		currentNetwork = quality
	}

	// MARK: - Private Methods

	private func checkStartupTime(sessionID: UUID) {
		guard let ttff = startupTracker.measurement?.timeToFirstFrame else { return }

		if ttff >= thresholds.criticalStartupTime {
			emitAlert(PerformanceAlert(
				id: uuidGenerator(),
				sessionID: sessionID,
				type: .slowStartup(duration: ttff),
				severity: .critical,
				timestamp: currentDate(),
				message: String(format: "Slow startup: %.1fs", ttff),
				suggestion: "Network may be slow"
			))
		} else if ttff >= thresholds.warningStartupTime {
			emitAlert(PerformanceAlert(
				id: uuidGenerator(),
				sessionID: sessionID,
				type: .slowStartup(duration: ttff),
				severity: .warning,
				timestamp: currentDate(),
				message: String(format: "Startup time: %.1fs", ttff),
				suggestion: nil
			))
		}
	}

	private func checkRebuffering(sessionID: UUID, event: RebufferingMonitor.BufferingEvent) async {
		guard let rebufferingMonitor else { return }

		let state = await rebufferingMonitor.state
		let eventsPerMinute = await rebufferingMonitor.eventsInLastMinute()

		// Check prolonged buffering
		if event.duration >= thresholds.maxBufferingDuration {
			emitAlert(PerformanceAlert(
				id: uuidGenerator(),
				sessionID: sessionID,
				type: .prolongedBuffering(duration: event.duration),
				severity: .critical,
				timestamp: currentDate(),
				message: String(format: "Buffered for %.1fs", event.duration),
				suggestion: "Consider reducing quality"
			))
		}

		// Check frequent rebuffering
		if eventsPerMinute >= thresholds.maxBufferingEventsPerMinute {
			guard let sessionStart = sessionStartTime else { return }
			let watchDuration = currentDate().timeIntervalSince(sessionStart)
			let ratio = watchDuration > 0 ? state.totalBufferingDuration / watchDuration : 0

			let severity: PerformanceAlert.Severity = ratio >= thresholds.criticalRebufferingRatio ? .critical : .warning

			emitAlert(PerformanceAlert(
				id: uuidGenerator(),
				sessionID: sessionID,
				type: .frequentRebuffering(count: eventsPerMinute, ratio: ratio),
				severity: severity,
				timestamp: currentDate(),
				message: "\(eventsPerMinute) buffering events in last minute",
				suggestion: "Network unstable"
			))
		}
	}

	private func checkQualityChange(sessionID: UUID) {
		guard let current = currentBitrate, let previous = previousBitrate else { return }

		if current < previous {
			let dropPercent = Double(previous - current) / Double(previous) * 100
			if dropPercent >= 50 {
				emitAlert(PerformanceAlert(
					id: uuidGenerator(),
					sessionID: sessionID,
					type: .qualityDowngrade(fromBitrate: previous, toBitrate: current),
					severity: dropPercent >= 75 ? .critical : .warning,
					timestamp: currentDate(),
					message: String(format: "Quality reduced by %.0f%%", dropPercent),
					suggestion: nil
				))
			}
		}
	}

	private func emitSnapshot() {
		guard let sessionID, let sessionStart = sessionStartTime else { return }

		Task {
			let bufferState = await rebufferingMonitor?.state ?? RebufferingMonitor.State(
				isBuffering: false,
				bufferingStartTime: nil,
				bufferingEvents: [],
				totalBufferingDuration: 0
			)

			let snapshot = PerformanceSnapshot(
				timestamp: currentDate(),
				sessionID: sessionID,
				timeToFirstFrame: startupTracker.measurement?.timeToFirstFrame,
				isBuffering: bufferState.isBuffering,
				bufferingCount: bufferState.bufferingCount,
				totalBufferingDuration: bufferState.totalBufferingDuration,
				currentBufferingDuration: bufferState.currentBufferingDuration,
				currentBitrate: currentBitrate,
				networkQuality: currentNetwork,
				memoryUsageMB: currentMemory.usedMB,
				memoryPressure: currentMemory.pressure,
				sessionStartTime: sessionStart
			)

			metricsSubject.send(snapshot)
		}
	}

	private func emitAlert(_ alert: PerformanceAlert) {
		alertSubject.send(alert)
	}
}
