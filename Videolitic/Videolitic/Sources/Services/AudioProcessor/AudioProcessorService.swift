//
//  AudioProcessorService.swift
//  Videolitic
//
//  Created by Michał Rogowski on 17/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import AVFoundation
import Combine
import Speech

/// `AudioProcessorService` interface to process audio at specific URL
protocol AudioProcessorServiceInterface {

    var recognizeSpeechPublisher: Future<[SFTranscriptionSegment], Error> { get }

    func authorizeIfNeeded() -> Future<SFSpeechRecognizerAuthorizationStatus, Error>
    func convert(video asset: AVAsset, toAudioNamed name: String) -> Future<AVAssetExportSession.Status, Error>
}

/// Service to process audio at specific URL
final class AudioProcessorService: AudioProcessorServiceInterface {

    // MARK: Public properties

    /// Publisher that recognise text from requested URL
    var recognizeSpeechPublisher: Future<[SFTranscriptionSegment], Error> {
        return Future<[SFTranscriptionSegment], Error> { [weak self] promise in
            guard let self = self else {
                return
            }
            self.speechRecognizer.recognitionTask(with: self.audioURL, resultHandler: { recognitionResult, error in
                guard recognitionResult?.isFinal == true else {
                    guard let error = error else {
                        return
                    }
                    promise(.failure(error))
                    return
                }
                promise(.success(recognitionResult?.bestTranscription.segments ?? []))
            })
        }
    }

    // MARK: Private properties

    private let audioURL: URL
    private let speechRecognizer: SpeechRecognizerInterface

    // MARK: Initialisation

    init(audioURL: URL, speechRecognizer: SpeechRecognizerInterface) {
        self.audioURL = audioURL
        self.speechRecognizer = speechRecognizer
    }

    // MARK: Public functions

    func authorizeIfNeeded() -> Future<SFSpeechRecognizerAuthorizationStatus, Error> {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        guard currentStatus == .notDetermined else {
            return Future<SFSpeechRecognizerAuthorizationStatus, Error> { $0(.success(currentStatus)) }
        }
        return Future<SFSpeechRecognizerAuthorizationStatus, Error> { promise in
            SFSpeechRecognizer.requestAuthorization { status in
                promise(.success(status))
            }
        }
    }

    func convert(video asset: AVAsset, toAudioNamed name: String) -> Future<AVAssetExportSession.Status, Error> {
        do {
            let audio = try convertToAudio(fromVideo: asset)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).m4a")
            return save(audio: audio, toUrl: url)
        } catch {
            return Future<AVAssetExportSession.Status, Error> { $0(.failure(error)) }
        }
    }

    // MARK: Private functions

    private func convertToAudio(fromVideo asset: AVAsset) throws -> AVAsset {

        let composition = AVMutableComposition()
        let audioTracks = asset.tracks(withMediaType: .audio)

        for track in audioTracks {
            let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            compositionTrack?.preferredTransform = track.preferredTransform
        }
        return composition
    }

    private func save(audio asset: AVAsset, toUrl url: URL) -> Future<AVAssetExportSession.Status, Error> {

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            return Future<AVAssetExportSession.Status, Error> {
                $0(.failure(VideoliticError.audioProcessorService(.cannotCrateExportSession)))
            }
        }

        exportSession.outputFileType = .m4a
        exportSession.outputURL = url

        return Future<AVAssetExportSession.Status, Error> { promise in
            exportSession.exportAsynchronously {
                promise(.success(exportSession.status))
            }
        }
    }
}
