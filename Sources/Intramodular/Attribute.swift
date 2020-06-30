//
// Copyright (c) Vatsal Manot
//

import Data
import Swallow

@propertyWrapper
public struct Attribute<Value: Codable> {
    @usableFromInline
    var parent: NSManagedObject?
    
    @usableFromInline
    var key: AnyStringKey {
        fatalError()
    }
    
    public var wrappedValue: Value {
        get {
            guard let parent = parent else {
                fatalError()
            }
            
            return try! _CodableToNSAttributeCoder<Value>.decode(from: parent, forKey: key).value
        } set {
            guard let parent = parent else {
                fatalError()
            }
            
            try! _CodableToNSAttributeCoder(newValue).encode(to: parent, forKey: key)
        }
    }
    
    public init() {
        
    }
}
