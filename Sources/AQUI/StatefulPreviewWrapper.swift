//
//  StatefulPreviewWrapper.swift
//  Do It
//
//  Created by Jim Dovey on 10/11/19.
//  Copyright © 2019 Jim Dovey. All rights reserved.
//

import SwiftUI

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    var body: some View {
        content($value)
    }

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}
