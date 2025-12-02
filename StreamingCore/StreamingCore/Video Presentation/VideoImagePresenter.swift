//
//  VideoImagePresenter.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public final class VideoImagePresenter {
    public static func map(_ video: Video) -> VideoImageViewModel {
        VideoImageViewModel(
            title: video.title,
            description: video.description)
    }
}
