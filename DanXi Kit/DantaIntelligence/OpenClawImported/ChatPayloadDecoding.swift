// Imported from openclaw commit b19e28a85ed9a867ff68ba1d6cd4609e47d8f624:
// apps/shared/OpenClawKit/Sources/OpenClawChatUI/ChatPayloadDecoding.swift
// DanXi modification: removed the OpenClawKit import and use the local copied AnyCodable.

import Foundation

enum ChatPayloadDecoding {
    static func decode<T: Decodable>(_ payload: AnyCodable, as _: T.Type = T.self) throws -> T {
        let data = try JSONEncoder().encode(payload)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
