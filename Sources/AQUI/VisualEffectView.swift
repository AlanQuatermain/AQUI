//
//  File.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

import SwiftUI

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct VisualEffectKey: EnvironmentKey {
    typealias Value = VisualEffect?
    static var defaultValue: Value = nil
}
  
extension EnvironmentValues {
    public var visualEffect: VisualEffect? {
        get { self[VisualEffectKey.self] }
        set { self[VisualEffectKey.self] = newValue }
    }
}

struct VisualEffectPreferenceKey: PreferenceKey {
    typealias Value = VisualEffect?
    static var defaultValue: VisualEffect? = nil
    
    static func reduce(value: inout VisualEffect?, nextValue: () -> VisualEffect?) {
        // use the lowest value only
        // would be nice to have these things be combinable, though.
        guard value == nil else { return }
        value = nextValue()
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
@available(watchOS, unavailable)
public enum VisualEffect {
    // Standard system materials for iOS-based platforms
    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemUltraThinMaterial

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemThinMaterial

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
    case systemMaterial

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemThickMaterial

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemChromeMaterial

    
    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemUltraThinMaterialLight

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemThinMaterialLight

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemMaterialLight

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemThickMaterialLight

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemChromeMaterialLight

    
    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemUltraThinMaterialDark

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemThinMaterialDark

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemMaterialDark

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemThickMaterialDark

    @available(iOS 13.0, tvOS 13.0, *)
    @available(OSX, unavailable)
    case systemChromeMaterialDark
    
    // Values specific to macOS
    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case menu
    
    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case popover

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case sidebar

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case headerView

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case sheet

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case windowBackground

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case hudWindow

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case fullScreenUI

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case toolTip

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case contentBackground

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case underWindowBackground

    @available(OSX 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    case underPageBackground
    
    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Vends an appropriate `UIVisualEffect`.
    var parameters: UIVisualEffect {
        switch self {
        case .systemUltraThinMaterial:
            return UIBlurEffect(style: .systemUltraThinMaterial)
        case .systemThinMaterial:
            return UIBlurEffect(style: .systemThinMaterial)
        case .systemMaterial:
            return UIBlurEffect(style: .systemMaterial)
        case .systemThickMaterial:
            return UIBlurEffect(style: .systemThickMaterial)
        case .systemChromeMaterial:
            return UIBlurEffect(style: .systemChromeMaterial)
        case .systemUltraThinMaterialLight:
            return UIBlurEffect(style: .systemUltraThinMaterialLight)
        case .systemThinMaterialLight:
            return UIBlurEffect(style: .systemThinMaterialLight)
        case .systemMaterialLight:
            return UIBlurEffect(style: .systemMaterialLight)
        case .systemThickMaterialLight:
            return UIBlurEffect(style: .systemThickMaterialLight)
        case .systemChromeMaterialLight:
            return UIBlurEffect(style: .systemChromeMaterialLight)
        case .systemUltraThinMaterialDark:
            return UIBlurEffect(style: .systemUltraThinMaterialDark)
        case .systemThinMaterialDark:
            return UIBlurEffect(style: .systemThinMaterialDark)
        case .systemMaterialDark:
            return UIBlurEffect(style: .systemMaterialDark)
        case .systemThickMaterialDark:
            return UIBlurEffect(style: .systemThickMaterialDark)
        case .systemChromeMaterialDark:
            return UIBlurEffect(style: .systemChromeMaterialDark)
        }
    }
    #elseif os(tvOS)
    /// Vends an appropriate `UIVisualEffect`.
    
    #elseif os(macOS)
    /// A type describing the values passed to an `NSVisualEffectView`.
    typealias Description = (material: NSVisualEffectView.Material,
                             blendingMode: NSVisualEffectView.BlendingMode)
    
    /// Vends an appropriate `VisualEffect.Description`.
    var parameters: Description {
        switch self {
        case .systemMaterial:
            return (.windowBackground, .behindWindow)
        case .menu:
            return (.menu, .behindWindow)
        case .popover:
            return (.popover, .withinWindow)
        case .sidebar:
            return (.sidebar, .behindWindow)
        case .headerView:
            return (.headerView, .withinWindow)
        case .sheet:
            return (.sheet, .behindWindow)
        case .windowBackground:
            return (.windowBackground, .behindWindow)
        case .hudWindow:
            return (.hudWindow, .behindWindow)
        case .fullScreenUI:
            return (.fullScreenUI, .behindWindow)
        case .toolTip:
            return (.toolTip, .withinWindow)
        case .contentBackground:
            return (.contentBackground, .withinWindow)
        case .underWindowBackground:
            return (.underWindowBackground, .behindWindow)
        case .underPageBackground:
            return (.underPageBackground, .withinWindow)
        }
    }
    #endif
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
@available(watchOS, unavailable)
struct VisualEffectView: View {
    private let content: _PlatformVisualEffectView
    var body: some View { content }
    
    fileprivate init(effect: VisualEffect) {
        self.content = _PlatformVisualEffectView(effect)
    }
    
    #if os(macOS)
    private struct _PlatformVisualEffectView: NSViewRepresentable {
        private let effect: VisualEffect
        
        fileprivate init(_ effect: VisualEffect) {
            self.effect = effect
        }
        
        func makeNSView(context: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            view.autoresizingMask = [.width, .height]
            return view
        }
        
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            let params: VisualEffect.Description = context.environment.visualEffect?.parameters ?? effect
            nsView.material = params.material
            nsView.blendingMode = params.blendingMode
            
            // mark emphasized if it contains the first responder
            if let resp = nsView.window?.firstResponder as? NSView {
                nsView.isEmphasized = resp === nsView || resp.isDescendant(of: nsView)
            }
            else {
                nsView.isEmphasized = false
            }
        }
    }
    #elseif canImport(UIKit)
    private struct _PlatformVisualEffectView: UIViewRepresentable {
        private let effect: VisualEffect
        
        fileprivate init(_ effect: VisualEffect) {
            self.effect = effect
        }
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: effect.parameters)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return view
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = context.environment.visualEffect?.parameters
                ?? effect.parameters
        }
    }
    #endif
}
  
extension View {
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
    @available(watchOS, unavailable)
    public func visualEffect(_ effect: VisualEffect = .systemMaterial) -> some View {
        background(VisualEffectView(effect: effect))
    }
}
