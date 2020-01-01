//
//  SpeechRecognizer.swift
//  Videolitic
//
//  Created by Michał Rogowski on 29/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import Speech

/// Interface over `SpeechRecognizer`
protocol SpeechRecognizerInterface: class {

    // Recognize speech utterance with a request
    // If request.shouldReportPartialResults is true, result handler will be called
    // repeatedly with partial results, then finally with a final result or an error.
    /// - Parameters:
    ///   - url: URL of audio
    ///   - resultHandler: Check SFSpeechRecognizer recognitionTask `resultHandler`
    @discardableResult
    func recognitionTask(with url: URL, resultHandler: @escaping (SpeechRecognitionResultInterface?, Error?) -> Void) -> SFSpeechRecognitionTask?
}

final class SpeechRecognizer: SpeechRecognizerInterface {

    private let sfSpeechRecognizer = SFSpeechRecognizer()

    // MARK: Initialisation

    init(defaultTaskHint: SFSpeechRecognitionTaskHint) {
        sfSpeechRecognizer?.defaultTaskHint = defaultTaskHint
    }

    // MARK: Public functions

    @discardableResult
    func recognitionTask(with url: URL, resultHandler: @escaping (SpeechRecognitionResultInterface?, Error?) -> Void) -> SFSpeechRecognitionTask? {
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true
        return sfSpeechRecognizer?.recognitionTask(with: request) { result, error in
            guard let sfResult = result else {
                resultHandler(nil, error)
                return
            }
            resultHandler(SpeechRecognitionResult(sfSpeechRecognitionResult: sfResult), error)
        }
    }
}
