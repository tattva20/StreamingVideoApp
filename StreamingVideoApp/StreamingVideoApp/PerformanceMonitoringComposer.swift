//
//  PerformanceMonitoringComposer.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import StreamingCore
import StreamingCoreiOS

/// Factory that composes all performance monitoring components
public enum PerformanceMonitoringComposer {

	/// Creates a fully wired performance monitoring system for a video player
	/// - Parameters:
	///   - player: The AVPlayer to observe
	///   - thresholds: Performance thresholds for alerts
	/// - Returns: A configured VideoPlayerPerformanceAdapter
	public static func makePerformanceAdapter(
		for player: AVPlayer,
		thresholds: PerformanceThresholds = .default
	) -> VideoPlayerPerformanceAdapter {
		let performanceService = PlaybackPerformanceService(thresholds: thresholds)
		let bandwidthEstimator = NetworkBandwidthEstimator()

		let adapter = VideoPlayerPerformanceAdapter(
			performanceService: performanceService,
			bandwidthEstimator: bandwidthEstimator
		)

		// Create and wire up AVPlayer observer
		let playerObserver = AVPlayerPerformanceObserver(player: player)
		playerObserver.startObserving()
		adapter.observePlayer(playerObserver)

		return adapter
	}

	/// Creates components needed for full performance monitoring integration
	/// - Parameter thresholds: Performance thresholds for alerts
	/// - Returns: Tuple containing all monitoring components
	public static func makeComponents(
		thresholds: PerformanceThresholds = .default
	) -> (
		performanceService: PlaybackPerformanceService,
		bandwidthEstimator: NetworkBandwidthEstimator,
		networkMonitor: NetworkQualityMonitor,
		memoryMonitor: PollingMemoryMonitor
	) {
		let performanceService = PlaybackPerformanceService(thresholds: thresholds)
		let bandwidthEstimator = NetworkBandwidthEstimator()
		let networkMonitor = NetworkQualityMonitor()
		let memoryMonitor = MemoryMonitorFactory.makeSystemMemoryMonitor()

		return (performanceService, bandwidthEstimator, networkMonitor, memoryMonitor)
	}
}
