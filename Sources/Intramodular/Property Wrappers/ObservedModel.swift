//
// Copyright (c) Vatsal Manot
//

import Combine
import CoreData
import Swift
import SwiftAPI
import SwiftUIX

// A property wrapper type that subscribes to an observable model and invalidates a view whenever the observable model changes.
@propertyWrapper
public struct ObservedModel<Model: Entity>: DynamicProperty {
    @Environment(\.database) var database
    
    private let initialValue: Model
    
    public var wrappedValue: Model {
        get {
            initialValue
        }
    }
    
    public var projectedValue: Binding<Model> {
        fatalError(reason: .unimplemented)
    }
    
    public func update() {
        
    }
    
    public init(wrappedValue: Model) {
        self.initialValue = wrappedValue
    }
}

public final class UpdatingSnapshot<Model>: ObservableObject {
    private let querySubscription: QuerySubscription<Model>
    
    @Published private(set) var snapshot: RecordSnapshot<Model>
    
    init(
        database: AnyDatabaseContainer.LiveAccess,
        snapshot: RecordSnapshot<Model>
    ) throws {
        querySubscription = try database.querySubscription(
            for: QueryRequest<Model>(
                predicate: nil,
                sortDescriptors: nil,
                fetchLimit: FetchLimit.max(1),
                scope: .init(
                    records: [snapshot.instanceMetadata.recordID]
                )
            )
        )
        
        self.snapshot = snapshot
    }
}
