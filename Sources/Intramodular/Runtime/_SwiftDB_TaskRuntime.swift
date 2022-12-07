//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

struct _SwiftDB_TaskRuntimeID: Hashable {
    private let rawValue: AnyHashable

    private init(rawValue: AnyHashable) {
        self.rawValue = rawValue
    }

    public init() {
        self.init(rawValue: UUID())
    }
}

/// An internal representation of a SwiftDB encapsulated database transaction.
protocol _SwiftDB_TaskRuntime: AnyObject, Identifiable where ID == _SwiftDB_TaskRuntimeID {
    func scope<T>(_ context: (_SwiftDB_TaskContext) throws -> T) throws -> T

    func _scopeRecordMutation<T>(_ body: () throws -> T) throws -> T
}

/// A transaction wrapper that interposes another transaction.
///
/// This is needed to implement special transaction types (such as `_AutoCommittingTransaction`).
/// The runtime uses this to ensure that the interposed transaction is used over the base transacton.
protocol _SwiftDB_TaskRuntimeInterposer: _SwiftDB_TaskRuntime {
    var interposee: _SwiftDB_TaskRuntimeID { get }
}

// MARK: - Implementation -

extension _SwiftDB_TaskRuntime {
    public func _scopeRecordMutation<T>(_ body: () throws -> T) throws -> T {
        try body()
    }
}

// MARK: - Supplementary API -

public final class _SwiftDB_TaskRuntimeLink {
    public let parentID: AnyHashable

    init(from parent: any _SwiftDB_TaskRuntime) {
        self.parentID = parent.id

        /*asObjCObject(transaction).keepAlive(ExecuteClosureOnDeinit { [weak self] in
         if self != nil {
         assertionFailure("Transaction link has outlived transaction.")
         }
         })*/
    }
}
