//
//  File.swift
//  
//
//  Created by Jim Dovey on 11/25/19.
//

/// A form of box that doesn't incur ARC overhead for structures.
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
struct SharedStorage<Value> {
    private let _storage: UnsafeMutablePointer<Value>

    init(wrappedValue: Value) {
        _storage = UnsafeMutablePointer.allocate(capacity: 1)
        _storage.pointee = wrappedValue
    }

    var wrappedValue: Value {
        get { _storage.pointee }
        nonmutating set { _storage.pointee = newValue }
    }
}
