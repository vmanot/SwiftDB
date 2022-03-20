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
