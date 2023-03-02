//
//  Version.swift
//  beers_v1
//
//  Created by Marco Incerti on 01/03/23.
//

import Foundation

class Unique: NSObject {
}

struct Version<Value>: Hashable {

    private let _unique: Unique
    let value: Value

    init(_ value: Value) {
        self._unique = Unique()
        self.value = value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self._unique)
    }

    static func == (lhs: Version<Value>, rhs: Version<Value>) -> Bool {
        lhs._unique === rhs._unique
    }
}

extension Version {
    func mutate(transform: (inout Value) -> Void) -> Version<Value> {
        var newSelf = self.value
        transform(&newSelf)
        return Version(newSelf)
    }

    func mutate(transform: (inout Value) throws -> Void) rethrows -> Version<Value> {
        var newSelf = self.value
        try transform(&newSelf)
        return Version(newSelf)
    }
}

