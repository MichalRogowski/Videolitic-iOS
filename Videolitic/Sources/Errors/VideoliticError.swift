//
//  VideoliticError.swift
//  Videolitic
//
//  Created by Michał Rogowski on 30/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//

import Foundation

/// Error used in Videolitic
enum VideoliticError: Error, RawRepresentable, LocalizedError {

    typealias RawValue = String

    enum AudioProcessorServiceError: String {

        case exportSessionWasCancelled
        case cannotCrateExportSession
        case notAuthorized
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
