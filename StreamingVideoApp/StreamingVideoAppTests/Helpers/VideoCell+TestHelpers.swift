//
//  VideoCell+TestHelpers.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCoreiOS

extension VideoCell {
	var renderedImage: Data? {
		return videoImageView.image?.pngData()
	}
}
