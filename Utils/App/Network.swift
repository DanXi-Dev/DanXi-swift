import Foundation
#if canImport(Pulse)
import Pulse
#endif

public class RecordedSession {
    
    private let recordNetwork: Bool
    private let plainSession: URLSession
    private let pulseSession: URLSessionProxy

    public init() {
        self.recordNetwork = UserDefaults.standard.bool(forKey: "record-network")
        self.pulseSession = URLSessionProxy(configuration: .default)
        self.plainSession = URLSession(configuration: .default)
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(Pulse)
        if recordNetwork {
            return try await pulseSession.data(for: request)
        }
        #endif
        return try await plainSession.data(for: request)
    }

    public func data(from url: URL) async throws -> (Data, URLResponse) {
        #if canImport(Pulse)
        if recordNetwork {
            return try await pulseSession.data(from: url)
        }
        #endif
        return try await plainSession.data(from: url)
    }

    public func upload(for request: URLRequest, from bodyData: Data) async throws -> (Data, URLResponse) {
        #if canImport(Pulse)
        if recordNetwork {
            return try await pulseSession.upload(for: request, from: bodyData)
        }
        #endif
        return try await plainSession.upload(for: request, from: bodyData)
    }
}

extension URLSession {
    public static let defaultSession = RecordedSession()
    public static let campusSession = RecordedSession()
}
