//
// Copyright (c) Vatsal Manot
//

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
            ZeroSizeView().onAppear {
                loadIfNeeded()
            }
            .background {
                PerformAction {
                    loadIfNeeded()
                }
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
