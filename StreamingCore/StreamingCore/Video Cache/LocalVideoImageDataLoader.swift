//
//  LocalVideoImageDataLoader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public final class LocalVideoImageDataLoader {
    private let store: VideoImageDataStore

    public init(store: VideoImageDataStore) {
        self.store = store
    }
}

extension LocalVideoImageDataLoader: VideoImageDataCache {
    public enum SaveError: Error {
        case failed
    }

    public func save(_ data: Data, for url: URL) throws {
        do {
            try store.insert(data, for: url)
        } catch {
            throw SaveError.failed
        }
    }
}

extension LocalVideoImageDataLoader: VideoImageDataLoader {
	public enum LoadError: Error {
		case notFound
		case failed
	}

	public func loadImageData(from url: URL) throws -> Data {
		do {
			if let data = try store.retrieve(dataForURL: url) {
				return data
			} else {
				throw LoadError.notFound
			}
		} catch let error as LoadError {
			throw error
		} catch {
			throw LoadError.failed
		}
	}
}
