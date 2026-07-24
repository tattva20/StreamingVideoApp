//
//  AVPlayerVideoPlayer+PlayerView.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import AVFoundation
import StreamingCoreiOS
import StreamingCorePlayback

extension AVPlayerVideoPlayer {
	func attach(to playerView: PlayerView) {
		playerView.playerLayer.player = player
	}
}
