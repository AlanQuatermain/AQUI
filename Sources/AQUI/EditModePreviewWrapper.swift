//
//  EditModePreviewWrapper.swift
//  
//
//  Created by Jim Dovey on 11/15/19.
//

import SwiftUI

@available(iOS 13.0, tvOS 13.0, *)
@available(OSX, unavailable)
@available(watchOS, unavailable)
public struct EditModePreviewWrapper<Content: View>: View {
    @State var editMode: EditMode = .inactive
    var content: Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    public var body: some View {
        // Can't access @State outside of render loop (e.g. in preview creation)
        content.environment(\.editMode, $editMode)
    }
}
