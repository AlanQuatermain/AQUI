//
//  File.swift
//  
//
//  Created by Jim Dovey on 11/25/19.
//

import UIKit
import SwiftUI
import Combine

#if os(iOS) || targetEnvironment(macCatalyst)
fileprivate func rootController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap {
        $0 as? UIWindowScene
    }

    guard !scenes.isEmpty else { return nil }
    for scene in scenes {
        guard let root = scene.windows.first?.rootViewController else {
            continue
        }
        return root
    }
    return nil
}

fileprivate struct _SpecialSheetPseudoView<SheetContent: View, ViewContent: View>: View {
    @Binding var isPresented: Bool
    @Boxed private var presentedController: UIHostingController<SheetContent>? = nil
    var style: UIModalPresentationStyle
    var sheet: () -> SheetContent
    var content: ViewContent

    var body: some View {
        if isPresented {
            presentSheet()
        }
        else {
            dismissSheet()
        }

        return content
    }

    func presentSheet() {
        guard presentedController == nil else { return }
        guard let controller = rootController() else { return }

        let presented = UIHostingController(rootView: sheet())
        self.presentedController = presented
        controller.present(presented, animated: true, completion: nil)
    }

    func dismissSheet() {
        guard let controller = presentedController else { return }
        presentedController = nil
        controller.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 13.0, tvOS 13.0, *)
@available(OSX, unavailable)
@available(watchOS, unavailable)
extension View {
    public func sheet<Content: View>(
        isPresented: Binding<Bool>,
        style: UIModalPresentationStyle,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        _SpecialSheetPseudoView(isPresented: isPresented, style: style,
                                sheet: content, content: self)
    }
}
#endif
