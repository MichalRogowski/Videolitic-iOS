//
//  SpeechRecognizer.swift
//  Videolitic
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

import Combine
import Speech

/// Interface over `SpeechRecognizer`
protocol SpeechRecognizerInterface: class {

    /// Returns your app's current authorization to perform speech recognition.
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus { get }

    // Recognize speech utterance with a request
    // If request.shouldReportPartialResults is true, result handler will be called
    // repeatedly with partial results, then finally with a final result or an error.
    /// - Parameters:
    ///   - url: URL of audio
    ///   - resultHandler: Check SFSpeechRecognizer recognitionTask `resultHandler`
    @discardableResult
    func recognitionTask(with url: URL, resultHandler: @escaping (SpeechRecognitionResultInterface?, Error?) -> Void) -> SFSpeechRecognitionTask?

    func requestAuthorization() -> Future<SFSpeechRecognizerAuthorizationStatus, Error>
}

final class SpeechRecognizer: SpeechRecognizerInterface {

    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus { SFSpeechRecognizer.authorizationStatus() }

    private let sfSpeechRecognizer = SFSpeechRecognizer()

    // MARK: Initialisation

    init(defaultTaskHint: SFSpeechRecognitionTaskHint) {
        sfSpeechRecognizer?.defaultTaskHint = defaultTaskHint
    }

    // MARK: Public functions

    @discardableResult
    func recognitionTask(with url: URL, resultHandler: @escaping (SpeechRecognitionResultInterface?, Error?) -> Void) -> SFSpeechRecognitionTask? {
        let request = SFSpeechURLRecognitionRequest(url: url)
        let forceOnDevice: Bool
        #if targetEnvironment(simulator)
        forceOnDevice = false
        #else
        forceOnDevice = true
        #endif
        request.requiresOnDeviceRecognition = forceOnDevice
        return sfSpeechRecognizer?.recognitionTask(with: request) { result, error in
            guard let sfResult = result else {
                resultHandler(nil, error)
                return
            }
            resultHandler(SpeechRecognitionResult(sfSpeechRecognitionResult: sfResult), error)
        }
    }

    func requestAuthorization() -> Future<SFSpeechRecognizerAuthorizationStatus, Error> {
        Future<SFSpeechRecognizerAuthorizationStatus, Error> { promise in
            SFSpeechRecognizer.requestAuthorization { status in
                promise(.success(status))
            }
        }
    }
}
