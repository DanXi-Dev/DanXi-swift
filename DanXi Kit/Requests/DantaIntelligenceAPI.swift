import Foundation

public enum DantaIntelligenceAPI {
    public static func listChannels() async throws -> [DantaIntelligenceChannel] {
        try await requestWithResponse("/channels", base: dantaIntelligenceURL)
    }
    
    public static func listMessages(
        channelId: Int,
        offset: Int = 0,
        sort: String = "asc",
        size: Int = 30
    ) async throws -> [DantaIntelligenceMessage] {
        try await requestWithResponse(
            "/messages",
            base: dantaIntelligenceURL,
            params: [
                "channel_id": String(channelId),
                "offset": String(offset),
                "sort": sort,
                "size": String(size)
            ])
    }
}
