//
//  FileSystemVideoImageDataStoreTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore

@MainActor
class FileSystemVideoImageDataStoreTests: XCTestCase, FailableRetrieveVideoImageDataStoreSpecs, FailableInsertVideoImageDataStoreSpecs {

    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieveImageData_deliversNotFoundWhenEmpty() throws {
        let sut = makeSUT()

        assertThatRetrieveImageDataDeliversNotFoundOnEmptyCache(on: sut)
    }

    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() throws {
        let sut = makeSUT()

        assertThatRetrieveImageDataDeliversNotFoundWhenStoredDataURLDoesNotMatch(on: sut)
    }

    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() throws {
        let sut = makeSUT()

        assertThatRetrieveImageDataDeliversFoundDataWhenThereIsAStoredImageDataMatchingURL(on: sut)
    }

    func test_retrieveImageData_deliversLastInsertedValue() throws {
        let sut = makeSUT()

        assertThatRetrieveImageDataDeliversLastInsertedValueForURL(on: sut)
    }

    func test_insert_overridesPreviouslyInsertedDataForSameURL() throws {
        let sut = makeSUT()
        let firstStoredData = Data("first".utf8)
        let latestStoredData = Data("latest".utf8)
        let url = URL(string: "https://a-url.com")!

        try sut.insert(firstStoredData, for: url)
        try sut.insert(latestStoredData, for: url)

        expect(sut, toCompleteRetrievalWith: found(latestStoredData), for: url)
    }

    func test_retrieveImageData_deliversFailureOnRetrievalError() throws {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toCompleteRetrievalWith: .failure(anyNSError()), for: anyURL())
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)

        let insertionError = insertAndCaptureError(anyData(), for: anyURL(), into: sut)

        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FileSystemVideoImageDataStore {
        let sut = FileSystemVideoImageDataStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func insertAndCaptureError(_ data: Data, for url: URL, into sut: FileSystemVideoImageDataStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        do {
            try sut.insert(data, for: url)
            return nil
        } catch {
            return error
        }
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
