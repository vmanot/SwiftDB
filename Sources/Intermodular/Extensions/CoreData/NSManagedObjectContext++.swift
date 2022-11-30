//
// Copyright (c) Vatsal Manot
//

import CoreData
import Swallow

extension NSManagedObjectContext {
    public func perform<T>(
        _ action: @escaping () -> T
    ) async -> T {
        await withCheckedContinuation { continuation in
            perform {
                continuation.resume(returning: action())
            }
        }
    }
    
    public func perform<T>(
        _ action: @escaping () throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            perform {
                do {
                    continuation.resume(returning: try action())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension NSManagedObjectContext {
    private enum _FetchDeleteError: Error {
        case objectIdentifierIsNotPermanent(NSManagedObjectID)
    }
    
    public func object(withPermanentID id: NSManagedObjectID) throws -> NSManagedObject {
        guard !id.isTemporaryID else {
            throw _FetchDeleteError.objectIdentifierIsNotPermanent(id)
        }
        
        return object(with: id)
    }
    
    public func deleteObject(with id: NSManagedObjectID) throws {
        let object = try existingObject(with: id)
        
        delete(object)
    }

    public func deleteObject(withPermanentID id: NSManagedObjectID) throws {
        guard !id.isTemporaryID else {
            throw _FetchDeleteError.objectIdentifierIsNotPermanent(id)
        }
        
        let object = try existingObject(with: id)
        
        delete(object)
    }
}
