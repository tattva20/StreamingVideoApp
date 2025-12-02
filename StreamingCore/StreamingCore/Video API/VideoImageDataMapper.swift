//
//  VideoImageDataMapper.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public final class VideoImageDataMapper {
	public enum Error: Swift.Error {
		case invalidData
	}

	public static func map(_ data: Data, from response: HTTPURLResponse) throws -> Data {
		guard response.isOK, !data.isEmpty else {
			throw Error.invalidData
		}

		return data
	}
}
