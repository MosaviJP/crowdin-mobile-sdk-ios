//
//  Crowdin+HotReload.swift
//  CrowdinSDK
//
//  Created by jackma on 2024/4/18.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

var controls = NSHashTable<AnyObject>.weakObjects()
public extension CrowdinSDK {
    
    static func enableHotReload(enable: Bool) {
        isHotReloadEnabled = enable
    }
    
    // MARK: Sub
    
    static func subscribe(control: Refreshable) {
        guard let localizationKey = control.key else { return }
        controls.add(control)
    }
    
    static func unsubscribe(control: Refreshable) {
        controls.remove(control)
    }
    
    static func subscribeAllVisibleConrols() {
#if os(iOS) || os(tvOS)
        UIApplication.shared.windows.forEach({
            subscribeAllControls(from: $0)
        })
#elseif os(macOS)
        NSApplication.shared.windows.compactMap(\.contentView).forEach({
            subscribeAllControls(from: $0)
        })
#endif
    }
    
    static func unsubscribeAllVisibleConrols() {
        controls.removeAllObjects()
    }
    
    static func subscribeAllControls(from view: CWView) {
#if !os(watchOS)
        view.subviews.forEach { (subview) in
            if let refreshable = subview as? Refreshable {
                self.subscribe(control: refreshable)
            }
            subscribeAllControls(from: subview)
        }
#endif
    }
    
    static func unsubscribeAllControls(from view: CWView) {
#if !os(watchOS)
        view.subviews.forEach { (subview) in
            if let refreshable = subview as? Refreshable {
                self.unsubscribe(control: refreshable)
            }
            unsubscribeAllControls(from: subview)
        }
#endif
    }
    
    // MARK: Refresh
    
    /// Refresh view subview controls
    /// - Parameter view: UIView
    static func refreshSubviewControls(from view: CWView) {
#if !os(watchOS)
        view.subviews.forEach { subview in
            if let refreshable = subview as? Refreshable {
                refreshable.refresh()
            }
            refreshSubviewControls(from: subview)
        }
#endif
    }
    
    /// Refresh all controls from cache
    static func refreshAllControls() {
        controls.allObjects.forEach { (control) in
            if let refreshable = control as? Refreshable {
                refreshable.refresh()
            }
        }
    }
}

// MARK: - One-time refresh on language change
extension CrowdinSDK {
    static var isHotReloadEnabled = false

    /// Call while the old language is still active; returns the refresh action to run after switching.
    static func prepareLanguageRefresh(from views: [CWView]? = nil) -> () -> Void {
        var updates: [() -> Void] = []
#if os(iOS) || os(tvOS)
        for view in views ?? UIApplication.shared.windows {
            collectLanguageUpdates(from: view, into: &updates)
        }
#endif
        return { updates.forEach { $0() } }
    }
}

#if os(iOS) || os(tvOS)
private extension CrowdinSDK {
    static func collectLanguageUpdates(from view: UIView, into updates: inout [() -> Void]) {
        if let button = view as? UIButton {
            updates.append(contentsOf: UIControl.State.all.compactMap { button.prepareLanguageUpdate(for: $0) })
        } else if let label = view as? UILabel, let update = label.prepareLanguageUpdate() {
            updates.append(update)
        }
        for subview in view.subviews {
            // The button manages its own titleLabel; avoid collecting it twice.
            if let button = view as? UIButton, subview === button.titleLabel { continue }
            collectLanguageUpdates(from: subview, into: &updates)
        }
    }
}

// MARK: - Control updates
private extension UILabel {
    func prepareLanguageUpdate() -> (() -> Void)? {
        let attributed = attributedText
        guard let text = attributed?.string ?? self.text,
              let translate = prepareTranslation(for: text) else { return nil }
        return { [weak self] in
            guard let self = self, (self.attributedText?.string ?? self.text) == text else { return }
            let translated = translate()
            if let attributed = attributed {
                self.attributedText = attributed.replacingTextForLanguageRefresh(with: translated)
            } else {
                self.text = translated
            }
        }
    }
}

private extension UIButton {
    func prepareLanguageUpdate(for state: UIControl.State) -> (() -> Void)? {
        let attributed = attributedTitle(for: state)
        guard let text = attributed?.string ?? title(for: state),
              let translate = prepareTranslation(for: text) else { return nil }
        return { [weak self] in
            guard let self = self,
                  (self.attributedTitle(for: state)?.string ?? self.title(for: state)) == text else { return }
            let translated = translate()
            if let attributed = attributed {
                self.setAttributedTitle(attributed.replacingTextForLanguageRefresh(with: translated), for: state)
            } else {
                self.setTitle(translated, for: state)
            }
        }
    }
}

// MARK: - Translation helpers
/// Capture the key and arguments in the old language, then resolve text in the new language.
private func prepareTranslation(for text: String) -> (() -> String)? {
    guard let key = Localization.current.keyForString(text) else { return nil }
    let format = Localization.current.localizedString(for: key)
    let values = format.flatMap { Localization.current.findValues(for: text, with: $0) } as? [CVarArg]
    return { values.map { key.cw_localized(with: $0) } ?? key.cw_localized }
}

private extension NSAttributedString {
    func replacingTextForLanguageRefresh(with text: String) -> NSAttributedString {
        let attributes = length > 0 ? self.attributes(at: 0, effectiveRange: nil) : [:]
        return NSAttributedString(string: text, attributes: attributes)
    }
}
#endif
