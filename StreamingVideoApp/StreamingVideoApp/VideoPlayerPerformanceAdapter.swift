//
//  VideoPlayerPerformanceAdapter.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import StreamingCore
import StreamingCoreiOS

/// Bridges AVPlayer performance observations to the platform-agnostic PerformanceMonitor
/// Coordinates bandwidth estimation with network quality monitoring
public final class VideoPlayerPerformanceAdapter: @unchecked Sendable {

	private let performanceService: any PerformanceMonitor
	private let bandwidthEstimator: NetworkBandwidthEstimator
	private var cancellables = Set<AnyCancellable>()

	private var _isObserving = false
	private var hasRecordedFirstFrame = false

	public var isObserving: Bool { _isObserving }

	public init(
		performanceService: any PerformanceMonitor,
		bandwidthEstimator: NetworkBandwidthEstimator
	) {
		self.performanceService = performanceService
		self.bandwidthEstimator = bandwidthEstimator
	}

	// MARK: - Monitoring Control

	public func startMonitoring(sessionID: UUID) async {
		await performanceService.startMonitoring(for: sessionID)
		_isObserving = true
		hasRecordedFirstFrame = false
	}

	public func stopMonitoring() async {
		_isObserving = false
		await performanceService.stopMonitoring()
		cancellables.removeAll()
	}

	// MARK: - Event Simulation (for testing)

	public func simulatePlaybackStarted() {
		guard _isObserving else { return }
		Task {
			await performanceService.recordEvent(.loadStarted)
			if !hasRecordedFirstFrame {
				hasRecordedFirstFrame = true
				await performanceService.recordEvent(.firstFrameRendered)
			}
		}
	}

	public func simulateBufferingStarted() {
		guard _isObserving else { return }
		Task {
			await performanceService.recordEvent(.bufferingStarted)
		}
	}

	public func simulateBufferingEnded() {
		guard _isObserving else { return }
		Task {
			await performanceService.recordEvent(.bufferingEnded(duration: 0))
		}
	}

	// MARK: - Quality Updates

	public func updateNetworkQuality(_ quality: NetworkQuality) async {
		await performanceService.recordEvent(.networkChanged(quality: quality))
		if let service = performanceService as? PlaybackPerformanceService {
			await service.updateNetwork(quality)
		}
	}

	public func updateMemory(usedMB: Double, pressure: MemoryPressureLevel) async {
		await performanceService.recordEvent(.memoryWarning(level: pressure))
		if let service = performanceService as? PlaybackPerformanceService {
			await service.updateMemory(usedMB: usedMB, pressure: pressure)
		}
	}

	// MARK: - Bandwidth Tracking

	public func recordBandwidthSample(bytesTransferred: Int64, duration: TimeInterval) async {
		let sample = BandwidthSample(
			bytesTransferred: bytesTransferred,
			duration: duration,
			timestamp: Date()
		)
		await bandwidthEstimator.recordSample(sample)
		await performanceService.recordEvent(.bytesTransferred(bytes: bytesTransferred, duration: duration))
	}

	public var currentBandwidthEstimate: BandwidthEstimate {
		get async {
			await bandwidthEstimator.currentEstimate
		}
	}

	// MARK: - AVPlayer Observer Integration

	public func observePlayer(_ observer: AVPlayerPerformanceObserver) {
		observer.playbackStatePublisher
			.removeDuplicates()
			.sink { [weak self] state in
				self?.handlePlaybackStateChange(state)
			}
			.store(in: &cancellables)

		observer.bufferingStatePublisher
			.removeDuplicates()
			.sink { [weak self] state in
				self?.handleBufferingStateChange(state)
			}
			.store(in: &cancellables)

		// AVPlayerPerformanceObserver emits StreamingCore.PerformanceEvent directly
		observer.performanceEventPublisher
			.sink { [weak self] event in
				self?.handlePerformanceEvent(event)
			}
			.store(in: &cancellables)
	}

	// MARK: - Private Handlers

	private func handlePlaybackStateChange(_ state: ObserverPlaybackState) {
		guard _isObserving else { return }

		Task {
			switch state {
			case .playing:
				if !hasRecordedFirstFrame {
					hasRecordedFirstFrame = true
					await performanceService.recordEvent(.firstFrameRendered)
				}
				await performanceService.recordEvent(.playbackResumed)

			case .buffering:
				await performanceService.recordEvent(.bufferingStarted)

			case .stalled:
				await performanceService.recordEvent(.playbackStalled)

			case .paused, .idle:
				break

			case .failed:
				await performanceService.recordEvent(.playbackStalled)
			}
		}
	}

	private func handleBufferingStateChange(_ state: BufferingState) {
		guard _isObserving else { return }

		Task {
			switch state {
			case .buffering:
				await performanceService.recordEvent(.bufferingStarted)

			case .ready:
				await performanceService.recordEvent(.bufferingEnded(duration: 0))

			case .stalled:
				await performanceService.recordEvent(.playbackStalled)

			case .unknown:
				break

			@unknown default:
				break
			}
		}
	}

	private func handlePerformanceEvent(_ event: StreamingCore.PerformanceEvent) {
		guard _isObserving else { return }

		Task {
			// Handle bandwidth tracking specially for the estimator
			if case .bytesTransferred(let bytes, let duration) = event {
				let sample = BandwidthSample(
					bytesTransferred: bytes,
					duration: duration,
					timestamp: Date()
				)
				await bandwidthEstimator.recordSample(sample)
			}
			// Forward all events to the performance service
			await performanceService.recordEvent(event)
		}
	}
}
