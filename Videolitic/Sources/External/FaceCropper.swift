//  Copyright (c) 2017 TAEJUN KIM <korean.darren@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

// Modified by Michał Rogowski on 29/11/2019.

import UIKit
import Vision

enum FaceCropResult<T> {
  case success([(T, VNFaceObservation)], VNRequest)
  case notFound(VNRequest)
  case failure(Error)
}

struct FaceCropper<T> {
  let detectable: T
  init(_ detectable: T) {
    self.detectable = detectable
  }
}

protocol FaceCroppable {
}

extension FaceCroppable {
  var face: FaceCropper<Self> {
    return FaceCropper(self)
  }
}

extension FaceCropper where T: CGImage {
    func crop(_ completion: @escaping (FaceCropResult<CGImage>) -> Void) -> VNDetectFaceRectanglesRequest {
        let req = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let faceImages = request.results?.map({ result -> FaceComputingService.Face? in
                guard let face = result as? VNFaceObservation else {
                    return nil
                }

                let width = face.boundingBox.width * CGFloat(self.detectable.width)
                let height = face.boundingBox.height * CGFloat(self.detectable.height)
                let x = face.boundingBox.origin.x * CGFloat(self.detectable.width)
                let y = (1 - face.boundingBox.origin.y) * CGFloat(self.detectable.height) - height

                let croppingRect = CGRect(x: x, y: y, width: width, height: height)
                guard let faceImage = self.detectable.cropping(to: croppingRect) else {
                    return nil
                }

                return (faceImage, face)
            })
            .compactMap { $0 }

            guard let result = faceImages, !result.isEmpty else {
                completion(.notFound(request))
                return
            }

            completion(.success(result, request))
        }
        return req
    }
}

extension NSObject: FaceCroppable {}
extension CGImage: FaceCroppable {}
