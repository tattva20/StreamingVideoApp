//
//  PlaybackError.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

/// Represents errors that can occur during video playback.
/// Categorizes errors by type to enable appropriate recovery strategies.
public enum PlaybackError: Error, Equatable, Sendable {
	case loadFailed(reason: String)
	case networkError(reason: String)
	case decodingError(reason: String)
	case drmError(reason: String)
	case unknown(reason: String)

	/// Whether this error can potentially be recovered from by retrying
	public var isRecoverable: Bool {
		switch self {
		case .networkError:
			return true
		default:
			return false
		}
	}
}
