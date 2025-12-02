//
//  VideoImageDataStoreSpecs.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

protocol VideoImageDataStoreSpecs {
    func test_retrieveImageData_deliversNotFoundWhenEmpty() throws
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() throws
    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() throws
    func test_retrieveImageData_deliversLastInsertedValue() throws
}

protocol FailableRetrieveVideoImageDataStoreSpecs: VideoImageDataStoreSpecs {
    func test_retrieveImageData_deliversFailureOnRetrievalError() throws
}

protocol FailableInsertVideoImageDataStoreSpecs: VideoImageDataStoreSpecs {
    func test_insert_deliversErrorOnInsertionError()
}

typealias FailableVideoImageDataStoreSpecs = FailableRetrieveVideoImageDataStoreSpecs & FailableInsertVideoImageDataStoreSpecs
