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

struct Foo: Entity, Identifiable {
    @Attribute var bar: String = "Untitled"
    
    var id: some Hashable {
        bar
    }
}

struct MySchema: Schema {
    var body: [any Entity.Type] {
        Foo.self
    }
}
