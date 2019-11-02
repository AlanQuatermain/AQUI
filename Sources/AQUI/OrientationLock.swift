//
//  OrientationLock.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

import SwiftUI

#if os(iOS) || targetEnvironment(macCatalyst)
struct SupportedOrientationsPreferenceKey: PreferenceKey {
    typealias Value = UIInterfaceOrientationMask
    static var defaultValue: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        else {
            return .allButUpsideDown
        }
    }
    
    public static func reduce(value: inout UIInterfaceOrientationMask, nextValue: () -> UIInterfaceOrientationMask) {
        // use the most restrictive set from the stack
        value.formIntersection(nextValue())
    }
}

/// Use this in place of `UIHostingController` in your app's `SceneDelegate`.
///
/// Supported interface orientations come from the root of the view hierarchy.
public class OrientationLockedController<Content: View>: UIHostingController<OrientationLockedController._Root<Content>> {
    fileprivate class Box {
        var supportedOrientations: UIInterfaceOrientationMask
        init() {
            self.supportedOrientations =
                UIDevice.current.userInterfaceIdiom == .pad
                ? .all
                : .allButUpsideDown
        }
    }
    
    private var orientations: Box!
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        orientations.supportedOrientations
    }

    /// Initializes a new orientation-lockable `UIHostingController` with the given root view.
    public init(rootView: Content) {
        let box = Box()
        let orientationRoot = _Root(contentView: rootView, box: box)
        self.orientations = box
        super.init(rootView: orientationRoot)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public struct _Root<Content: View>: View {
        private let contentView: Content
        private let box: Box

        fileprivate init(contentView: Content, box: Box) {
            self.contentView = contentView
            self.box = box
        }

        public var body: some View {
            /// Attach a listener to the content view that will pass any changed orientation values
            /// up to the controller, ready to be reported to the application.
            contentView
                .onPreferenceChange(SupportedOrientationsPreferenceKey.self) { value in
                    // Update the binding to set the value on the root controller.
                    self.box.supportedOrientations = value
            }
        }
    }
}

extension View {
    /// Specify the orientations supported by this view.
    ///
    /// This affects the view hierarchy above the affected view. If you add a new subview that
    /// can only appear in landscape-left or portrait, and also add a view that can only appear in
    /// any landscape orientation, then the application will be locked to only landscape by combining
    /// all the supported orientations for all views in the hierarchy.
    @available(iOS 13.0, *)
    @available(OSX, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func supportedOrientations(_ supportedOrientations: UIInterfaceOrientationMask) -> some View {
        // When rendered, export the requested orientations upward to Root
        preference(key: SupportedOrientationsPreferenceKey.self, value: supportedOrientations)
    }
}
#endif
