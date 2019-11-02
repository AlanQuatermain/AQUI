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

#if os(macOS)
struct VisualEffectMaterialKey: EnvironmentKey {
    typealias Value = NSVisualEffectView.Material?
    static var defaultValue: Value = nil
}
  
struct VisualEffectBlendingKey: EnvironmentKey {
    typealias Value = NSVisualEffectView.BlendingMode?
    static var defaultValue: Value = nil
}
  
struct VisualEffectEmphasizedKey: EnvironmentKey {
    typealias Value = Bool?
    static var defaultValue: Bool? = nil
}
#endif

#if os(iOS) || targetEnvironment(macCatalyst)
struct VisualEffectUIEffectKey: EnvironmentKey {
    typealias Value = UIVisualEffect?
    static var defaultValue: UIVisualEffect? = nil
}
#endif
  
extension EnvironmentValues {
    #if os(macOS)
    public var visualEffectMaterial: NSVisualEffectView.Material? {
        get { self[VisualEffectMaterialKey.self] }
        set { self[VisualEffectMaterialKey.self] = newValue }
    }
      
    public var visualEffectBlending: NSVisualEffectView.BlendingMode? {
        get { self[VisualEffectBlendingKey.self] }
        set { self[VisualEffectBlendingKey.self] = newValue }
    }
      
    public var visualEffectEmphasized: Bool? {
        get { self[VisualEffectEmphasizedKey.self] }
        set { self[VisualEffectEmphasizedKey.self] = newValue }
    }
    #elseif canImport(UIKit)
    public var visualEffect: UIVisualEffect? {
        get { self[VisualEffectUIEffectKey.self] }
        set { self[VisualEffectUIEffectKey.self] = newValue }
    }
    #endif
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
@available(watchOS, unavailable)
struct VisualEffectView: View {
    private let content: _PlatformVisualEffectView
    var body: some View { content }
    
    fileprivate init(parameters: _PlatformParameters) {
        self.content = _PlatformVisualEffectView(parameters)
    }
    
    #if os(macOS)
    fileprivate typealias _PlatformParameters = (material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode, emphasized: Bool)
    private struct _PlatformVisualEffectView: NSViewRepresentable {
        private let parameters: _PlatformParameters
        
        fileprivate init(_ parameters: _PlatformParameters) {
            self.parameters = parameters
        }
        
        func makeNSView(context: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            
            // Not certain how necessary this is
            view.autoresizingMask = [.width, .height]
            
            return view
        }
        
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            nsView.material = context.environment.visualEffectMaterial ?? parameters.material
            nsView.blendingMode = context.environment.visualEffectBlending ?? parameters.blendingMode
            nsView.isEmphasized = context.environment.visualEffectEmphasized ?? parameters.emphasized
        }
    }
    #elseif canImport(UIKit)
    fileprivate typealias _PlatformParameters = UIVisualEffect
    private struct _PlatformVisualEffectView: UIViewRepresentable {
        private let effect: _PlatformParameters
        
        fileprivate init(_ parameters: _PlatformParameters) {
            self.effect = parameters
        }
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: effect)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return view
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = context.environment.visualEffect ?? effect
        }
    }
    #endif
}
  
extension View {
    #if os(macOS)
    @available(OSX 10.15, *)
    @available(watchOS, unavailable)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    public func visualEffect(
        material: NSVisualEffectView.Material = .appearanceBased,
        blendingMode: NSVisualEffectView.BlendingMode = .withinWindow,
        emphasized: Bool = false
    ) -> some View {
        background(
            VisualEffectView(parameters: (material, blendingMode, emphasized))
        )
    }
    #elseif canImport(UIKit)
    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    public func visualEffect(effect: UIVisualEffect = UIBlurEffect(style: .systemMaterial)) -> some View {
        background(
            VisualEffectView(parameters: (effect))
        )
    }
    #endif
}
