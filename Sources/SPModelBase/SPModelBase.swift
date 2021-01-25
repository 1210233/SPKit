//
//  SPModelBase.swift
//  
//
//  Created by LSP on 2021/1/9.
//

import Foundation
import SPFoundationCategory

let SPMODEL_SAVED_PATH: String = {
    if var path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
        return path + "/SPModels"
    }
    return "/var"
}()


// MARK: Protocols
public
protocol SPModel {
    static
    func from(dics: [[String: Any]]) -> [SPModel]
}

public
protocol ModelObserverDelegate: NSObjectProtocol {
    /**
     * obj 属性发生变化的对象。
     * property 发生变化的属性。
     */
    func observed<T>(object: T, changeAt property: String, from oldValue: Any?) where T: SPModel
}

// MARK: - Primary class
open class SPModelBase: NSObject, SPModel {
    /**
     * Contains key-value-pair that's the dictionary for initialized.
     */
    private
    var _dictionary: [String: Any] = [:]
    public
    var dictionary: [String: Any] {
        return _dictionary
    }
    
    /**
     *  Initialize instance from a Dictionary instance.
     *  As a subclass,You must override this method and call initWithDic: for super
     *  to ensure the instance variable _dictionary setted.
     */
    required public
    init(dic d: [String: Any]?) {
        super.init()
        guard let dic = d else {
            _dictionary = [:]
            return
        }
        
        _dictionary = dic.filterNullValues()
    }
    
    /**
     Create instance without any argument.
     @return Instance.
     */
    public class
    func model() -> Self {
        return Self(dic: [:])
    }

    /**
     * Create instances from an array which has included NSDictionary instances.
     */
    public static
    func from(dics: [[String : Any]]) -> [SPModel] {
        var array = [SPModel]()
        dics.filterNullValues().forEach { (d) in
            array.append(Self(dic: d))
        }
        return array
    }
    
    public
    func toDictionary() -> [String: Any] {
        var dic = [String: Any]()
        var mir: Mirror! = Mirror(reflecting: self)
        repeat {
            let children = Array(mir.children) as! [(label: String, value: Any)]

            for child in children {
                dic[child.label] = child.value
            }
            
            mir = mir.superclassMirror
        } while (mir != nil && mir.subjectType != SPModelBase.self)
        
        return dic
    }

    // for Obseration
    private
    var observeMap: [String: [ModelObserver]] = [:] // [PropertyName: [Observers]]
    private
    var observers: [String: ModelObserver] = [:] // [ObjectAddress: Observer]
}


class ModelObserver: Equatable {
    static func == (lhs: ModelObserver, rhs: ModelObserver) -> Bool {
        if lhs.delegateAddress == rhs.delegateAddress {
            return true
        }
        return false
    }
    
    weak var delegate: ModelObserverDelegate?
    var observedKeies: Set<String> = []
    var delegateAddress: String
    init(delegate: NSObject & ModelObserverDelegate) {
        self.delegate = delegate
        self.delegateAddress = delegate.modelObserverKey
    }
}


/// MARK: - SPModelBase扩展
// MARK: - Obseration
extension SPModelBase {
    /**
     * Plase call this function in Property's didSet{ } block.
     * Exam: var num: Int {
     *          didSet {
     *              self.changeAt(property: "num", from: oldValue)
     *          }
     *      }
     */
    public func changeAt(property name: String, from oldValue: Any?) {
        guard let arr =  observeMap[name] else {
            return
        }
        for observer in arr {
            if observer.delegate == nil {
                self.observers.removeValue(forKey: observer.delegateAddress)
            } else {
                if observer.observedKeies.isEmpty {
                    self.observers.removeValue(forKey: observer.delegateAddress)
                } else {
                    observer.delegate!.observed(object: self, changeAt: name, from: oldValue)
                }
            }
        }
        
    }
    
