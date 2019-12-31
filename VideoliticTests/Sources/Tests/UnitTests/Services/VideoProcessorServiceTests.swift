//
//  VideoProcessorServiceTests.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 03/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import AVFoundation
import Combine
import Speech
import Vision
import XCTest
@testable import Videolitic

class VideoProcessorServiceTests: XCTestCase {

    var sut: VideoProcessorService!

    func testGivenDidNotStartTrackingThenFrameIsNil() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        let mockAudioProcessorService = MockAudioProcessorService()
        let mockVideoReader = MockVideoReader()
        let mockFaceComputing = MockFaceComputingService()
        sut = try VideoProcessorService(audioProcessor: mockAudioProcessorService, faceComputingService: mockFaceComputing, videoReader: mockVideoReader)

        // Then
        let cancellable = sut.framePublisher
            .sink { frame in
                XCTAssertNil(frame)
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 5)
        cancellable.cancel()
    }

    func testGivenStartedTrackingThenFrameExists() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        let mockAudioProcessorService = MockAudioProcessorService()
        let mockVideoReader = MockVideoReader()
        let mockFaceComputing = MockFaceComputingService()
        let image = mockVideoReader.imageFrom(color: .red, width: 100, height: 100)
        let pixelBuffer = mockVideoReader.pixelBufferFrom(image: image)
        mockVideoReader.expectedFrame = VideoProcessingResult.Frame(pixelBuffer: pixelBuffer, timestamp: 0)
        sut = try VideoProcessorService(audioProcessor: mockAudioProcessorService, faceComputingService: mockFaceComputing, videoReader: mockVideoReader)

        // When
        _ = self.sut.startTracking()

        // Then
        let cancellable = sut.framePublisher
            .sink { frame in
                XCTAssertNotNil(frame)
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 5)
        cancellable.cancel()
    }

    func testGivenNextFrameIsNilCantStartTracking() throws {
        // Given
        let expectation = XCTestExpectation(description: name)
        let mockAudioProcessorService = MockAudioProcessorService()
        let mockVideoReader = MockVideoReader()
        let mockFaceComputing = MockFaceComputingService()
        sut = try VideoProcessorService(audioProcessor: mockAudioProcessorService, faceComputingService: mockFaceComputing, videoReader: mockVideoReader)

        // When
        mockVideoReader.expectedFrame = nil

        // Then
        let cancellable = self.sut
            .startTracking()
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTAssertEqual("firstFrameReadFailed", (error as? VideoliticError)?.rawValue)
                    expectation.fulfill()
                case .finished:
                    XCTFail()
                }
            }, receiveValue: { _ in })

        wait(for: [expectation], timeout: 5)
        cancellable.cancel()
    }

    func testGivenIsTrackingWhenStopThenFailure() throws {
       // Given
        let expectation = XCTestExpectation(description: name)

        let mockAudioProcessorService = MockAudioProcessorService()
        mockAudioProcessorService.expectedRecognizedSpeech = ([], nil)
        let mockVideoReader = MockVideoReader()
        let mockFaceComputing = MockFaceComputingService()
        let image = mockVideoReader.imageFrom(color: .red, width: 100, height: 100)
        let pixelBuffer = mockVideoReader.pixelBufferFrom(image: image)
        mockVideoReader.expectedFrame = VideoProcessingResult.Frame(pixelBuffer: pixelBuffer, timestamp: 0)
        sut = try VideoProcessorService(audioProcessor: mockAudioProcessorService, faceComputingService: mockFaceComputing, videoReader: mockVideoReader)

        // When
        let publisher = sut
            .startTracking()
        sut.stopTracking()

        // Then
        let cancellable = publisher
            .sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                XCTAssertEqual("detectingCancelled", (error as? VideoliticError)?.rawValue)
                expectation.fulfill()
            case .finished:
                XCTFail()
            }
        }, receiveValue: { _ in })

        wait(for: [expectation], timeout: 1)
        cancellable.cancel()
    }

    func testGivenIsTrackingThenReturnExpectedTransription() throws {
       // Given
        let expectation = XCTestExpectation(description: name)

        let mockAudioProcessorService = MockAudioProcessorService()
        let segments = [SFTranscriptionSegment(), SFTranscriptionSegment()]
        let mockVideoReader = MockVideoReader()
        let image = mockVideoReader.imageFrom(color: .red, width: 100, height: 100)
        let pixelBuffer = mockVideoReader.pixelBufferFrom(image: image)
        mockVideoReader.expectedFrame = VideoProcessingResult.Frame(pixelBuffer: pixelBuffer, timestamp: 0)
        let mockFaceComputing = MockFaceComputingService()
        let face = (image: image.cgImage!, observation: VNFaceObservation(boundingBox: .zero))
        let detectionResult = (Participant(), face)
        mockFaceComputing.expectedFaceDetectionResult = ([detectionResult], nil)
        sut = try VideoProcessorService(audioProcessor: mockAudioProcessorService, faceComputingService: mockFaceComputing, videoReader: mockVideoReader)

        // When
        mockAudioProcessorService.expectedRecognizedSpeech = (segments, nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            _ = self.sut
                .framePublisher
                .sink { frame in
                    if frame != nil {
                        mockVideoReader.expectedFrame = nil
                    }
                }
        }
        // Then
        let cancellable = sut
            .startTracking()
            .sink(receiveCompletion: { completion in
            switch completion {
            case .failure:
                XCTFail()
            case .finished:
                expectation.fulfill()
            }
        }, receiveValue: { result in
            XCTAssertEqual(detectionResult.0.uuid, result.1.first?.uuid)
            XCTAssertEqual(result.0, segments)
        })

        wait(for: [expectation], timeout: 1)
        cancellable.cancel()
    }
}
