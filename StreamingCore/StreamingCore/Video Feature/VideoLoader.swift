//
//  VideoLoader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import Combine

@MainActor
public protocol VideoLoader {
    func load() -> AnyPublisher<[Video], Error>
}
