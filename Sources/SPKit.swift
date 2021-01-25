//
//  File.swift
//  
//
//  Created by Bee on 2021/1/7.
//

import Foundation
//import SPFoundationCategory
//import SPUIKitCategory

open class APP {
    // MARK: Version
    /// Current Version String.
    public static let VERSION: String = {
        if let dic = Bundle.main.infoDictionary, let v = dic["CFBundleShortVersionString"] as? String {
            return v
        }
        return "1.0.0"
    }()
    public static let STORED_VERSION_KEY = "APP_STORED_VERSION"
    public static var STORED_VERSION: String  {
        if let version = UserDefaults.standard.string(forKey: STORED_VERSION_KEY) {
            return version
        }
        UserDefaults.standard.set(VERSION, forKey: STORED_VERSION_KEY)
        return VERSION
    }
    public static func store(version: String) {
        UserDefaults.standard.set(version, forKey: STORED_VERSION_KEY)
    }
    
    
}

// 在主线程执行
public final class OnForeground {
    /**
     * Usable:
     *  OnForeground {
     *      statements...
     *  }
     */
    @discardableResult
    init?(code: @escaping () -> Void) {
        DispatchQueue.main.async(execute: code)
        return nil
    }
}

// 在全局线程执行
public final class OnBackground {
    /**
     * Usable:
     *  OnBackground {
     *      statements...
     *  }
     */
    @discardableResult
    init?(code: @escaping () -> Void) {
        DispatchQueue.global().async(execute: code)
        return nil
    }
    
    /**
     * Usable:
     *  OnBackground(.background) {
     *      statements...
     *  }
     */
    @discardableResult
    init?(_ qos: DispatchQoS.QoSClass, code: @escaping () -> Void) {
        DispatchQueue.global(qos: qos).async(execute: code)
        return nil
    }
}
