//
//  PlaybackTransition.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents a state transition in the playback state machine.
/// Captures the complete context of a state change for analytics, debugging, and undo.
public struct PlaybackTransition: Equatable, Sendable {
	/// The state before the transition
	public let from: PlaybackState

	/// The state after the transition
	public let to: PlaybackState

	/// The action that triggered this transition
	public let action: PlaybackAction

	/// When this transition occurred
	public let timestamp: Date

	public init(
		from: PlaybackState,
		to: PlaybackState,
		action: PlaybackAction,
		timestamp: Date = Date()
	) {
		self.from = from
		self.to = to
		self.action = action
		self.timestamp = timestamp
	}

	/// Whether this transition actually changed the state.
	/// Returns false for no-op transitions where from == to.
	public var didChangeState: Bool {
		from != to
	}
}
