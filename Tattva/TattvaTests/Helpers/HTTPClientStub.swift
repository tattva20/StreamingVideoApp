//
//  HTTPClientStub.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore

final class HTTPClientStub: HTTPClient {
	private let stub: @Sendable (URL) -> Result<(Data, HTTPURLResponse), Error>

	init(stub: @escaping @Sendable (URL) -> Result<(Data, HTTPURLResponse), Error>) {
		self.stub = stub
	}

	func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
		try stub(url).get()
	}
}

extension HTTPClientStub {
	static var offline: HTTPClientStub {
		HTTPClientStub(stub: { _ in .failure(NSError(domain: "offline", code: 0)) })
	}

	static func online(_ stub: @escaping @Sendable (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
		HTTPClientStub { url in .success(stub(url)) }
	}
}
