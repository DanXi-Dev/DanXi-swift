import Foundation
import MarkdownUI

/// Starts work when a floor is prefetched, before its SwiftUI row exists.
final class MarkdownDocument {
    let source: String
    let prepared: Task<PreparedMarkdown, Never>

    init(_ source: String) {
        self.source = source
        prepared = Task.detached(priority: .userInitiated) {
            await MarkdownParser.shared.prepare(source)
        }
    }

    func renderMarkdown() -> String { source }
}

struct PreparedMarkdown {
    let content: MarkdownContent
    let expressions: [MathExpression]
}

private actor MarkdownParser {
    static let shared = MarkdownParser()
    private var cache: [String: PreparedMarkdown] = [:]
    private var order: [String] = []
    private var sourceBytes = 0

    func prepare(_ source: String) -> PreparedMarkdown {
        if let cached = cache[source] { return cached }
        let protected = MarkdownSource(source)
        let result = PreparedMarkdown(content: MarkdownContent(protected.markdown).separatingImages {
            $0.hasPrefix("markdown-block:") || $0.hasPrefix("https://") || $0.hasPrefix("http://")
        },
                                      expressions: protected.expressions)
        while !order.isEmpty && (order.count >= 128 || sourceBytes + source.utf8.count > 2_000_000) {
            let oldest = order.removeFirst()
            sourceBytes -= oldest.utf8.count
            cache.removeValue(forKey: oldest)
        }
        if source.utf8.count <= 2_000_000 {
            cache[source] = result
            order.append(source)
            sourceBytes += source.utf8.count
        }
        if !result.expressions.isEmpty {
            Task.detached(priority: .utility) {
                // Yield the renderer between expressions so visible rows can overtake prefetch.
                for expression in Set(result.expressions) {
                    guard !Task.isCancelled else { return }
                    await MathRenderer.shared.preload([expression])
                }
            }
        }
        return result
    }
}
