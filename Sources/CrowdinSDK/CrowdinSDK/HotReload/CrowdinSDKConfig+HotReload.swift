//
//  CrowdinSDKConfig+HotReload.swift
//  CrowdinSDK
//
//  Created by jackma on 2024/4/19.
//

import Foundation

extension CrowdinSDKConfig {
    private static var hotReloadEnabled: Bool = false
    
    /// Debug mode status
    var hotReloadEnabled: Bool {
        get {
            return CrowdinSDKConfig.hotReloadEnabled
        }
        set {
            CrowdinSDKConfig.hotReloadEnabled = newValue
            CrowdinSDK.enableHotReload(enable: newValue)
        }
    }
    
    /// Method for enabling/disabling debug mode through the config.
    /// - Parameter debugEnabled: A boolean value which indicate debug mode enabling status.
    @discardableResult
    public func with(hotReloadEnabled: Bool) -> Self {
        self.hotReloadEnabled = hotReloadEnabled
        return self
    }
}
