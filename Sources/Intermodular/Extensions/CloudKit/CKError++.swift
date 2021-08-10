//
// Copyright (c) Vatsal Manot
//

import CloudKit
import Merge
import Swallow

extension CKError {
    var isTerminal: Bool {
        switch code {
            case .internalError:
                return true
            case .partialFailure:
                return false
            case .networkUnavailable:
                return false
            case .networkFailure:
                return false
            case .badContainer:
                return true
            case .serviceUnavailable:
                return false
            case .requestRateLimited:
                return false
            case .missingEntitlement:
                return true
            case .notAuthenticated:
                return true
            case .permissionFailure:
                return true
            case .unknownItem:
                return true
            case .invalidArguments:
                return true
            case .resultsTruncated:
                return false
            case .serverRecordChanged:
                return true
            case .serverRejectedRequest:
                return true
            case .assetFileNotFound:
                return true
            case .assetFileModified:
                return true
            case .incompatibleVersion:
                return true
            case .constraintViolation:
                return true
            case .operationCancelled:
                return false
            case .changeTokenExpired:
                return true
            case .batchRequestFailed:
                return false
            case .zoneBusy:
                return false
            case .badDatabase:
                return true
            case .quotaExceeded:
                return false
            case .zoneNotFound:
                return true
            case .limitExceeded:
                return true
            case .userDeletedZone:
                return true
            case .tooManyParticipants:
                return false
            case .alreadyShared:
                return true
            case .referenceViolation:
                return true
            case .managedAccountRestricted:
                return true
            case .participantMayNeedVerification:
                return true
            case .serverResponseLost:
                return false
            case .assetNotAvailable:
                return false
            #if swift(>=5.5)
            case .accountTemporarilyUnavailable:
                return true
            #endif
            @unknown default:
                return false
        }
    }
}
