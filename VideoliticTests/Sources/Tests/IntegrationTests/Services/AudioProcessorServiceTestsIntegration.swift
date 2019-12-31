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

class AudioProcessorServiceTestsIntegration: XCTestCase {

    var sut: AudioProcessorService!
    
    func testGivenVideoWhenConvertingToAudioThanItsSaved() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        expectation.expectedFulfillmentCount = 2
        let url = try URL(resource: "trump_clintoon", extension: "mov")
        let asset = AVAsset(url: url)
        let speechRecognizer = SpeechRecognizer(defaultTaskHint: .dictation)
        let audioName = UUID().uuidString
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(audioName).m4a")
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut
            .convert(video: asset, toAudioNamed: audioName)
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
        let speechRecognizer = SpeechRecognizer(defaultTaskHint: .dictation)
        sut = AudioProcessorService(audioURL: url, speechRecognizer: speechRecognizer)
        // When
        let publisher = sut
            .convert(video: asset, toAudioNamed: "DoNotExist")
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
