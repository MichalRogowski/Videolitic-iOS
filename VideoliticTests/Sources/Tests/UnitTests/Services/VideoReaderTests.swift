//
//  VideoReaderTestsIntegration.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 30/11/2019.
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
import Speech
import XCTest
@testable import Videolitic

class VideoReaderTests: XCTestCase {
    
    var sut: VideoReader!

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
        let url = try URL(resource: "TestRecording", extension: "m4a")
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
}
