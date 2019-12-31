//
//  MockAudioProcessorService.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 03/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
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


import Combine
import Speech
@testable import Videolitic

final class MockAudioProcessorService: AudioProcessorServiceInterface {

    var expectedRecognizedSpeech: (segments: [SFTranscriptionSegment]?, error: Error?) = (nil, nil)
    var expectedAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var expectedConvertionResult: (status: AVAssetExportSession.Status?, error: Error?) = (nil, nil)

    var recognizeSpeechPublisher: Future<[SFTranscriptionSegment], Error> {
        Future<[SFTranscriptionSegment], Error> { promise in
            if let segments = self.expectedRecognizedSpeech.segments {
                promise(.success(segments))
            } else if let error = self.expectedRecognizedSpeech.error {
                promise(.failure(error))
            } else {
                promise(.failure(UnitTestErrors.audioProcessor(.noRecognizedResult)))
            }
        }
    }

    func authorizeIfNeeded() -> Future<SFSpeechRecognizerAuthorizationStatus, Error> {
        Future<SFSpeechRecognizerAuthorizationStatus, Error> { $0(.success(self.expectedAuthorizationStatus)) }
    }

    func convert(video asset: AVAsset, toAudioNamed name: String) -> Future<AVAssetExportSession.Status, Error> {
        Future<AVAssetExportSession.Status, Error> { promise in
            if let status = self.expectedConvertionResult.status {
                promise(.success(status))
            } else if let error = self.expectedConvertionResult.error {
                promise(.failure(error))
            } else {
                promise(.failure(UnitTestErrors.audioProcessor(.noConvertResult)))
            }
        }
    }
}
