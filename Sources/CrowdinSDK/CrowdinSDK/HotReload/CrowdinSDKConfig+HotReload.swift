//
//  CrowdinSDKConfig+HotReload.swift
//  CrowdinSDK
//
//  Created by jackma on 2024/4/19.
//

import Foundation

extension CrowdinSDKConfig {
    
    /// Whether to refresh controls in application windows when the language changes.
    var hotReloadEnabled: Bool {
        get {
            return CrowdinSDK.isHotReloadEnabled
        }
        set {
            CrowdinSDK.enableHotReload(enable: newValue)
        }
    }
    
    /// Configure refresh on language changes without swizzling control setters.
    /// - Parameter hotReloadEnabled: Whether to automatically refresh existing controls.
    @discardableResult
    public func with(hotReloadEnabled: Bool) -> Self {
        self.hotReloadEnabled = hotReloadEnabled
        return self
    }
}
