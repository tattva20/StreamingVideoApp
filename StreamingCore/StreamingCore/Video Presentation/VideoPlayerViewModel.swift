//
//  VideoPlayerViewModel.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
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
