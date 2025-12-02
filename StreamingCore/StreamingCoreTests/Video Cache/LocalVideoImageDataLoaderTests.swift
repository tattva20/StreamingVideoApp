//
//  LocalVideoImageDataLoaderTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore

@MainActor
class LocalVideoImageDataLoaderTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheInsertion() throws {
        let (sut, store) = makeSUT()
        let data = anyData()
        let url = anyURL()

        store.completeInsertionSuccessfully()

        try sut.save(data, for: url)

        XCTAssertEqual(store.receivedMessages, [.insert(data: data, url: url)])
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()

        store.completeInsertion(with: anyNSError())

        do {
            try sut.save(anyData(), for: anyURL())
            XCTFail("Expected save to fail")
        } catch {
            // Expected error
        }
    }

    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        let url = anyURL()

        store.completeRetrieval(with: anyData())

        _ = try? sut.loadImageData(from: url)

        XCTAssertEqual(store.receivedMessages, [.retrieve(url: url)])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()

        store.completeRetrieval(with: anyNSError())

        do {
            _ = try sut.loadImageData(from: anyURL())
            XCTFail("Expected load to fail")
        } catch {
            // Expected error
        }
    }

    func test_load_deliversDataOnFoundData() throws {
        let (sut, store) = makeSUT()
        let foundData = anyData()

        store.completeRetrieval(with: foundData)

        let retrievedData = try sut.loadImageData(from: anyURL())

        XCTAssertEqual(retrievedData, foundData)
    }

    func test_load_failsOnNotFound() {
        let (sut, store) = makeSUT()

        store.completeRetrieval(with: nil)

        do {
            _ = try sut.loadImageData(from: anyURL())
            XCTFail("Expected load to fail on not found")
        } catch {
            // Expected error
        }
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalVideoImageDataLoader, store: VideoImageDataStoreSpy) {
        let store = VideoImageDataStoreSpy()
        let sut = LocalVideoImageDataLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    private func anyData() -> Data {
        return Data("any data".utf8)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private class VideoImageDataStoreSpy: VideoImageDataStore {
        enum Message: Equatable {
            case insert(data: Data, url: URL)
            case retrieve(url: URL)
        }

        private(set) var receivedMessages = [Message]()
        private var retrievalResult: Result<Data?, Error>?
        private var insertionResult: Result<Void, Error>?

        func insert(_ data: Data, for url: URL) throws {
            receivedMessages.append(.insert(data: data, url: url))
            try insertionResult?.get()
        }

        func retrieve(dataForURL url: URL) throws -> Data? {
            receivedMessages.append(.retrieve(url: url))
            return try retrievalResult?.get()
        }

        func completeRetrieval(with error: Error) {
            retrievalResult = .failure(error)
        }

        func completeRetrieval(with data: Data?) {
            retrievalResult = .success(data)
        }

        func completeInsertion(with error: Error) {
            insertionResult = .failure(error)
        }

        func completeInsertionSuccessfully() {
            insertionResult = .success(())
        }
    }
}
