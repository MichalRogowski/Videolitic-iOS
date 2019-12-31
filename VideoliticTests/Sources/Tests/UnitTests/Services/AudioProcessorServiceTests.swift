//
//  AudioProcessorServiceTests.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 27/11/2019.
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
        let url = try URL(resource: "TestRecording", extension: "m4a")
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedResult = MockSpeechRecognitionResult(bestTranscription: SFTranscription(), transcriptions: [], isFinal: true)
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut
            .recognizeSpeechPublisher
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
        let url = try URL(resource: "TestRecording", extension: "m4a")
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedResult = MockSpeechRecognitionResult(bestTranscription: SFTranscription(), transcriptions: [], isFinal: false)
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut
            .recognizeSpeechPublisher
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
        let url = try URL(resource: "TestRecording", extension: "m4a")
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedError = UnitTestErrors.audioProcessor(.general)
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut
            .recognizeSpeechPublisher
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

    func testGivenStatusNotDetermendAskToAuthorize() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        let url = try URL(resource: "TestRecording", extension: "m4a")
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedStatus = .notDetermined
        speechRecognizer.expectedAuthorizationRequestResult = .authorized
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut
            .authorizeIfNeeded()
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail("Error \(String(describing: error))")
                case .finished:
                    // Then
                    expectation.fulfill()
                }
            }, receiveValue: { result in
                XCTAssertEqual(result, .authorized)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 5)
        publisher.cancel()
    }

    func testGivenStatusDetermendReturnExpectedStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        let url = try URL(resource: "TestRecording", extension: "m4a")
        let speechRecognizer = MockSpeechRecognizer()
        speechRecognizer.expectedStatus = .authorized
        speechRecognizer.expectedAuthorizationRequestResult = .denied
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut
            .authorizeIfNeeded()
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail("Error \(String(describing: error))")
                case .finished:
                    // Then
                    expectation.fulfill()
                }
            }, receiveValue: { result in
                XCTAssertEqual(result, .authorized)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 5)
        publisher.cancel()
    }
}
