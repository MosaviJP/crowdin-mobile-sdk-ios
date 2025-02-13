//
//  Crowdin+HotReload.swift
//  CrowdinSDK
//
//  Created by jackma on 2024/4/18.
//

import Foundation
import CrowdinSDK

var controls = NSHashTable<AnyObject>.weakObjects()
public extension CrowdinSDK {
    
    static func enableHotReload(enable: Bool) {
        if enable {
            self.swizzleControlMethods()
        } else {
            self.unswizzleControlMethods()
        }
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
        UIApplication.shared.windows.forEach({
            subscribeAllControls(from: $0)
        })
    }
    
    static func unsubscribeAllVisibleConrols() {
        controls.removeAllObjects()
    }
    
    static func subscribeAllControls(from view: CWView) {
        view.subviews.forEach { (subview) in
            if let refreshable = subview as? Refreshable {
                self.subscribe(control: refreshable)
            }
            subscribeAllControls(from: subview)
        }
    }
    
    static func unsubscribeAllControls(from view: CWView) {
        view.subviews.forEach { (subview) in
            if let refreshable = subview as? Refreshable {
                self.unsubscribe(control: refreshable)
            }
            unsubscribeAllControls(from: subview)
        }
    }
    
    // MARK: Refresh
    
    /// Refresh view subview controls
    /// - Parameter view: UIView
    static func refreshSubviewControls(from view: CWView) {
        view.subviews.forEach { subview in
            if let refreshable = subview as? Refreshable {
                refreshable.refresh()
            }
            refreshSubviewControls(from: subview)
        }
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
