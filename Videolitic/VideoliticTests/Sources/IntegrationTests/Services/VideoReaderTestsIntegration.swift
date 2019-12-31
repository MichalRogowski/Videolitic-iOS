//
//  VideoReaderTestsIntegration.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 30/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import AVFoundation
import Speech
import XCTest
@testable import Videolitic

class VideoReaderTestsIntegration: XCTestCase {
    
    var sut: VideoReader!
    var sut2: VideoProcessorService!
    func testGivenVideoIsUpOrientationIsUp() throws {
        // Given
        let url = try URL(resource: "trump_clintoon", extension: "mov")
        let asset = AVAsset(url: url)
        sut = try VideoReader(videoAsset: asset)
        
        // Then
        XCTAssertEqual(sut.orientation, .up)
    }
    
    func testGivenAssetIsAudioVideoReaderThrows() throws {
        // Given
        let url = try URL(resource: "Bobrowiecka", extension: "m4a")
        let asset = AVAsset(url: url)
        
        // Then
        do {
            sut = try VideoReader(videoAsset: asset)
            XCTFail()
        } catch {
            XCTAssertEqual((error as? VideoliticError)?.rawValue, VideoliticError.videoReader(.videoTrackDoesNotExist).rawValue)
        }
    }
    
    func testGivenAssetIsValidNextFrameIsValid() throws {
        // Given
        let url = try URL(resource: "trump_clintoon", extension: "mov")
        let asset = AVAsset(url: url)
        sut = try VideoReader(videoAsset: asset)
        
        // When
        let frame = sut.nextFrame()
        
        // Then
        XCTAssertNotNil(frame)
        XCTAssertTrue((frame?.timestamp ?? -1) >= Double(0))
        XCTAssertNotNil(frame?.pixelBuffer)
    }

    func testVideoProcessorIntegration() throws {
        let expectation = XCTestExpectation(description: name)
        let url = try URL(resource: "trump_clintoon", extension: "mov")
        let asset = AVAsset(url: url)
        let audioName = UUID().uuidString
        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(audioName).m4a")
        let videoReader = try VideoReader(videoAsset: asset)
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedResult = MockSpeechRecognitionResult(bestTranscription: SFTranscription(), transcriptions: [], isFinal: true)

        let audioProcessor = AudioProcessorService(audioURL: audioURL, speechRecognizer: speechRecognizer)
        
        sut2 = try VideoProcessorService(audioProcessor: audioProcessor, videoReader: videoReader)

        let cancelable = sut2
            .prepareTracking(for: asset, toAudioNamed: audioName)
            .flatMap { _ in self.sut2.startTracking() }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("completion = \(completion)")
            }) { transcription, participiants in
                print("transc = \(transcription)")
                print("participiants = \(participiants)")
                expectation.fulfill()
            }
        
        wait(for: [expectation], timeout: 120)
        cancelable.cancel()
    }
}
