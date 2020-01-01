//
//  AudioProcessorServiceTests.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 27/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import AVFoundation
import Combine
import Speech
import XCTest
@testable import Videolitic

class AudioProcessorServiceTests: XCTestCase {

    var sut: AudioProcessorService!

    override func tearDown() {
        super.tearDown()
        // TODO: Clear temp directory
    }
    
    func testGivenURLIsValidThenResultsExists() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        expectation.expectedFulfillmentCount = 2
        let url = try URL(resource: "Bobrowiecka", extension: "m4a")
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedResult = MockSpeechRecognitionResult(bestTranscription: SFTranscription(), transcriptions: [], isFinal: true)
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut.recognizeSpeechPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail("Error \(String(describing: error))")
                case .finished:
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                // Then
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 5)
        publisher.cancel()
    }

    func testGivenURLIsValidThenWaitForFinalResult() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        let url = try URL(resource: "Bobrowiecka", extension: "m4a")
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedResult = MockSpeechRecognitionResult(bestTranscription: SFTranscription(), transcriptions: [], isFinal: false)
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut.recognizeSpeechPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    XCTFail()
                case .finished:
                    XCTFail()
                }
            }, receiveValue: { _ in
                XCTFail()
            })
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
        publisher.cancel()
    }
    
    func testGivenMP3IsNotValidThenErrorIsReturned() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        let url = try URL(resource: "Bobrowiecka", extension: "m4a")
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedError = UnitTestErrors.audioProcessor
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut.recognizeSpeechPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    // Then
                    expectation.fulfill()
                case .finished:
                    XCTFail()
                }
            }, receiveValue: { _ in
                XCTFail()
            })
        wait(for: [expectation], timeout: 5)
        publisher.cancel()
    }

    func testAudioPrpcessorIntergration() throws {
        let expectation = XCTestExpectation(description: name)
        let url = try URL(resource: "trump_clintoon", extension: "mov")
        let asset = AVAsset(url: url)
        let audioName = UUID().uuidString
        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(audioName).m4a")
        let speecjRecognizer = SpeechRecognizer(defaultTaskHint: .dictation)
        sut = AudioProcessorService(audioURL: audioURL, speechRecognizer: speecjRecognizer)
        let publisher = sut
            .convert(video: asset, toAudioNamed: audioName)
            .flatMap { _ in self.sut.recognizeSpeechPublisher }
            .sink(receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTFail("Error \(String(describing: error))")
                    case .finished:
                        expectation.fulfill()
                    }
                }, receiveValue: { result in
                    print("result = \(result)")
                    expectation.fulfill()
                })
            wait(for: [expectation], timeout: 360)
        publisher.cancel()
    }
}
