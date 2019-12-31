//
//  UnitTestErrors.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 29/11/2019.
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

enum UnitTestErrors: Error, RawRepresentable, LocalizedError {

    typealias RawValue = String

    enum AudioProcessorError: String {
        
        case general
        case noConvertResult
        case noRecognizedResult
    }

    enum FaceComputingError: String {

        case noFacesResult
    }

    enum URLError: String {

        case cantCreate
    }

    case audioProcessor(AudioProcessorError)
    case url(URLError)
    case faceComputing(FaceComputingError)

    var rawValue: String {
        switch self {
        case let .audioProcessor(error):
            return error.rawValue
        case let .faceComputing(error):
            return error.rawValue
        case let .url(error):
            return error.rawValue
        }
    }

    var errorDescription: String? { "\(self) ".capitalized + rawValue }
    
    init?(rawValue: String) {
        return nil
    }
}
