//
//  MockSpeechRecognizer.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 29/11/2019.
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

import Combine
import Speech
@testable import Videolitic

final class MockSpeechRecognizer: SpeechRecognizerInterface {
    // MARK: Public properties

    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus { expectedStatus }

    var expectedStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var expectedAuthorizationRequestResult: SFSpeechRecognizerAuthorizationStatus = .restricted
    var expectedResult: SpeechRecognitionResultInterface?
    var expectedError: Error?

    var defaultTaskHint: SFSpeechRecognitionTaskHint = .dictation

    // MARK: Public functions

    func recognitionTask(with url: URL, resultHandler: @escaping (SpeechRecognitionResultInterface?, Error?) -> Void) -> SFSpeechRecognitionTask? {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            resultHandler(self.expectedResult, self.expectedError)
        }
        return SFSpeechRecognitionTask()
    }

    func requestAuthorization() -> Future<SFSpeechRecognizerAuthorizationStatus, Error> {
        Future<SFSpeechRecognizerAuthorizationStatus, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                promise(.success(self.expectedAuthorizationRequestResult))
            }
        }
    }
}
