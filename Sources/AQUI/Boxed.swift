//
//  File.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

/// A property wrapper that manages persistent storage shared by copies of
/// a value type, similar to the content of a SwiftUI Struct.
@propertyWrapper
class Boxed<Value> {
    var wrappedValue: Value
    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
