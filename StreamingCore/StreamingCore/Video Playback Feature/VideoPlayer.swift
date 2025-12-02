//
//  VideoPlayer.swift
//  StreamingCore
//
//  Created by Octavio Rojas on 02/12/25.
//

import Foundation

public protocol VideoPlayer: AnyObject {
	var isPlaying: Bool { get }
	func load(url: URL)
	func play()
	func pause()
}
