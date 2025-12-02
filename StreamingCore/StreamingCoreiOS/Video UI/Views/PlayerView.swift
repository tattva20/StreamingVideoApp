//
//  PlayerView.swift
//  StreamingCoreiOS
//
//  Created by Octavio Rojas on 02/12/25.
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
