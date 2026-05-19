import Foundation

public struct DantaIntelligenceInlineImage: Identifiable {
    public let id: UUID
    public let label: String
    public let image: OpenClawPlatformImage?
}

public struct DantaIntelligenceMarkdownResult {
    public let cleaned: String
    public let images: [DantaIntelligenceInlineImage]
}

public struct DantaIntelligenceAssistantSegment: Identifiable {
    public enum Kind {
        case thinking
        case response
    }

    public let id: UUID
    public let kind: Kind
    public let text: String
}

public enum DantaIntelligenceTextProcessing {
    public static func preprocessMarkdown(_ markdown: String) -> DantaIntelligenceMarkdownResult {
        let result = ChatMarkdownPreprocessor.preprocess(markdown: markdown)
        return DantaIntelligenceMarkdownResult(
            cleaned: result.cleaned,
            images: result.images.map {
                DantaIntelligenceInlineImage(id: $0.id, label: $0.label, image: $0.image)
            })
    }

    public static func assistantSegments(
        from raw: String,
        includeThinking: Bool = true
    ) -> [DantaIntelligenceAssistantSegment] {
        AssistantTextParser.segments(from: raw, includeThinking: includeThinking).map { segment in
            DantaIntelligenceAssistantSegment(
                id: segment.id,
                kind: Self.kind(from: segment.kind),
                text: segment.text)
        }
    }

    private static func kind(from openClawKind: AssistantTextSegment.Kind) -> DantaIntelligenceAssistantSegment.Kind {
        switch openClawKind {
        case .thinking:
            return .thinking
        case .response:
            return .response
        }
    }
}
