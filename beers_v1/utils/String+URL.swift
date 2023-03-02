//
//  String+URL.swift
//  beers_v1
//
//  Created by Marco Incerti on 01/03/23.
//

extension String {
    var URLEscaped: String {
       return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }
}

