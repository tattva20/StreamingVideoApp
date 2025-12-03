//
//  PictureInPictureControlling.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public protocol PictureInPictureControlling: AnyObject {
	var isPictureInPictureActive: Bool { get }
	var isPictureInPicturePossible: Bool { get }
	func togglePictureInPicture()
	func startPictureInPicture()
	func stopPictureInPicture()
}
