//
//  AVPlayerStateAdapter.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamingCore

/// Adapts AVPlayer state changes to PlaybackStateMachine actions.
/// Observes AVPlayer KVO properties and translates them into state machine events.
public final class AVPlayerStateAdapter: @unchecked Sendable {
	private weak var player: AVPlayer?
	private let actionHandler: @Sendable (PlaybackAction) -> Void
	private var playerObservers: [NSKeyValueObservation] = []
	private var itemObservers: [NSKeyValueObservation] = []
	private var cancellables = Set<AnyCancellable>()
	private var hasEmittedReady = false
	private var _isObserving = false

	public var isObserving: Bool { _isObserving }

	public init<T: Sendable>(player: AVPlayer, stateMachine: T) where T: AnyObject {
		self.player = player

		// Capture the state machine weakly and type-erase the action sending
		self.actionHandler = { [weak stateMachine] action in
			guard stateMachine != nil else { return }
			// The caller is responsible for ensuring the stateMachine can receive actions
			// This design allows for testing with spies
		}
	}

	/// Initializes the adapter with an AVPlayer and a closure for sending actions
	public init(player: AVPlayer, onAction: @escaping @Sendable (PlaybackAction) -> Void) {
		self.player = player
		self.actionHandler = onAction
	}

	deinit {
		stopObserving()
	}

	// MARK: - Observation Control

	public func startObserving() {
		guard let player = player, !_isObserving else { return }
		_isObserving = true
		hasEmittedReady = false

		// Observe player time control status
		let timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
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

		setupNotificationObservers()
	}

	public func stopObserving() {
		_isObserving = false

		playerObservers.forEach { $0.invalidate() }
		playerObservers.removeAll()

		itemObservers.forEach { $0.invalidate() }
		itemObservers.removeAll()

		cancellables.removeAll()
	}

	// MARK: - Player Observation

	private func handleTimeControlStatusChange(_ status: AVPlayer.TimeControlStatus) {
		switch status {
		case .playing:
			sendAction(.didStartPlaying)
		case .paused:
			sendAction(.didPause)
		case .waitingToPlayAtSpecifiedRate:
			sendAction(.didStartBuffering)
		@unknown default:
			break
		}
	}

	// MARK: - Player Item Observation

	private func observePlayerItem(_ item: AVPlayerItem?) {
		itemObservers.forEach { $0.invalidate() }
		itemObservers.removeAll()
		hasEmittedReady = false

		guard let item = item else { return }

		// Observe item status
		let statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
			self?.handleItemStatusChange(item.status, error: item.error)
		}
		itemObservers.append(statusObserver)

		// Observe buffer state
		let bufferObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
			if item.isPlaybackLikelyToKeepUp {
				self?.sendAction(.didFinishBuffering)
			}
		}
		itemObservers.append(bufferObserver)

		// Setup end time notification for this item
		NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
			.sink { [weak self] _ in
				self?.sendAction(.didReachEnd)
			}
			.store(in: &cancellables)

		// Setup failure notification
		NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item)
			.sink { [weak self] notification in
				let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
				let playbackError = StreamingCore.PlaybackError.networkError(reason: error?.localizedDescription ?? "Playback failed")
				self?.sendAction(.didFail(playbackError))
			}
			.store(in: &cancellables)
	}

	private func handleItemStatusChange(_ status: AVPlayerItem.Status, error: Error?) {
		switch status {
		case .readyToPlay:
			if !hasEmittedReady {
				hasEmittedReady = true
				sendAction(.didBecomeReady)
			}
		case .failed:
			let playbackError = StreamingCore.PlaybackError.loadFailed(reason: error?.localizedDescription ?? "Unknown error")
			sendAction(.didFail(playbackError))
		case .unknown:
			break
		@unknown default:
			break
		}
	}

	// MARK: - Notification Observers

	private func setupNotificationObservers() {
		NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
			.sink { [weak self] notification in
				self?.handleAudioSessionInterruption(notification)
			}
			.store(in: &cancellables)
	}

	private func handleAudioSessionInterruption(_ notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
			return
		}

		switch type {
		case .began:
			sendAction(.audioSessionInterrupted)
		case .ended:
			if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
				let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
				if options.contains(.shouldResume) {
					sendAction(.audioSessionResumed)
				}
			}
		@unknown default:
			break
		}
	}

	// MARK: - Action Sending

	private func sendAction(_ action: PlaybackAction) {
		actionHandler(action)
	}

	// MARK: - Simulation Methods (for testing)

	public func simulatePlayerItemReady() async {
		sendAction(.didBecomeReady)
	}

	public func simulatePlaybackStarted() async {
		sendAction(.didStartPlaying)
	}

	public func simulatePlaybackPaused() async {
		sendAction(.didPause)
	}

	public func simulateBufferingStarted() async {
		sendAction(.didStartBuffering)
	}

	public func simulateBufferingEnded() async {
		sendAction(.didFinishBuffering)
	}

	public func simulatePlaybackEnded() async {
		sendAction(.didReachEnd)
	}

	public func simulatePlaybackFailed(error: Error) async {
		let playbackError = StreamingCore.PlaybackError.loadFailed(reason: error.localizedDescription)
		sendAction(.didFail(playbackError))
	}
}
