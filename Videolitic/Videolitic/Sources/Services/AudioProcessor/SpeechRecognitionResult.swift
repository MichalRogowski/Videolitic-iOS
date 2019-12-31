//
//  SpeechRecognitionResultInterface.swift
//  Videolitic
//
//  Created by Michał Rogowski on 29/11/2019.
//  Copyright © 2019 Michał Rogowski. All rightsreserved.
//

import Speech

protocol SpeechRecognitionResultInterface {

    var bestTranscription: SFTranscription { get }

    var transcriptions: [SFTranscription] { get }

    var isFinal: Bool { get }
}

struct SpeechRecognitionResult: SpeechRecognitionResultInterface {

    let bestTranscription: SFTranscription
    let transcriptions: [SFTranscription]
    let isFinal: Bool
}

extension SpeechRecognitionResult {

    init(sfSpeechRecognitionResult: SFSpeechRecognitionResult) {
        self.bestTranscription = sfSpeechRecognitionResult.bestTranscription
        self.transcriptions = sfSpeechRecognitionResult.transcriptions
        self.isFinal = sfSpeechRecognitionResult.isFinal
    }
}
