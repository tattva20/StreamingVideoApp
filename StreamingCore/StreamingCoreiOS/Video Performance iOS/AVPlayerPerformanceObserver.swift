//
//  AVPlayerPerformanceObserver.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamingCore

/// Playback state for AVPlayer performance observation (internal to observer)
public enum ObserverPlaybackState: Equatable, Sendable {
	case idle
	case playing
	case paused
	case buffering
	case stalled
	case failed(Error)

	public static func == (lhs: ObserverPlaybackState, rhs: ObserverPlaybackState) -> Bool {
		switch (lhs, rhs) {
		case (.idle, .idle), (.playing, .playing), (.paused, .paused),
			 (.buffering, .buffering), (.stalled, .stalled):
			return true
		case (.failed, .failed):
			return true
		default:
			return false
		}
	}
}

/// Buffering state for AVPlayerItem observation
public enum BufferingState: Equatable, Sendable {
	case unknown
	case buffering
	case ready
	case stalled
}

/// Observes AVPlayer state and emits performance events via Combine publishers
public final class AVPlayerPerformanceObserver: @unchecked Sendable {
	private weak var player: AVPlayer?
	private var playerObservers: [NSKeyValueObservation] = []
	private var itemObservers: [NSKeyValueObservation] = []
	private var timeObserver: Any?
	private var bufferingStartTime: Date?

	private let playbackStateSubject = CurrentValueSubject<ObserverPlaybackState, Never>(.idle)
	private let bufferingStateSubject = CurrentValueSubject<BufferingState, Never>(.unknown)
	private let performanceEventSubject = PassthroughSubject<PerformanceEvent, Never>()

	public var currentPlaybackState: ObserverPlaybackState {
		playbackStateSubject.value
	}

	public var currentBufferingState: BufferingState {
		bufferingStateSubject.value
	}

	public var playbackStatePublisher: AnyPublisher<ObserverPlaybackState, Never> {
		playbackStateSubject.eraseToAnyPublisher()
	}

	public var bufferingStatePublisher: AnyPublisher<BufferingState, Never> {
		bufferingStateSubject.eraseToAnyPublisher()
	}

	public var performanceEventPublisher: AnyPublisher<PerformanceEvent, Never> {
		performanceEventSubject.eraseToAnyPublisher()
	}

	public init(player: AVPlayer) {
		self.player = player
	}

	deinit {
		stopObserving()
	}

	// MARK: - Start/Stop Observing

	public func startObserving() {
		guard let player = player else { return }

		// Observe player time control status
		let timeControlObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
			self?.handleTimeControlStatusChange(player.timeControlStatus)
		}
		playerObservers.append(timeControlObserver)

		// Observe current item changes
		let currentItemObserver = player.observe(\.currentItem, options: [.new]) { [weak self] player, _ in
			self?.observePlayerItem(player.currentItem)
		}
		playerObservers.append(currentItemObserver)

		// Observe current item if already set
		if let currentItem = player.currentItem {
			observePlayerItem(currentItem)
		}
	}

	public func stopObserving() {
		playerObservers.forEach { $0.invalidate() }
		playerObservers.removeAll()

		itemObservers.forEach { $0.invalidate() }
		itemObservers.removeAll()

		if let timeObserver = timeObserver, let player = player {
			player.removeTimeObserver(timeObserver)
			self.timeObserver = nil
		}
	}

	// MARK: - Player Observation Handlers

	private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
		switch status {
		case .paused:
			playbackStateSubject.send(.paused)
		case .playing:
			playbackStateSubject.send(.playing)
		case .waitingToPlayAtSpecifiedRate:
			playbackStateSubject.send(.buffering)
		@unknown default:
			break
		}
	}

	// MARK: - Player Item Observation

	private func observePlayerItem(_ item: AVPlayerItem?) {
		// Clear existing item observers
		itemObservers.forEach { $0.invalidate() }
		itemObservers.removeAll()

		guard let item = item else {
			bufferingStateSubject.send(.unknown)
			return
		}

		// Observe buffer empty
		let bufferEmptyObserver = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
			self?.handleBufferStateChange(item)
		}
		itemObservers.append(bufferEmptyObserver)

		// Observe likely to keep up
		let likelyToKeepUpObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
			self?.handleBufferStateChange(item)
		}
		itemObservers.append(likelyToKeepUpObserver)

		// Observe buffer full
		let bufferFullObserver = item.observe(\.isPlaybackBufferFull, options: [.new]) { [weak self] item, _ in
			self?.handleBufferStateChange(item)
		}
		itemObservers.append(bufferFullObserver)

		// Observe item status
		let statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
			self?.handleItemStatusChange(item.status)
		}
		itemObservers.append(statusObserver)

		// Emit load started
		performanceEventSubject.send(.loadStarted)
	}

	private func handleBufferStateChange(_ item: AVPlayerItem) {
		let newState: BufferingState

		if item.isPlaybackBufferEmpty {
			newState = .buffering

			// Track buffering start
			if bufferingStartTime == nil {
				bufferingStartTime = Date()
				performanceEventSubject.send(.bufferingStarted)
			}
		} else if item.isPlaybackLikelyToKeepUp || item.isPlaybackBufferFull {
			newState = .ready

			// Track buffering end
			if let startTime = bufferingStartTime {
				let duration = Date().timeIntervalSince(startTime)
				performanceEventSubject.send(.bufferingEnded(duration: duration))
				bufferingStartTime = nil
			}
		} else {
			newState = .stalled

			if bufferingStartTime == nil {
				performanceEventSubject.send(.playbackStalled)
			}
		}

		bufferingStateSubject.send(newState)
	}

	private func handleItemStatusChange(_ status: AVPlayerItem.Status) {
		switch status {
		case .readyToPlay:
			performanceEventSubject.send(.firstFrameRendered)
		case .failed:
			playbackStateSubject.send(.failed(NSError(domain: "AVPlayer", code: -1)))
		case .unknown:
			break
		@unknown default:
			break
		}
	}
}
