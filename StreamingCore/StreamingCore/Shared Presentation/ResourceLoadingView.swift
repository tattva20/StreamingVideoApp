//
//  ResourceLoadingView.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
@MainActor
public protocol ResourceLoadingView {
	func display(_ viewModel: ResourceLoadingViewModel)
}
