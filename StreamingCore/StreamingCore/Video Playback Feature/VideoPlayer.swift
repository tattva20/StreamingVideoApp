//
//  VideoPlayer.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

/// A protocol defining video playback capabilities.
///
/// `VideoPlayer` abstracts video playback operations, allowing different
/// implementations (AVPlayer, custom players, test doubles) to be used
/// interchangeably. This enables the Decorator pattern for adding features
/// like analytics, logging, or state management.
///
/// ## Thread Safety
/// Implementations should be `@MainActor` isolated for UI thread safety.
///
/// ## Conformance Requirements
/// - Must be a reference type (`AnyObject`) to support identity-based operations
/// - All state properties must reflect the current playback state accurately
public protocol VideoPlayer: AnyObject {
	/// Whether the video is currently playing.
	var isPlaying: Bool { get }

	/// The current playback position in seconds.
	var currentTime: TimeInterval { get }

	/// The total duration of the video in seconds.
	var duration: TimeInterval { get }

	/// The current volume level (0.0 to 1.0).
	var volume: Float { get }

	/// Whether audio is currently muted.
	var isMuted: Bool { get }

	/// The current playback speed multiplier.
	var playbackSpeed: Float { get }

	/// Loads a video from the specified URL.
	/// - Parameter url: The URL of the video to load
	func load(url: URL)

	/// Starts or resumes playback.
	func play()

	/// Pauses playback.
	func pause()

	/// Seeks forward by the specified duration.
	/// - Parameter seconds: Number of seconds to seek forward
	func seekForward(by seconds: TimeInterval)

	/// Seeks backward by the specified duration.
	/// - Parameter seconds: Number of seconds to seek backward
	func seekBackward(by seconds: TimeInterval)

	/// Seeks to a specific time position.
	/// - Parameter time: The target time in seconds
	func seek(to time: TimeInterval)

	/// Sets the playback volume.
	/// - Parameter volume: Volume level (0.0 to 1.0)
	func setVolume(_ volume: Float)

	/// Toggles the mute state.
	func toggleMute()

	/// Sets the playback speed.
	/// - Parameter speed: Speed multiplier (e.g., 0.5, 1.0, 1.5, 2.0)
	func setPlaybackSpeed(_ speed: Float)
}
