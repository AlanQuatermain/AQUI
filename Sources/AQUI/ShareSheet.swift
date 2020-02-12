//
//  ShareSheet.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

/// Presents an activity view controller (“share sheet”) on iOS devices.
///
/// This is currently intended for use via the `.sheet()` modifier on `View` types.
@available(iOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct ShareSheet: UIViewControllerRepresentable {

    public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, excludedActivityTypes: [UIActivity.ActivityType]? = nil, callback: Callback? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
        self.callback = callback
    }
    
    public typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    let excludedActivityTypes: [UIActivity.ActivityType]?
    let callback: Callback?
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
}
#endif
