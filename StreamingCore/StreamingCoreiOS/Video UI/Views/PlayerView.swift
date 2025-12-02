//
//  PlayerView.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import AVFoundation

public final class PlayerView: UIView {
	public override class var layerClass: AnyClass {
		AVPlayerLayer.self
	}

	public var playerLayer: AVPlayerLayer {
		layer as! AVPlayerLayer
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		playerLayer.frame = bounds
		playerLayer.videoGravity = .resizeAspect
	}
}
