//
//  ResourceErrorView.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
@MainActor
public protocol ResourceErrorView {
	func display(_ viewModel: ResourceErrorViewModel)
}
