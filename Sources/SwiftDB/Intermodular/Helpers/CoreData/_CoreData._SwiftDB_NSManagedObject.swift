//
// Copyright (c) Vatsal Manot
//

import CoreData
import Merge
import Swift

extension _CoreData {
    /// A `NSManagedObject` subclass with modern provisions.
    @objc(_SwiftDB_NSManagedObject)
    open class _SwiftDB_NSManagedObject: NSManagedObject {
        lazy private(set) var cancellables = Cancellables()
        
        var areInitialAttributesSetup: Bool = false
        
        open func setupInitialAttributes() {
            areInitialAttributesSetup = true
        }
        
        /// Derive and set any calculated attributes.
        ///
        /// This is typically done for optimization purposes.
        open func deriveAttributes() {
            
        }
        
        override open func awakeFromInsert() {
            super.awakeFromInsert()
            
            if !areInitialAttributesSetup {
                setupInitialAttributes()
            }
            
            deriveAttributes()
        }
        
        override open func awakeFromFetch() {
            super.awakeFromFetch()
            
            deriveAttributes()
        }
        
        override open func willSave() {
            super.willSave()
        }
        
        override open func willAccessValue(forKey key: String?) {
            super.willAccessValue(forKey: key)
        }
        
        override public func willChangeValue(forKey key: String) {
            super.willChangeValue(forKey: key)
            
            if managedObjectContext != nil {
                objectWillChange.send()
            }
        }
        
        /// Provide a fallback value for `primitiveValue(forKey:)`.
        open func primitiveDefaultValue(forKey key: String) -> Any? {
            return nil
        }
        
        override open func primitiveValue(forKey key: String) -> Any? {
            if let result = super.primitiveValue(forKey: key) {
                return result
            } else if let result = primitiveDefaultValue(forKey: key) {
                return result
            } else {
                return nil
            }
        }
    }
}
