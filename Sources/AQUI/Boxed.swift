//
//  File.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

/// A property wrapper that manages persistent storage shared by copies of
/// a value type, similar to the content of a SwiftUI Struct.
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
class Boxed<Value> {
    var wrappedValue: Value
    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
