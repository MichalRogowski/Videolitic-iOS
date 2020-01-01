//
//  MockSpeechRecognizer.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 29/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import Speech
@testable import Videolitic

final class MockSpeechRecognizer: SpeechRecognizerInterface {

    // MARK: Public properties

    var expectedResult: SpeechRecognitionResultInterface?
    var expectedError: Error?

    var defaultTaskHint: SFSpeechRecognitionTaskHint = .dictation

    // MARK: Public functions

    func recognitionTask(with url: URL, resultHandler: @escaping (SpeechRecognitionResultInterface?, Error?) -> Void) -> SFSpeechRecognitionTask? {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            resultHandler(self.expectedResult, self.expectedError)
        }
        return SFSpeechRecognitionTask()
    }
}
