import Foundation
import WatchConnectivity
import FudanKit

class CredentialSynchronizer: NSObject, WCSessionDelegate {
    static let shared = CredentialSynchronizer()
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let type = message["type"] as? String, type == "credential-request" else {
            return
        }
        
        let session = WCSession.default
        guard session.isReachable else { return }
        
        let studentType = switch CredentialStore.shared.studentType {
            case .undergrad: "undergrad"
            case .grad: "grad"
            case .staff: "staff"
        }
        
        if let username = CredentialStore.shared.username,
           let password = CredentialStore.shared.password {
            let message: [String: Any] = ["state": "is-logged", "username": username, "password": password, "student-type": studentType]
            replyHandler(message)
        } else {
            let message: [String: Any] = ["state": "not-logged"]
            replyHandler(message)
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
}
