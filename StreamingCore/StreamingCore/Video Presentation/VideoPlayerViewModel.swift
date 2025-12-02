//
//  VideoPlayerViewModel.swift
//  StreamingCore
//
//  Created by Octavio Rojas on 02/12/25.
//

import Foundation

public struct VideoPlayerViewModel {
	public let title: String
	public let videoURL: URL

	public init(title: String, videoURL: URL) {
		self.title = title
		self.videoURL = videoURL
	}
}
