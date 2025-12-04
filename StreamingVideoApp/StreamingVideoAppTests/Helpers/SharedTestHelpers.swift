//
//  SharedTestHelpers.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore

func anyNSError() -> NSError {
	return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
	return URL(string: "https://any-url.com")!
}

func anyData() -> Data {
	return Data("any data".utf8)
}

func uniqueVideos() -> [Video] {
	return [Video(id: UUID(), title: "any", description: "any", url: anyURL(), thumbnailURL: anyURL(), duration: 100)]
}

private class DummyView: ResourceView {
	func display(_ viewModel: Any) {}
}

var loadError: String {
	LoadResourcePresenter<Any, DummyView>.loadError
}

var videosTitle: String {
	VideosPresenter.title
}
