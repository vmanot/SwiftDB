//
// Copyright (c) Vatsal Manot
//

import Merge
import Swift

/// A type-erased database.
public final class AnyDatabase: Database {
    public typealias SchemaAdaptor = AnyDatabaseSchemaAdaptor
    public typealias RecordContext = AnyDatabaseRecordContext
    public typealias Zone = AnyDatabaseZone

    private let baseBox: _AnyDatabaseBoxBase

    public var name: String {
        baseBox.name
    }

    public var id: ID {
        baseBox.id
    }

    public var capabilities: [DatabaseCapability] {
        baseBox.capabilities
    }

    public var configuration: Configuration {
        baseBox.configuration
    }

    public var state: State {
        baseBox.state
    }

    public var context: Context {
        baseBox.context
    }
    
    public init<D: Database>(_ database: D) {
        self.baseBox = _AnyDatabaseBox(database)
    }

    public init(
        runtime: _SwiftDB_Runtime,
        schema: DatabaseSchema?,
        configuration: Configuration,
        state: State?
    ) throws {
        throw Never.Reason.unsupported
    }

    public func fetchAllAvailableZones() -> AnyTask<[AnyDatabaseZone], Error> {
        baseBox.fetchAllAvailableZones()
    }

    public func fetchZone(named zoneName: String) -> AnyTask<AnyDatabaseZone, Error> {
        baseBox.fetchZone(named: zoneName)
    }

    public func recordContext(forZones zones: [AnyDatabaseZone]?) throws -> AnyDatabaseRecordContext {
        try baseBox.recordContext(forZones: zones)
    }

    public func delete() -> AnyTask<Void, Error> {
        baseBox.delete()
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

// MARK: - Underlying Implementation -

class _AnyDatabaseBoxBase {
    var name: String {
        fatalError()
    }

    var id: AnyDatabase.ID {
        fatalError()
    }

    var capabilities: [DatabaseCapability] {
        fatalError()
    }
    
    var configuration: AnyDatabase.Configuration {
        fatalError()
    }

    var state: AnyDatabase.State {
        fatalError()
    }

    var context: AnyDatabase.Context {
        fatalError()
    }
    
    func fetchAllAvailableZones() -> AnyTask<[AnyDatabaseZone], Error> {
        fatalError()
    }

    func fetchZone(named zoneName: String) -> AnyTask<AnyDatabaseZone, Error> {
        fatalError()
    }

    func recordContext(forZones zones: [AnyDatabaseZone]?) throws -> AnyDatabaseRecordContext {
        fatalError()
    }

    func delete() -> AnyTask<Void, Error> {
        fatalError()
    }
}

final class _AnyDatabaseBox<Base: Database>: _AnyDatabaseBoxBase {
    let base: Base

    override var name: String {
        base.name
    }

    override var id: AnyDatabase.ID {
        .init(base: base.id)
    }

    override var capabilities: [DatabaseCapability] {
        base.capabilities
    }

    override var configuration: AnyDatabase.Configuration {
        .init(base: base.configuration)
    }

    override var state: AnyDatabase.State {
        .init(base: base.state)
    }

    override var context: AnyDatabase.Context {
        base.context.eraseToAnyDatabaseContext()
    }

    init(_ base: Base) {
        self.base = base
    }

    override func fetchAllAvailableZones() -> AnyTask<[AnyDatabaseZone], Error> {
        base.fetchAllAvailableZones()
            .successPublisher
            .map({ $0.map(AnyDatabaseZone.init(base:)) })
            .convertToTask()
    }

    override func fetchZone(named zoneName: String) -> AnyTask<AnyDatabaseZone, Error> {
        base.fetchZone(named: zoneName)
            .successPublisher
            .map({ AnyDatabaseZone(base: $0) })
            .convertToTask()
    }

    override func recordContext(forZones zones: [AnyDatabaseZone]?) throws -> AnyDatabaseRecordContext {
        let _zones = try zones?.map({ try cast($0.base, to: Base.Zone.self) })

        return AnyDatabaseRecordContext(try base.recordContext(forZones: _zones))
    }

    override func delete() -> AnyTask<Void, Error> {
        base.delete()
    }
}
