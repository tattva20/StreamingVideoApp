//
//  VideoPlayer.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public protocol VideoPlayer: AnyObject {
	var isPlaying: Bool { get }
	var currentTime: TimeInterval { get }
	var duration: TimeInterval { get }
	var volume: Float { get }
	var isMuted: Bool { get }
	var playbackSpeed: Float { get }

	func load(url: URL)
	func play()
	func pause()
	func seekForward(by seconds: TimeInterval)
	func seekBackward(by seconds: TimeInterval)
	func seek(to time: TimeInterval)
	func setVolume(_ volume: Float)
	func toggleMute()
	func setPlaybackSpeed(_ speed: Float)
}
