//
//  VideoliticService.swift
//  Videolitic
//
//  Created by Michał Rogowski on 06/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import AVFoundation
import Combine
import Speech

public protocol VideoliticServiceInterface: class {

    static func compute(video asset: AVAsset) throws -> (result: AnyPublisher<VideoProcessingResult, Error>, currentFrame: Published<VideoProcessingResult.Frame?>.Publisher)
}

public class VideoliticService: VideoliticServiceInterface {

    // MARK: Initialisation

    public init() { }

    // MARK: Public functions

    public static func compute(video asset: AVAsset) throws -> (result: AnyPublisher<VideoProcessingResult, Error>, currentFrame: Published<VideoProcessingResult.Frame?>.Publisher) {
        let url = (asset as? AVURLAsset)?.url
        let audioName = UUID().uuidString
        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(audioName).m4a")
        let videoReader = try VideoReader(videoAsset: asset)
        let speechRecognizer = SpeechRecognizer(defaultTaskHint: .dictation)
        let audioProcessor = AudioProcessorService(audioURL: audioURL, speechRecognizer: speechRecognizer)
        let faceComputingService = try FaceComputingService()
        let videoProcessor = try VideoProcessorService(audioProcessor: audioProcessor, faceComputingService: faceComputingService, videoReader: videoReader)

        return (audioProcessor
            .authorizeIfNeeded()
            .flatMap { status -> AnyPublisher<AVAssetExportSession.Status, Error> in
                if status == .authorized {
                    return audioProcessor.convert(video: asset, toAudioNamed: audioName).eraseToAnyPublisher()
                } else {
                    return Fail(error: VideoliticError.audioProcessorService(.notAuthorized)).eraseToAnyPublisher()
                }
            }
            .flatMap { status -> AnyPublisher<([SFTranscriptionSegment], [Participant]), Error> in
                if status == .failed {
                    return Fail(error: VideoliticError.audioProcessorService(.cannotCrateExportSession)).eraseToAnyPublisher()
                } else if status == .completed {
                    return videoProcessor.startTracking().eraseToAnyPublisher()
                } else {
                    return Fail(error: VideoliticError.audioProcessorService(.exportSessionWasCancelled)).eraseToAnyPublisher()
                }
            }
            .map { transcription, participants in
                VideoProcessingResult(audioURL: audioURL, orientation: videoReader.orientation, participants: participants, transcriptionSegments: transcription, videoURL: url)
            }
        .eraseToAnyPublisher(), videoProcessor.framePublisher)
    }
}
