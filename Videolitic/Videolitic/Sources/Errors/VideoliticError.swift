//
//  VideoliticError.swift
//  Videolitic
//
//  Created by Michał Rogowski on 30/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import Foundation

/// Error used in Videolitic
enum VideoliticError: Error, RawRepresentable, LocalizedError {

    typealias RawValue = String

    enum AudioProcessorServiceError: String {

        case cannotCrateExportSession
    }

    enum VideoReaderError: String {

        case assetReaderCantAddOutput
        case videoTrackDoesNotExist
    }

    enum VideoProcessorServiceError: String {

        case assetDoNotExist
        case cantConvertToAudio
        case cantGenerateUIImage
        case detectingCancelled
        case readerInitializationFailed
        case firstFrameReadFailed
        case objectTrackingFailed
        case rectangleDetectionFailed
    }

    case audioProcessorService(AudioProcessorServiceError)
    case videoProcessorService(VideoProcessorServiceError)
    case videoReader(VideoReaderError)

    var rawValue: String {
        switch self {
        case let .audioProcessorService(error):
            return error.rawValue
        case let .videoProcessorService(error):
            return error.rawValue
        case let .videoReader(error):
            return error.rawValue
        }
    }

    var errorDescription: String? { "\(self) ".capitalized + rawValue }

    init?(rawValue: String) {
        return nil
    }
}
