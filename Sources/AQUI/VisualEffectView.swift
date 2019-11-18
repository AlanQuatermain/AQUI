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
    typealias Value = VisualEffect
    static var defaultValue: Value = .default
}
  
extension EnvironmentValues {
    public var visualEffect: VisualEffect {
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
public enum VisualEffect: Equatable, Hashable {
    public enum Material: Equatable, Hashable {
        @available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
        case `default`

        @available(iOS 13.0, tvOS 13.0, *)
        @available(OSX, unavailable)
        case ultraThin

        @available(iOS 13.0, tvOS 13.0, *)
        @available(OSX, unavailable)
        case thin

        @available(iOS 13.0, tvOS 13.0, *)
        @available(OSX, unavailable)
        case thick

        @available(iOS 13.0, tvOS 13.0, *)
        @available(OSX, unavailable)
        case chrome

        @available(OSX 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        case headerView(behindWindow: Bool)

        @available(OSX 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        case windowBackground

        @available(OSX 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        case contentBackground(behindWindow: Bool)

        @available(OSX 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        case pageBackground(behindWindow: Bool)
    }

    case `default`
    case defaultLight
    case defaultDark

    case adaptive(Material)
    case light(Material)
    case dark(Material)
}

#if os(iOS) || targetEnvironment(macCatalyst)
extension VisualEffect {
    /// Vends an appropriate `UIVisualEffect`.
    var parameters: UIVisualEffect { UIBlurEffect(style: self.blurStyle) }

    private var blurStyle: UIBlurEffect.Style {
        switch self {
        case .default:      return .systemMaterial
        case .defaultLight: return .systemMaterialLight
        case .defaultDark:  return .systemMaterialDark
        case .adaptive(let material):
            switch material {
            case .ultraThin:    return .systemUltraThinMaterial
            case .thin:         return .systemThinMaterial
            case .default:      return .systemMaterial
            case .thick:        return .systemThickMaterial
            case .chrome:       return .systemChromeMaterial
            }
        case .light(let material):
            switch material {
            case .ultraThin:    return .systemUltraThinMaterialLight
            case .thin:         return .systemThinMaterialLight
            case .default:      return .systemMaterialLight
            case .thick:        return .systemThickMaterialLight
            case .chrome:       return .systemChromeMaterialLight
            }
        case .dark(let material):
            switch material {
            case .ultraThin:    return .systemUltraThinMaterialDark
            case .thin:         return .systemThinMaterialDark
            case .default:      return .systemMaterialDark
            case .thick:        return .systemThickMaterialDark
            case .chrome:       return .systemChromeMaterialDark
            }
        }
    }
}
#elseif os(tvOS)
extension VisualEffect {
    /// Vends an appropriate `UIVisualEffect`.
    var parameters: UIVisualEffect {
        switch self {
        case .adaptive, .default:   return UIBlurEffect(style: .regular)
        case .light, .defaultLight: return UIBlurEffect(style: .light)
        case .dark, .defaultDark:   return UIBlurEffect(style: .dark)
        }
    }
}
#elseif os(macOS)
extension VisualEffect {
    /// A type describing the values passed to an `NSVisualEffectView`.
    struct NSEffectParameters {
        var material: NSVisualEffectView.Material = .contentBackground
        var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
        var appearance: NSAppearance? = nil
    }
    
    /// Vends an appropriate `NSEffectParameters`.
    var parameters: NSEffectParameters {
        switch self {
        case .default:      return NSEffectParameters()
        case .defaultLight: return NSEffectParameters(appearance: NSAppearance(named: .aqua))
        case .defaultDark:  return NSEffectParameters(appearance: NSAppearance(named: .darkAqua))
        case .adaptive:
            return NSEffectParameters(material: self.material,
                                      blendingMode: self.blendingMode)
        case .light:
            return NSEffectParameters(material: self.material,
                                      blendingMode: self.blendingMode,
                                      appearance: NSAppearance(named: .aqua))
        case .dark:
            return NSEffectParameters(material: self.material,
                                      blendingMode: self.blendingMode,
                                      appearance: NSAppearance(named: .darkAqua))
        }
    }

    private var material: NSVisualEffectView.Material {
        switch self {
        case .default, .defaultLight, .defaultDark:
            return .contentBackground
        case .adaptive(let material), .light(let material), .dark(let material):
            switch material {
            case .default, .contentBackground: return .contentBackground
            case .headerView: return .headerView
            case .pageBackground: return .underPageBackground
            case .windowBackground: return .windowBackground
            }
        }
    }

    private var blendingMode: NSVisualEffectView.BlendingMode {
        switch self {
        case .default, .defaultLight, .defaultDark:
            return .behindWindow
        case .adaptive(let material),
             .light(let material),
             .dark(let material):
            switch material {
            case .default, .windowBackground:
                return .behindWindow
            case .contentBackground(let b),
                 .headerView(let b),
                 .pageBackground(let b):
                return b ? .behindWindow : .withinWindow
            }
        }
    }
}
#endif

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
@available(watchOS, unavailable)
struct VisualEffectView: View {
    private let content: _PlatformVisualEffectView
    @State private var effect: VisualEffect
    var body: some View {
        content
            .environment(\.visualEffect, effect)
            .onPreferenceChange(VisualEffectPreferenceKey.self) {
                self.effect = $0 ?? .default
            }
    }
    
    fileprivate init(effect: VisualEffect) {
        self._effect = State(initialValue: effect)
        self.content = _PlatformVisualEffectView()
    }
    
    #if os(macOS)
    private struct _PlatformVisualEffectView: NSViewRepresentable {
        func makeNSView(context: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            view.autoresizingMask = [.width, .height]
            return view
        }
        
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            let params = context.environment.visualEffect.parameters
            nsView.material = params.material
            nsView.blendingMode = params.blendingMode
            nsView.appearance = params.appearance
            
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
        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: context.environment.visualEffect.parameters)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return view
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = context.environment.visualEffect.parameters
        }
    }
    #endif
}
  
extension View {
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
    @available(watchOS, unavailable)
    public func visualEffect(_ effect: VisualEffect = .default) -> some View {
        background(VisualEffectView(effect: effect))
    }
}
