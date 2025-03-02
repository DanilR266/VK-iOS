//
//  ReviewPhotoRequest.swift
//  Test
//
//  Created by Данила on 02.03.2025.
//

import Foundation
import UIKit

final class ReviewPhotoRequest {
    
    static let shared = ReviewPhotoRequest()
    
}

extension ReviewPhotoRequest {
    
    typealias GetReviewPhotoResult = Result<Data, GetReviewsError>

    enum GetReviewsError: Error {

        case badURL
        case badData(Error)

    }

    func getReviewPhoto(from urlString: String, completion: @escaping (GetReviewPhotoResult) -> Void) {
        guard let url = URL(string: urlString) else {
            return completion(.failure(.badURL))
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.badData(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badURL))
                return
            }

            completion(.success(data))
        }
        
        task.resume()
    }
}
