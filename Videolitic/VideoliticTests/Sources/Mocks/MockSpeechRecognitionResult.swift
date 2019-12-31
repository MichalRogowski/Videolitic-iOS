//
//  MockSpeechRecognitionResult.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 29/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import Speech
@testable import Videolitic

struct MockSpeechRecognitionResult: SpeechRecognitionResultInterface {

    // MARK: Public properties

    let bestTranscription: SFTranscription
    let transcriptions: [SFTranscription]
    let isFinal: Bool
}
