//
//  File.swift
//  
//
//  Created by Jim Dovey on 2/3/20.
//

import SwiftUI
import UIKit

@available(iOS 13, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
fileprivate struct _KeyCommandProxy : Equatable {
    var uiKeyCommand: UIKeyCommand
    var action: () -> Void

    init(key: String, modifier: UIKeyModifierFlags = [], selector: Selector,
         discoverabilityTitle: String? = nil, action: @escaping () -> Void) {
        self.action = action
        self.uiKeyCommand = UIKeyCommand(
            title: discoverabilityTitle ?? "",
            action: selector,
            input: key,
            modifierFlags: modifier,
            discoverabilityTitle: discoverabilityTitle)
    }

    var discoverabilityTitle: String? { uiKeyCommand.discoverabilityTitle }
    var key: String { uiKeyCommand.input! }
    var modifierFlags: UIKeyModifierFlags { uiKeyCommand.modifierFlags }
    var selector: Selector { uiKeyCommand.action! }

    static func == (lhs: _KeyCommandProxy, rhs: _KeyCommandProxy) -> Bool {
        lhs.selector == rhs.selector
    }
}

@available(iOS 13, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
fileprivate struct _KeyCommandProxyKey: PreferenceKey {
    typealias Value = [_KeyCommandProxy]
    static var defaultValue: [_KeyCommandProxy] = []
    static func reduce(value: inout [_KeyCommandProxy], nextValue: () -> [_KeyCommandProxy]) {
        value.append(contentsOf: nextValue())
    }
}

extension NSNotification.Name {
    static var commandsUpdatedNotification = NSNotification.Name(rawValue: "aqui.swiftui.keycommands.updated")
}

fileprivate class KeyCommandHandler: NSObject {
    var commands = [Selector : _KeyCommandProxy]()

    func installCommand(_ command: _KeyCommandProxy) {
        typealias Block = (Any, Selector, Any?) -> ()
        let handler: Block = { [unowned self] _, sel, _ in
            self.commands[sel]?.action()
        }

        let imp = imp_implementationWithBlock(handler)
        class_replaceMethod(self.classForCoder, command.selector, imp, "v@:@")
    }
}

@available(iOS 13, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
public class KeyCommandingController<Content: View>: UIHostingController<KeyCommandingController.Root<Content>> {
    private var commandHandler = KeyCommandHandler()
    private var notificationObserver: NSObjectProtocol? = nil

    public init(rootView: Content) {
        super.init(rootView: Root(content: rootView))
        self.notificationObserver = NotificationCenter.default.addObserver(
            forName: .commandsUpdatedNotification,
            object: nil,
            queue: .main) { [weak self] (notification: Notification) in
                guard let self = self else { return }

                let newCommands = notification.userInfo!["Commands"] as! [_KeyCommandProxy]
                let removed = self.commandHandler.commands.filter { selector, _ in
                    !newCommands.contains { $0.selector == selector }
                }
                let added = newCommands.filter { self.commandHandler.commands[$0.selector] == nil }

                for (_, value) in removed {
                    self.removeKeyCommand(value.uiKeyCommand)
                }
                for cmd in added {
                    self.commandHandler.installCommand(cmd)
                }
        }
    }

    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if commandHandler.commands[aSelector] != nil {
            return commandHandler
        }
        return nil
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public struct Root<Content: View>: View {
        fileprivate var content: Content

        public var body: some View {
            content.onPreferenceChange(_KeyCommandProxyKey.self) { values in
                NotificationCenter.default.post(
                    name: .commandsUpdatedNotification,
                    object: nil,
                    userInfo: ["Commands" : values])
            }
        }
    }
}

fileprivate func mapModifiers(_ modifiers: EventModifiers) -> UIKeyModifierFlags {
    guard modifiers != .all else {
        return [.command, .control, .alternate, .alphaShift, .numericPad, .shift]
    }

    var result: UIKeyModifierFlags = []
    if modifiers.contains(.capsLock) {
        result.insert(.alphaShift)
    }
    if modifiers.contains(.command) {
        result.insert(.command)
    }
    if modifiers.contains(.control) {
        result.insert(.control)
    }
    if modifiers.contains(.option) {
        result.insert(.alternate)
    }
    if modifiers.contains(.shift) {
        result.insert(.shift)
    }
    if modifiers.contains(.numericPad) {
        result.insert(.numericPad)
    }
    return result
}

@available(iOS 13, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
extension View {
    func keyCommand(
        key: Character,
        modifiers: EventModifiers = [],
        selector: Selector,
        discoverabilityTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        let command = _KeyCommandProxy(
            key: String(key),
            modifier: mapModifiers(modifiers),
            selector: selector,
            discoverabilityTitle: discoverabilityTitle,
            action: action)
        return self.preference(key: _KeyCommandProxyKey.self, value: [command])
    }
}
