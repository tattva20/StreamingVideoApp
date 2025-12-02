//
//  VideoPlayerStub.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore

class VideoPlayerStub: VideoPlayer {
	var isPlaying: Bool = false
	var currentTime: TimeInterval = 0
	var duration: TimeInterval = 0
	var volume: Float = 1.0
	var isMuted: Bool = false
	var playbackSpeed: Float = 1.0

	func load(url: URL) {}
	func play() { isPlaying = true }
	func pause() { isPlaying = false }
	func seekForward(by seconds: TimeInterval) {}
	func seekBackward(by seconds: TimeInterval) {}
	func seek(to time: TimeInterval) {}
	func setVolume(_ volume: Float) { self.volume = volume }
	func toggleMute() { isMuted.toggle() }
	func setPlaybackSpeed(_ speed: Float) { playbackSpeed = speed }
}
