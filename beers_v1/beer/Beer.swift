//
//  BeerModel.swift
//  beers
//
//  Created by Marco Incerti on 01/03/23.
//  Copyright © 2023 Marco. All rights reserved.
//

import Foundation


struct Beer{
    var id = UUID()
    let id_beer: Int
    let name: String
    let tagline: String
    let description: String
    let image_url: URL?
    
    
    static func parseJSON(_ json: NSDictionary) throws -> Beer {
        guard
            let parse = json.value(forKey: "parse"),
            let id_beer = (parse as AnyObject).value(forKey: "id") as? Int,
            let name = (parse as AnyObject).value(forKey: "name") as? String,
            let tagline = (parse as AnyObject).value(forKey: "tagline") as? String,
            let description = (parse as AnyObject).value(forKey: "description") as? String,
            let image_url = (parse as AnyObject).value(forKey: "image_url") as? URL
        else {
                throw apiError("Error parsing page content")
            }
                
        return Beer(id_beer: id_beer, name: name, tagline: tagline, description: description, image_url: image_url)
    }
}
