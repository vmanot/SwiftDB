//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

extension NSObjectProtocol where Self: NSManagedObject {
    public func primitiveValueExists(forKey key: String) -> Bool {
        primitiveValue(forKey: key) != nil
    }
    
    public func willAccessValue<Value>(_ keyPath: KeyPath<Self, Value>) {
        willAccessValue(forKey: keyPath._kvcKeyPathString!)
    }
    
    public func didAccessValue<Value>(_ keyPath: KeyPath<Self, Value>) {
        didAccessValue(forKey: keyPath._kvcKeyPathString!)
    }
    
    public subscript<Value>(primitive keyPath: KeyPath<Self, Value>) -> Value? {
        get {
            primitiveValue(forKey: keyPath._kvcKeyPathString!) as? Value
        } set {
            setPrimitiveValue(newValue, forKey: keyPath._kvcKeyPathString!)
        }
    }
    
    public subscript<Value>(primitive keyPath: KeyPath<Self, Value>, defaultValue defaultValue: @autoclosure () -> Value) -> Value {
        get {
            primitiveValue(forKey: keyPath._kvcKeyPathString!) as? Value ?? defaultValue()
        } set {
            setPrimitiveValue(newValue, forKey: keyPath._kvcKeyPathString!)
        }
    }
    
    public subscript<Value>(dynamic keyPath: KeyPath<Self, Value>, defaultValue: @autoclosure () -> Value) -> Value {
        get {
            willAccessValue(keyPath)
            
            defer {
                didAccessValue(keyPath)
            }
            
            return self[primitive: keyPath, defaultValue: defaultValue()]
        }
    }
}
