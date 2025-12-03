//
//  PlaybackAction.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents all possible actions/events that can be sent to the playback state machine.
/// Divided into user-initiated actions, system events, and external events.
public enum PlaybackAction: Equatable, Sendable {
	// MARK: - User-Initiated Actions

	/// User requests to load a video from the given URL
	case load(URL)

	/// User requests to start or resume playback
	case play

	/// User requests to pause playback
	case pause

	/// User requests to seek to a specific time position
	case seek(to: TimeInterval)

	/// User requests to stop playback and return to idle
	case stop

	/// User requests to retry after a recoverable error
	case retry

	// MARK: - System Events

	/// The player item has finished loading and is ready to play
	case didBecomeReady

	/// Playback has started
	case didStartPlaying

	/// Playback has paused
	case didPause

	/// Buffering has started due to insufficient data
	case didStartBuffering

	/// Buffering has completed and playback can continue
	case didFinishBuffering

	/// Seeking operation has started
	case didStartSeeking

	/// Seeking operation has completed
	case didFinishSeeking

	/// Playback reached the end of the content
	case didReachEnd

	/// An error occurred during playback
	case didFail(PlaybackError)

	// MARK: - External Events

	/// App entered background
	case didEnterBackground

	/// App became active
	case didBecomeActive

	/// Audio session was interrupted (e.g., phone call)
	case audioSessionInterrupted

	/// Audio session interruption ended
	case audioSessionResumed
}
