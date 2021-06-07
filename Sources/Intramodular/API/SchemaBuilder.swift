//
// Copyright (c) Vatsal Manot
//

import Swallow
import Swift

#if swift(<5.4)
@_functionBuilder
public final class SchemaBuilder: ArrayBuilder<_opaque_Entity.Type> {
    
}
#else
@resultBuilder
public final class SchemaBuilder: ArrayBuilder<_opaque_Entity.Type> {
    
}
#endif