    public
    func observed<T: NSObject>(by obj: T, atProperty property: String) where T: ModelObserverDelegate {
        let key = obj.modelObserverKey
        
        
        var observer: ModelObserver! = self.observers[key]
        if observer == nil {
            observer = ModelObserver(delegate: obj)
            self.observers[key] = observer
        }
        
        if !observer.observedKeies.contains(property) {
            observer.observedKeies.insert(property)

            var arr: [ModelObserver]
            if let a = self.observeMap[property] {
                arr = a
            } else {
                arr = []
            }
            if !arr.contains(observer) {
                arr.append(observer)
            }
            self.observeMap[property] = arr
        }
    }
    public
    func observed<T: NSObject>(by obj: T, atProperties properties: [String]) where T: ModelObserverDelegate {
        let key = obj.modelObserverKey
        
        var observer: ModelObserver! = self.observers[key]
        if observer == nil {
            observer = ModelObserver(delegate: obj)
            self.observers[key] = observer
        }
        for property in properties {
            if !observer.observedKeies.contains(property) {
                observer.observedKeies.insert(property)
                
                var arr: [ModelObserver]
                if let a = self.observeMap[property] {
                    arr = a
                } else {
                    arr = []
                }
                if !arr.contains(observer) {
                    arr.append(observer)
                }
                self.observeMap[property] = arr
            }
        }
    }
    public
    func removeObserved<T: NSObject>(by obj: T, atProperties properties: [String]) where T: ModelObserverDelegate {
        let key = obj.modelObserverKey
        guard let observer = self.observers[key] else {
            return
        }
        
        for property in properties {
            if observer.observedKeies.contains(property) {
                observer.observedKeies.remove(property)
                
                if var arr = self.observeMap[property], arr.contains(observer) {
                    arr.remove(observer)
                    if arr.isEmpty {
                        self.observeMap.removeValue(forKey: property)
                    } else {
                        self.observeMap[property] = arr
                    }
                }
            }
        }
        if observer.observedKeies.isEmpty {
            self.observers.removeValue(forKey: key)
        }
    }
    public
    func removeObserved<T: NSObject>(by obj: T, atProperty property: String = "") where T: ModelObserverDelegate {
        let key = obj.modelObserverKey
        guard let observer = self.observers[key] else {
            return
        }
        if property.isEmpty {
            for temp in observer.observedKeies {
                
                if var arr = self.observeMap[temp], arr.contains(observer) {
                    arr.remove(observer)
                    if arr.isEmpty {
                        self.observeMap.removeValue(forKey: temp)
                    } else {
                        self.observeMap[temp] = arr
                    }
                }
            }
            self.observers.removeValue(forKey: key)
        } else {
            if observer.observedKeies.contains(property) {
                observer.observedKeies.remove(property)
                
                if var arr = self.observeMap[property], arr.contains(observer) {
                    arr.remove(observer)
                    if arr.isEmpty {
                        self.observeMap.removeValue(forKey: property)
                    } else {
                        self.observeMap[property] = arr
                    }
                }
            }
            if observer.observedKeies.isEmpty {
                self.observers.removeValue(forKey: key)
            }
        }
    }
}

var sp_modelObserverKey = "sp_modelObserverKey"

extension NSObject {
    fileprivate
    var modelObserverKey: String {
        get {
            if let v = objc_getAssociatedObject(self, &sp_modelObserverKey) as? String {
                return v
            }
            let key = String(format: "%p", self)
            self.modelObserverKey = key
            return key
        }
        set {
            objc_setAssociatedObject(self, &sp_modelObserverKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
}

// MARK: - Persistence
extension SPModelBase {
    
    static
    var storedPath: String {
        return SPMODEL_SAVED_PATH + "/\(Self.self)/"
    }
    
    public
    func saveToDisk(_ forKey: String = "default") {
        let path = Self.storedPath + forKey + ".dat"
        NSDictionary(dictionary: _dictionary).write(toFile: path, atomically: true)
    }
    
    public
    func clearInDisk(_ forKey: String = "default") {
        let path = Self.storedPath + forKey + ".dat"
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch { }
    }
    
    public
    func loadFromDisk(_ forKey: String = "default") -> Self {
        let path = Self.storedPath + forKey + ".dat"
        if let d = NSDictionary(contentsOfFile: path) {
            let a = Dictionary<String, Any>(_immutableCocoaDictionary: d)
            return Self(dic: a)
        }
        return Self.model()
    }
}

// MARK: - CustomDescription
extension SPModelBase {
    
    public override var description: String {
        var desc = ""
        var prefix = "{| "

        var mir: Mirror! = Mirror(reflecting: self)
        repeat {
            let children = Array(mir.children) as! [(label: String, value: Any)]

            for child in children {
                if var v = child.value as? String {
                    if v == "" {
                        v = "<blank>"
                    }
                    desc += prefix + child.label + " -> " + v + "\n"
                } else {
                    var str = String(describing: child.value)
                    if str.hasPrefix("Optional(") {
                        str = str[9 ..< str.count]
                    }
                    if str == "nil" {
                        str = "<nil>"
                    }
                    if str.contains("["), str.contains("]") {
                        if str.contains("\": ") {
                            var dicStrs: [String] = []
                            for temp in str[1 ..< str.count].components(separatedBy: ",") {
                                if temp.contains("\n") {
                                    dicStrs.append(temp.replacingOccurrences(of: "\": ", with: "\":\n").replacingOccurrences(of: "\n", with: "\n  "))
                                } else {
                                    dicStrs.append(temp)
                                }
                            }
                            str = "[" + dicStrs.joined(separator: ",") + "]"
                        }
                        if str.contains(",") {
                            str = str.replacingOccurrences(of: ", ", with: ",\n")
                        }
                        if str.contains("\n") {
                            str = str.replacingOccurrences(of: "\n", with: "\n            ")
                        }
                    }else{
                        if str.contains("\n") {
                            str = str.replacingOccurrences(of: "\n", with: "\n           ")
                        }
                    }
                    
                    desc += prefix + child.label + " -> " + str + "\n"
                }
                if prefix != " | " {
                    prefix = " | "
                }
            }
            
            mir = mir.superclassMirror
        } while (mir != nil && mir.subjectType != SPModelBase.self)
        
        desc += String(format: "} <= <\(Self.self): %p>", self)
        return desc
    }
}

