//
//  MockFaceComputingService.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 03/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import Combine
import UIKit
import Vision
@testable import Videolitic

final class MockFaceComputingService: FaceComputingServiceInterface {

    var expectedFaceDetectionResult: (result: [(Participant, FaceComputingService.Face)]?, error: Error?) = (nil, nil)

    func detectFacesAndCreateTrackers(for frame: VideoProcessingResult.Frame, participants: [Participant], handler: VNSequenceRequestHandler, trackObservation: VNDetectedObjectObservation?, timestamp: TimeInterval, orientation: CGImagePropertyOrientation) -> Future<[(Participant, FaceComputingService.Face)], Error> {

        Future<[(Participant, FaceComputingService.Face)], Error> { promise in
            if let result = self.expectedFaceDetectionResult.result {
                promise(.success(result))
            } else if let error = self.expectedFaceDetectionResult.error {
                promise(.failure(error))
            } else {
                promise(.failure(UnitTestErrors.faceComputing(.noFacesResult)))
            }
        }
    }
}
