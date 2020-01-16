//
//  OptionalBinding.swift
//  AQUI
//
//  Created by Jim Dovey on 11/13/19.
//

import SwiftUI

public extension Binding {
    /// Given a binding to an optional value, creates a non-optional binding that projects
    /// the unwrapped value. If the given optional binding contains `nil`, then the supplied
    /// value is assigned to it before the projected binding is generated.
    ///
    /// This allows for one-line use of optional bindings, which is very useful for CoreData types
    /// which are non-optional in the model schema but which are still declared nullable and may
    /// be nil at runtime before an initial value has been set.
    ///
    ///     class Thing: NSManagedObject {
    ///         @NSManaged var name: String?
    ///     }
    ///     struct MyView: View {
    ///         @State var thing = Thing(name: "Bob")
    ///         var body: some View {
    ///             TextField("Name", text: Binding($thing.name, ""))
    ///         }
    ///     }
    ///
    /// - note: From experimentation, it seems that a binding created from an `@State` variable
    /// is not immediately 'writable'. There is seemingly some work done by SwiftUI following the render pass
    /// to make newly-created or assigned bindings modifiable, so simply assigning to
    /// `source.wrappedValue` inside `init` is not likely to have any effect. The implementation
    /// has been designed to work around this (we don't assume that we can unsafely-unwrap even after
    /// assigning a non-`nil` value), but a side-effect is that if the binding is never written to outside of
    /// the getter, then there is no guarantee that the underlying value will become non-`nil`.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    init(_ source: Binding<Value?>, _ defaultValue: Value) {
        self.init(get: {
            // ensure the source doesn't contain nil
            if source.wrappedValue == nil {
                // try to assign--this may not initially work, since it seems
                // SwiftUI needs to wire things up inside Bindings before they
                // become properly 'writable'.
                source.wrappedValue = defaultValue
            }
            return source.wrappedValue ?? defaultValue
        }, set: {
            source.wrappedValue = $0
        })
    }

    /// Creates a binding that projects the result of `source.wrappedValue == nil`. Additionally
    /// takes a default value: this will be used to set the underlying binding's value when this binding's
    /// wrapped value is set to `true`.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    init<T>(isNotNil source: Binding<T?>, defaultValue: T) where Value == Bool {
        self.init(get: { source.wrappedValue != nil },
                  set: { source.wrappedValue = $0 ? defaultValue : nil })
    }
}

public extension Binding where Value: Equatable {
    /// Creates a non-nil binding by projecting to its unwrapped value, translating nil values
    /// to or from the given nil value. If the source contains nil, this binding will return the
    /// nil value. If this binding is set to the given nil value, it will assign nil to the underlying
    /// source binding.
    ///
    /// This is useful if you have optional values of a type that has a logical 'empty' value of
    /// its own, for example `String`:
    ///
    ///     @State var name: String?
    ///     ...
    ///     TextField(text: Binding($name, replacingWithNil: ""))
    ///
    /// If the `name` property contains `nil`, the text field will see an empty string. If the text field
    /// assigns an empty string, the `name` property will be set to `nil`.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    init(_ source: Binding<Value?>, replacingNilWith nilValue: Value) {
        self.init(
            get: { source.wrappedValue ?? nilValue },
            set: { newValue in
                if newValue == nilValue {
                    source.wrappedValue = nil
                }
                else {
                    source.wrappedValue = newValue
                }
        })
    }
}
