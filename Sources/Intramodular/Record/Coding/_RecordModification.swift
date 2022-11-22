//
// Copyright (c) Vatsal Manot
//

public enum _RecordModification {
    case arbitrary((_DatabaseRecordCoder) -> Void)

    init(mutation: @escaping (_DatabaseRecordCoder) -> Void) {
        self = .arbitrary(mutation)
    }
}
