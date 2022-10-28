//
// Copyright (c) Vatsal Manot
//

import Merge
import Swift

/// A type-erased database.
public final class AnyDatabase: Database {
    public typealias SchemaAdaptor = AnyDatabaseSchemaAdaptor
    public typealias RecordSpace = AnyDatabaseRecordSpace
    public typealias Zone = AnyDatabaseZone
    
    private let base: any Database
    
    public var name: String {
        base.name
    }
    
    public var id: ID {
        .init(base: base.id)
    }
    
    public var configuration: Configuration {
        .init(base: base.configuration)
    }
    
    public var state: State {
        .init(base: base.state)
    }
    
    public var context: Context {
        base._opaque_context
    }
    
    public init<D: Database>(_ database: D) {
        self.base = database
    }
    
    public init(
        runtime: _SwiftDB_Runtime,
        schema: _Schema?,
        configuration: Configuration,
        state: State?
    ) throws {
        throw Never.Reason.unsupported
    }
    
    public func fetchAllAvailableZones() -> AnyTask<[AnyDatabaseZone], Error> {
        base._opaque_fetchAllAvailableZones()
    }
    
    public func fetchZone(named zoneName: String) -> AnyTask<AnyDatabaseZone, Error> {
        base._opaque_fetchZone(named: zoneName)
    }
    
    public func recordSpace(forZones zones: [AnyDatabaseZone]?) throws -> AnyDatabaseRecordSpace {
        try base._opaque_recordSpace(forZones: zones)
    }
    
    public func delete() -> AnyTask<Void, Error> {
        base.delete()
    }
}

// MARK: - Auxiliary Implementation -

extension AnyDatabase {
    public struct ID: Codable, Hashable {
        let base: AnyCodable
        
        init(base: Codable) {
            self.base = AnyCodable(base)
        }
        
        public init(from decoder: Decoder) throws {
            throw Never.Reason.unsupported
        }
    }
    
    public struct Configuration: Codable {
        let base: AnyCodable
        
        init(base: Codable) {
            self.base = .init(base)
        }
        
        public init(from decoder: Decoder) throws {
            throw Never.Reason.unsupported
        }
    }
    
    public struct State: Codable, Equatable {
        let base: AnyCodable?
        
        init(base: Codable?) {
            self.base = base.map({ AnyCodable($0) })
        }
        
        public init(from decoder: Decoder) throws {
            throw Never.Reason.unsupported
        }
        
        public init(nilLiteral: ()) {
            self.base = nil
        }
    }
}

// MARK: - Auxiliary Implementation -

fileprivate extension Database {
    var _opaque_context: AnyDatabase.Context {
        context.eraseToAnyDatabaseContext()
    }
    
    func _opaque_fetchAllAvailableZones() -> AnyTask<[AnyDatabaseZone], Error> {
        fetchAllAvailableZones()
            .successPublisher
            .map({ $0.map(AnyDatabaseZone.init(base:)) })
            .convertToTask()
    }
    
    func _opaque_fetchZone(named zoneName: String) -> AnyTask<AnyDatabaseZone, Error> {
        fetchZone(named: zoneName)
            .successPublisher
            .map({ AnyDatabaseZone(base: $0) })
            .convertToTask()
    }
    
    func _opaque_recordSpace(forZones zones: [AnyDatabaseZone]?) throws -> AnyDatabaseRecordSpace {
        let _zones = try zones?.map({ try cast($0.base, to: Zone.self) })
        
        return AnyDatabaseRecordSpace(erasing: try recordSpace(forZones: _zones))
    }
}
