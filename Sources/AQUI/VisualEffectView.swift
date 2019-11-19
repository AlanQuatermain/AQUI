//
//  File.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

import SwiftUI

#if canImport(UIKit)
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
        @available(macCatalyst, unavailable)
        case titlebar

        @available(OSX 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        @available(macCatalyst, unavailable)
        case windowBackground

        @available(OSX 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        @available(macCatalyst, unavailable)
        case headerView(behindWindow: Bool)

        @available(OSX 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        @available(macCatalyst, unavailable)
        case contentBackground(behindWindow: Bool)

        @available(OSX 10.15, *)
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        @available(macCatalyst, unavailable)
        case behindPageBackground(behindWindow: Bool)
    }

    case system
    case systemLight
    case systemDark

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
        case .system:      return .systemMaterial
        case .systemLight: return .systemMaterialLight
        case .systemDark:  return .systemMaterialDark
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
        case .adaptive, .system:   return UIBlurEffect(style: .regular)
        case .light, .systemLight: return UIBlurEffect(style: .light)
        case .dark, .systemDark:   return UIBlurEffect(style: .dark)
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
        case .system:      return NSEffectParameters()
        case .systemLight: return NSEffectParameters(appearance: NSAppearance(named: .aqua))
        case .systemDark:  return NSEffectParameters(appearance: NSAppearance(named: .darkAqua))
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
        case .system, .systemLight, .systemDark:
            return .contentBackground
        case .adaptive(let material), .light(let material), .dark(let material):
            switch material {
            case .default, .contentBackground: return .contentBackground
            case .headerView: return .headerView
            case .behindPageBackground: return .underPageBackground
            case .windowBackground: return .windowBackground
            }
        }
    }

    private var blendingMode: NSVisualEffectView.BlendingMode {
        switch self {
        case .system, .systemLight, .systemDark:
            return .behindWindow
        case .adaptive(let material),
             .light(let material),
             .dark(let material):
            switch material {
            case .default, .windowBackground:
                return .behindWindow
            case .contentBackground(let b),
                 .headerView(let b),
                 .behindPageBackground(let b):
                return b ? .behindWindow : .withinWindow
            }
        }
    }
}
#endif

@available(OSX 10.15, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
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
            let params = context.environment.visualEffect?.parameters
                ?? effect.parameters
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
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
    @available(watchOS, unavailable)
    public func visualEffect(_ effect: VisualEffect = .system) -> some View {
        background(VisualEffectView(effect: effect))
    }
}
