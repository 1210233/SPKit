//
//  SPErrorReporter.swift
//  
//
//  Created by LSP on 2021/1/9.
//

import Foundation
import SystemConfiguration

open
class SPError : SPModelBase {

    private static
    var SPERROR_RECORD_ID: Int {
        var id = UserDefaults.standard.integer(forKey: "SPERROR_RECORD_ID_KEY")
        if id == 0 {
            id = 1000
        }
        id += 1
        UserDefaults.standard.set(id, forKey: "SPERROR_RECORD_ID_KEY")
        return id
    }
    
    public var userId: String
    public var message: String
    public var location: String
    public lazy var recordID: Int = SPError.SPERROR_RECORD_ID
    public lazy var creatTime: TimeInterval = Date.timeStamp
    public lazy var errorType: Int = 0
    public lazy var appVersion: String = APP.VERSION
    public lazy var internalCode: Int = 10001

    convenience public
    init(userId: String, message msg: String, file: String = #fileID, line: Int = #line, func function: String = #function) {
        var dic = [String: Any]()
        
        dic["userId"] = userId
        dic["location"] = file.replacingOccurrences(of: "/", with: ".") + " in " + function + ":\(line)"
        dic["message"] = msg
        
        self.init(dic:dic)
    }
    
    
    required public init(dic: [String : Any]?) {
        var loc = "..."
        var uid = "-1"
        var msg = "no"
        
        let d = dic ?? [:]
        
        if let o = d["location"] as? String {
            loc = o
        }
        if let o = d["userId"] as? String {
            uid = o
        }
        if let o = d["message"] as? String {
            msg = o
        }
        
        self.location = loc
        self.userId = uid
        self.message = msg
        
        super.init(dic: dic)
        
        if let o = d["errorType"] as? Int {
            self.errorType = o
        }
        if let o = d["internalCode"] as? Int {
            self.internalCode = o
        }
        if let o = d["creatTime"] as? TimeInterval {
            self.creatTime = o
        }
        if let o = d["recordID"] as? Int {
            self.recordID = o
        }
        if let o = d["appVersion"] as? String {
            self.appVersion = o
        }
    }
}

public typealias ReportErrorComplete = (Bool, SPError) -> Void
public typealias ReportErrorHttpRequest = (SPError, ReportErrorComplete) -> Void

func NetworkChangedCallback(target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?){
    if let obj = target.infoObject as? SPErrorReporter {
        obj.networkChanged()
    }
}

var sp_infoObjectKey = "sp_infoObjectKey"


extension SCNetworkReachability {
    fileprivate
    var infoObject: Any? {
        get {
            return objc_getAssociatedObject(self, &sp_infoObjectKey)
        }
        set {
            objc_setAssociatedObject(self, &sp_infoObjectKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

fileprivate
var DEFAULT_ERROR_REPORTER: SPErrorReporter!

public final
class SPErrorReporter: NSObject {
    /// 使用SPErrorReporter.default请确保先调用start(with:ReportErrorHttpRequest)方法，否则将无法正常工作
    public static
    var `default`: SPErrorReporter {
        #if DEBUG
        if DEFAULT_ERROR_REPORTER == nil {
            print("使用SPErrorReporter.default请确保先调用start(with:)方法，否则无法正常工作")
            return SPErrorReporter { (e, v) in }
        }
        #endif
        return DEFAULT_ERROR_REPORTER
    }
    
    public var storePath: String =  {
        if var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            return path + "/SPErrors.dat"
        }
        return "/var"
    }()
    
    public var allErrors: [SPError] {
        return _allErrors ?? []
    }
    private var _allErrors: [SPError]!
    
    private var _errors: [SPError]!
    private var _connected = false
    private var _reachability: SCNetworkReachability!
    
    public var reportAction: ReportErrorHttpRequest
    
    init(reportAction action: @escaping ReportErrorHttpRequest) {
        self.reportAction = action
        super.init()
        
        _connected = "www.baidu.com".withCString({ bytes in
            if let reachability = SCNetworkReachabilityCreateWithName(nil, bytes) {
                reachability.infoObject = self
                _reachability = reachability
                return !SCNetworkReachabilitySetCallback(reachability, NetworkChangedCallback, nil)
            }
            return false
        })
    }

    public static
    func start(with action: @escaping ReportErrorHttpRequest) {
        DEFAULT_ERROR_REPORTER = Self(reportAction: action)
        DEFAULT_ERROR_REPORTER.startReport()
    }

    public func startReport() {
        let arr = NSArray(contentsOfFile: self.storePath) as? [[String: Any]] ?? []
        _errors = []
        _allErrors = []
        if !arr.isEmpty {
            for dic in arr {
                guard !dic.isEmpty else {
                    continue
                }
                let err = SPError(dic: dic)
                _allErrors.append(err)
                _errors.append(err)
            }
        }
        let thread = Thread(target: self, selector: #selector(reportCircle), object: nil)
        thread.name = "ErrorReportCircle" + String(arc4random_uniform(99) + 1)
        thread.start()
    }
    public func report(_ error:SPError) {
        _allErrors.append(error)
        _errors.append(error)
    }

    public func saveToDisk() {
        let arr = NSMutableArray()
        for error in _allErrors {
            arr.add(error.dictionary)
        }
        arr.write(toFile: self.storePath, atomically: true)
    }
    
    @objc func reportCircle() {
        weak var wself = self
        
        while true {
            if !_errors.isEmpty {
                let err = _errors.removeFirst()
                print("StartReportError: \(err)")
                
                self.reportAction(err, { (result, error) in
                    DispatchQueue.global(qos: .default).async {
                        if result {
                            wself?.reportSuccess(error)
                        } else {
                            wself?.reportFail(error)
                        }
                    }
                })
                
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                Thread.sleep(forTimeInterval: 5)
            }
        }
    }
    func reportSuccess(_ error: SPError) {
        _allErrors.remove(error)
        #if DEBUG
        print("ReportFail:ErrorID=\(error.recordID)");
        #endif
    }
    func reportFail(_ error: SPError) {
        _errors.append(error)
        #if DEBUG
        print("ReportSuccess:ErrorID=\(error.recordID)");
        #endif
    }
    
    func networkChanged() {
        var flags = SCNetworkReachabilityFlags.isLocalAddress
        if SCNetworkReachabilityGetFlags(_reachability, &flags) {
            _connected = (self.networkStatusFor(flags: flags) == 1)
        } else {
            _connected = false
        }
    }
    
    func networkStatusFor(flags: SCNetworkReachabilityFlags) -> Int {
        if !flags.contains(.reachable) {
            return 0
        }
        if !flags.contains(.connectionRequired) {
            return 1
        }
        if flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic) {
            if !flags.contains(.interventionRequired) {
                return 1
            }
        }
        if flags.contains(.isWWAN) {
            return 2
        }
        return 0
    }
    
    deinit {
        if _reachability != nil {
            _reachability.infoObject = nil
            SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        }
    }
}
