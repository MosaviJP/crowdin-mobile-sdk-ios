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
    
    static func subscribeAllControls(from view: View) {
        view.subviews.forEach { (subview) in
            if let refreshable = subview as? Refreshable {
                self.subscribe(control: refreshable)
            }
            subscribeAllControls(from: subview)
        }
    }
    
    static func refreshAllControls() {
        controls.allObjects.forEach { (control) in
            if let refreshable = control as? Refreshable {
                refreshable.refresh()
            }
        }
    }
}
