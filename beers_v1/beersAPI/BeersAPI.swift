//
//  BeersAPI.swift
//  beers
//
//  Created by Marco Incerti on 01/03/23.
//  Copyright © 2023 Marco. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

func apiError(_ error: String) -> NSError {
    return NSError(domain: "BeersAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
}


enum BeersServiceError: Error {
    case offline
    case beersLimitReached
    case networkError
}

typealias SearchBeersResponse = Result<([Beer]), BeersServiceError>


class BeersSearchAPI {

    static let sharedAPI = BeersSearchAPI(reachabilityService: try! DefaultReachabilityService())

    private let _reachabilityService: ReachabilityService

    private init(reachabilityService: ReachabilityService) {
        _reachabilityService = reachabilityService
    }
}


extension BeersSearchAPI {
    public func loadSearchURL(_ searchURL: URL) -> Observable<SearchBeersResponse> {
        return URLSession.shared
            .rx.response(request: URLRequest(url: searchURL))
            .retry(3)
            .observe(on:Dependencies.sharedDependencies.backgroundWorkScheduler)
            .map { pair -> SearchBeersResponse in
                if pair.0.statusCode == 403 {
                    return .failure(.beersLimitReached)
                }
                
                let jsonRoot = try BeersSearchAPI.parseJSON(pair.0, data: pair.1)

                let beers = try Beer.parse(jsonRoot)
                
                //let nextURL = try BeersSearchAPI.parseNextURL(pair.0

                return .success((beers))
            }
            .retryOnBecomesReachable(.failure(.offline), reachabilityService: _reachabilityService)
    }
}


// MARK: Parsing the response

extension BeersSearchAPI {

    private static let parseLinksPattern = "\\s*,?\\s*<([^\\>]*)>\\s*;\\s*rel=\"([^\"]*)\""
    private static let linksRegex = try! NSRegularExpression(pattern: parseLinksPattern, options: [.allowCommentsAndWhitespace])


    private static func parseJSON(_ httpResponse: HTTPURLResponse, data: Data) throws -> AnyObject {
        if !(200 ..< 300 ~= httpResponse.statusCode) {
            throw exampleError("Call failed")
        }

        return try JSONSerialization.jsonObject(with: data, options: []) as AnyObject
    }
    
}

extension Beer {
    fileprivate static func parse(_ json: AnyObject) throws -> [Beer] {
        guard let items = json as? [AnyObject] else {
            throw exampleError("Can't find items")
        }
        return try items.map { item in
            guard let name = item["name"] as? String,
                  let tagline = item["tagline"] as? String,
                  let description = item["description"] as? String,
                  let id = item["id"] as? Int
            else {
                throw exampleError("Parsing error")
                
            }
            
            let image_url = item["image_url"] as? String?
            
            return Beer(id_beer: id, name: name, tagline: tagline, description: description, image_url: URL(string: (image_url ?? "https://images.punkapi.com/v2/192.png")!))
        }
    }
}

func exampleError(_ error: String, location: String = "\(#file):\(#line)") -> NSError {
    return NSError(domain: "ExampleError", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(location): \(error)"])
}
