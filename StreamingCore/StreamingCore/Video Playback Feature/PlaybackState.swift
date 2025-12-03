//
//  PlaybackState.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents all possible states of a video player.
/// Forms the core of the playback state machine with explicit, testable transitions.
public enum PlaybackState: Equatable, Sendable, CustomStringConvertible {
	case idle
	case loading(URL)
	case ready
	case playing
	case paused
	case buffering(previousState: ResumableState)
	case seeking(to: TimeInterval, previousState: ResumableState)
	case ended
	case failed(PlaybackError)

	/// States that can be resumed after buffering or seeking completes
	public enum ResumableState: Equatable, Sendable {
		case playing
		case paused
	}

	public var description: String {
		switch self {
		case .idle: return "idle"
		case .loading: return "loading"
		case .ready: return "ready"
		case .playing: return "playing"
		case .paused: return "paused"
		case .buffering: return "buffering"
		case .seeking: return "seeking"
		case .ended: return "ended"
		case .failed: return "failed"
		}
	}

	/// Whether playback is conceptually "active" (for analytics tracking).
	/// Returns true when video is playing or will resume playing after buffering/seeking.
	public var isActive: Bool {
		switch self {
		case .playing:
			return true
		case .buffering(let previousState):
			return previousState == .playing
		case .seeking(_, let previousState):
			return previousState == .playing
		default:
			return false
		}
	}

	/// Whether the player can receive play commands in this state.
	/// Returns true for states where starting/resuming playback is valid.
	public var canPlay: Bool {
		switch self {
		case .ready, .paused, .ended:
			return true
		default:
			return false
		}
	}

	/// Whether the player can receive pause commands in this state.
	/// Returns true for states where pausing is valid.
	public var canPause: Bool {
		switch self {
		case .playing:
			return true
		case .buffering(let previousState):
			return previousState == .playing
		default:
			return false
		}
	}
}
