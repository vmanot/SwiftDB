//
//  ------------------------------------------------
//  Original project: SwiftDBTest
//  Created on 2025/5/14 by Fatbobman(东坡肘子)
//  X: @fatbobman
//  Mastodon: @fatbobman@mastodon.social
//  GitHub: @fatbobman
//  Blog: https://fatbobman.com
//  ------------------------------------------------
//  Copyright © 2025-present Fatbobman. All rights reserved.

import SwiftDB
import SwiftUI
import FoundationX
import Combine

struct ContentView: View {
   
    @StateObject var container = try! LocalDatabaseContainer(
        name: "mySchema",
        schema: MySchema(),
        location: URL.documentsDirectory.appending(path: "mydb.sqlite"))
    var body: some View {
        FooList()
            .database(container)
            .task {
//                try? await container.load()
            }
    }
}

#Preview {
    ContentView()
}

struct FooList: View {
    @QueryModels<Foo>() var foos
    @Environment(\.database) var container
    var body: some View {
        VStack {
            Button("Add New Foo") {
                Task { @MainActor in
                    try await container.transact {
                        let foo = try $0.create(Foo.self)
                        foo.bar = UUID().uuidString
                    }
                }
            }
            Button("Fetch Foo") {
                Task.detached {
                    try await container.transact {
//                        let predicate = CocoaPredicate<Foo>(booleanLiteral: true)
//                        let predicate = NSPredicate(format: "bar = %@", "8E9EE1D4-473C-49D5-AEEF-4EC64D8DCA4B")
                        let request = QueryRequest<Foo>(
                            predicate: nil,//.init(predicate),
                            sortDescriptors: [],
                            fetchLimit: nil,
                            scope: .init(nilLiteral: ()))
                        let results = try $0.execute(request)
                        for result in results.results {
                            print(result.bar)
                        }
                    }
                }
            }
            List(foos){ foo in
                Text(foo.bar)
            }
        }
    }
}
