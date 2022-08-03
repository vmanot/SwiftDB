//
// Copyright (c) Vatsal Manot
//

import XCTest

@testable import SwiftDB

struct TestORMSchema: Schema {
    var body: Body {
        EmptyEntity.self
        EntityWithSimpleRequiredProperty.self
        EntityWithOptionalProperties.self
        EntityWithComplexProperties.self
        EntityWithDynamicProperties.self
    }
}

extension TestORMSchema {
    class EmptyEntity: Entity {
        required init() {

        }
    }

    class EntityWithSimpleRequiredProperty: Entity, Codable {
        @Attribute var foo: Int = 0

        required init() {

        }
    }

    class EntityWithOptionalProperties: Entity, Codable {
        @Attribute var foo: Int? = nil
        @Attribute var bar: Date? = nil
        @Attribute var baz: String? = nil

        required init() {

        }
    }

    class EntityWithComplexProperties: Entity, Codable {
        enum Animal: String, Codable, Hashable {
            case cat
            case dog
            case lion
        }

        @Attribute var animal: Animal = .cat

        required init() {

        }
    }

    class EntityWithDynamicProperties: Entity, Codable {
        @Attribute var id: UUID = UUID()

        @Attribute(defaultValue: UUID()) var defaultValueID: UUID

        required init() {

        }
    }
}
