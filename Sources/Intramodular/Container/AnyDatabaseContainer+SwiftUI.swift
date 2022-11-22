//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Merge
import Swallow
import SwiftUIX

struct AttachDatabaseContainer: ViewModifier {
    @ObservedObject var container: AnyDatabaseContainer
    
    @State private var hasAttemptedFirstLoad: Bool = false
    
    func body(content: Content) -> some View {
        Group {
            if container.status == .initialized {
                content
                    .environmentObject(container)
                    .environment(\.database, container.liveAccess)
            } else {
                if !hasAttemptedFirstLoad {
                    firstLoadView
                } else {
                    DiagnosticView(container: container)
                }
            }
        }
    }
    
    private var firstLoadView: some View {
        ZeroSizeView().onAppear {
            loadIfNeeded()
        }
        .background {
            PerformAction {
                loadIfNeeded()
            }
        }
    }
    
    private func loadIfNeeded() {
        guard !hasAttemptedFirstLoad else {
            return
        }
        
        Task(priority: .userInitiated) {
            try await container.load()
        }
        
        hasAttemptedFirstLoad = true
    }
}

// MARK: - API -

extension View {
    /// Attaches a database container to this view.
    ///
    /// The view is disabled until the database container is initialized. This is intentionally done to prevent invalid access to an uninitialized database container.
    ///
    /// - Parameters:
    ///   - container: The database container to attach.
    public func database(
        _ container: AnyDatabaseContainer
    ) -> some View {
        modifier(AttachDatabaseContainer(container: container))
    }
}

// MARK: - Auxiliary -

extension EnvironmentValues {
    fileprivate struct _DatabaseEnvironmentKey: EnvironmentKey {
        static let defaultValue = AnyDatabaseContainer.LiveAccess()
    }
    
    /// The database record space associated with this environment.
    public fileprivate(set) var database: AnyDatabaseContainer.LiveAccess {
        get {
            self[_DatabaseEnvironmentKey.self]
        } set {
            self[_DatabaseEnvironmentKey.self] = newValue
        }
    }
}

// MARK: - Diagnostics -

extension AttachDatabaseContainer {
    struct DiagnosticView: View {
        @ObservedObject var container: AnyDatabaseContainer
        
        var body: some View {
            NavigationStack {
                _MirrorSummaryView(mirror: container.customMirror)
                    .navigationTitle("Database Summary")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
