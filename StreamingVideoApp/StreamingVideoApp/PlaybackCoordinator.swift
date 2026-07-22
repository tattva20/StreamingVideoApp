//
//  PlaybackCoordinator.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import AVFoundation
import StreamingCore
import StreamingCoreiOS

@MainActor
final class PlaybackCoordinator {
	private let player: AVPlayer
	private let stateMachine: DefaultPlaybackStateMachine
	private let performanceAdapter: VideoPlayerPerformanceAdapter
	private let onTimeUpdate: @MainActor (TimeInterval) -> Void

	private(set) var stateAdapter: AVPlayerStateAdapter?
	private var performanceObserver: AVPlayerPerformanceObserver?
	private var timeObserverToken: Any?

	var isObserving: Bool {
		stateAdapter?.isObserving ?? false
	}

	init(
		player: AVPlayer,
		stateMachine: DefaultPlaybackStateMachine,
		performanceAdapter: VideoPlayerPerformanceAdapter,
		onTimeUpdate: @escaping @MainActor (TimeInterval) -> Void = { _ in }
	) {
		self.player = player
		self.stateMachine = stateMachine
		self.performanceAdapter = performanceAdapter
		self.onTimeUpdate = onTimeUpdate
	}

	func start() {
		guard stateAdapter == nil else { return }

		let stateMachine = self.stateMachine
		let adapter = AVPlayerStateAdapter(player: player, onAction: { action in
			Task { @MainActor in stateMachine.send(action) }
		})
		adapter.startObserving()
		stateAdapter = adapter

		let observer = AVPlayerPerformanceObserver(player: player)
		observer.startObserving()
		performanceAdapter.observePlayer(observer)
		performanceObserver = observer

		let onTimeUpdate = self.onTimeUpdate
		let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
		timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
			MainActor.assumeIsolated { onTimeUpdate(time.seconds) }
		}
	}

	func stop() {
		if let timeObserverToken {
			player.removeTimeObserver(timeObserverToken)
			self.timeObserverToken = nil
		}
		stateAdapter?.stopObserving()
		stateAdapter = nil
		performanceObserver?.stopObserving()
		performanceObserver = nil
	}
}
