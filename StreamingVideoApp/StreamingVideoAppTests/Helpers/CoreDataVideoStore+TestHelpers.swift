//
//  CoreDataVideoStore+TestHelpers.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore

@MainActor
extension CoreDataVideoStore {
    static var empty: CoreDataVideoStore {
        get throws {
            try CoreDataVideoStore(storeURL: URL(fileURLWithPath: "/dev/null"), contextQueue: .main)
        }
    }

    static var withExpiredVideoCache: CoreDataVideoStore {
        get throws {
            let store = try CoreDataVideoStore.empty
            try store.insert([], timestamp: .distantPast)
            return store
        }
    }

    static var withNonExpiredVideoCache: CoreDataVideoStore {
        get throws {
            let store = try CoreDataVideoStore.empty
            try store.insert([], timestamp: Date())
            return store
        }
    }
}
