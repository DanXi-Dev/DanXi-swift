import SwiftUI
import WatchConnectivity
import FudanKit
import Combine

enum CompanionState {
    case isLogged(username: String, password: String, studentType: StudentType)
    case notLogged
}

func requestCredentialTransfer() async throws -> CompanionState {
    let session = WCSession.default
    guard session.isReachable else {
        throw NSError()
    }
    
    let state: CompanionState = try await withCheckedThrowingContinuation { continuation in
        let message = ["type": "credential-request"]
        
        let replyHander = { (reply: [String: Any]) -> Void in
            guard let state = reply["state"] as? String else {
                continuation.resume(throwing: NSError())
                return
            }
            
            if state == "not-logged" {
                continuation.resume(returning: CompanionState.notLogged)
                return
            }
            
            guard let username = reply["username"] as? String,
                  let password = reply["password"] as? String,
                  let studentTypeString = reply["student-type"] as? String else {
                continuation.resume(throwing: NSError())
                return
            }
            
            let studentType: StudentType = switch studentTypeString {
                case "undergrad": .undergrad
                case "grad": .grad
                case "staff": .staff
                default: .undergrad
            }
            
            let companionState = CompanionState.isLogged(username: username, password: password, studentType: studentType)
            continuation.resume(returning: companionState)
        }
        
        let errorHandler = { error in
            continuation.resume(throwing: error)
        }
        
        session.sendMessage(message, replyHandler: replyHander, errorHandler: errorHandler)
    }
    
    return state
}

class CredentialSynchronizer: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = CredentialSynchronizer()
    
    @Published var activated = false
    
    override init() {
        super.init()
        
        guard WCSession.isSupported() else { return }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in
            switch activationState {
            case .activated:
                activated = true
            default:
                activated = false
            }
        }
    }
}
