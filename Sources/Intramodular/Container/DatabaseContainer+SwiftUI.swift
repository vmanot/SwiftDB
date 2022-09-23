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
        if let mainContext = try? container.mainContext {
            content
                .databaseRecordContext(mainContext)
                .environmentObject(container)
        } else {
            if !hasAttemptedFirstLoad {
                firstLoadView
            } else {
                #if DEBUG
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                    DiagnosticView(container: container)
                }
                #endif
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

// MARK: - Diagnostics -

extension AttachDatabaseContainer {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    struct DiagnosticView: View {
        @ObservedObject var container: AnyDatabaseContainer
        
        var body: some View {
            NavigationStack {
                MirrorSummary(mirror: container.customMirror)
                    .navigationTitle("Database Summary")
                    .modify {
                        #if !os(macOS)
                        $0.navigationBarTitleDisplayMode(.inline)
                        #else
                        $0
                        #endif
                    }
            }
        }
    }
}
