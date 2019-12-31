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

class AudioProcessorServiceTestsIntegration: XCTestCase {

    var sut: AudioProcessorService!
    
    func testWhenConvertingVideoThanItsSaved() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        expectation.expectedFulfillmentCount = 2
        let url = try URL(resource: "trump_clintoon", extension: "mov")
        let asset = AVAsset(url: url)
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedError = UnitTestErrors.audioProcessor
        let audioName = UUID().uuidString
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(audioName).m4a")
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut.convert(video: asset, toAudioNamed: audioName)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    XCTFail()
                    expectation.fulfill()
                case .finished:
                    expectation.fulfill()
                }
            }, receiveValue: { status in
                // Then
                let asset = AVAsset(url: destinationURL)
                XCTAssertTrue(asset.duration.value > 0)
                XCTAssertEqual(status, .completed)
                expectation.fulfill()
            })
        
        wait(for: [expectation], timeout: 5)
        publisher.cancel()
    }
    
    func testWhenConvertingNonExistingAssetThenStatusFailed() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        expectation.expectedFulfillmentCount = 2
        let url = FileManager.default.temporaryDirectory
        let asset = AVAsset(url: url)
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedError = UnitTestErrors.audioProcessor
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut.convert(video: asset, toAudioNamed: "DoNotExist")
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    XCTFail()
                    expectation.fulfill()
                case .finished:
                    expectation.fulfill()
                }
            }, receiveValue: { status in
                // Then
                XCTAssertEqual(status, .failed)
                expectation.fulfill()
            })
        
        wait(for: [expectation], timeout: 5)
        publisher.cancel()
    }
}
