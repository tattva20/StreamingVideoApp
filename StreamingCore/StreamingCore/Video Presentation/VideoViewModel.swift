//
//  VideoViewModel.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
public struct VideoViewModel {
	public let title: String?
	public let description: String?

	public init(title: String?, description: String?) {
		self.title = title
		self.description = description
	}

	public var hasTitle: Bool {
		return title != nil
	}
}