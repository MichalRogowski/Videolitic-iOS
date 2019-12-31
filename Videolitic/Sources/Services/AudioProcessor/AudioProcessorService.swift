//
//  AudioProcessorService.swift
//  Videolitic
//
//  Created by Michał Rogowski on 17/11/2019.
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
        let currentStatus = speechRecognizer.authorizationStatus
        guard currentStatus == .notDetermined else {
            return Future<SFSpeechRecognizerAuthorizationStatus, Error> { $0(.success(currentStatus)) }
        }
        return speechRecognizer.requestAuthorization()
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
