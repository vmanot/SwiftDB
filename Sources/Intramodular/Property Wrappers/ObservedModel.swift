//
// Copyright (c) Vatsal Manot
//

import API
import Combine
import CoreData
import Swift
import SwiftUIX

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
                    records: [snapshot.recordMetadata.id]
                )
            )
        )
        
        self.snapshot = snapshot
    }
}

// A property wrapper type that subscribes to an observable model and invalidates a view whenever the observable model changes.
@propertyWrapper
public struct ObservedModel<Model: Entity>: DynamicProperty {
    @Environment(\.database) var database
    
    private let initialValue: RecordSnapshot<Model>
    
    public var wrappedValue: RecordSnapshot<Model> {
        get {
            initialValue
        }
    }
    
    public var projectedValue: Binding<Model> {
        fatalError(reason: .unimplemented)
    }
    
    public func update() {
        
    }
    
    public init(wrappedValue: RecordSnapshot<Model>) {
        self.initialValue = wrappedValue
    }
}
